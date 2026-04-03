param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
var suffix = take(uniqueString(resourceGroup().id), 6)
var cloudVpnGwName = 'cloud-vpngw-${suffix}'
param enablediagnostics bool

/* ****************************** Cloud-Vnet ****************************** */

module nsgSite1 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite1'
  params: {
    name: 'nsg-site1'
    location: locationSite1
  }
}

module cloudVnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet'
  params: {
    tags: {
      project: 'toizumi_recipes'
    }
    name: 'cloud-vnet'
    location: locationSite1
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.1.0/24'
      }
    ]
  }
}

module cloudVpnGw 'br/public:avm/res/network/virtual-network-gateway:0.10.1' = {
  name: cloudVpnGwName
  params: {
    name: cloudVpnGwName
    location: locationSite1
    gatewayType: 'Vpn'
    skuName: 'VpnGw1AZ'
    virtualNetworkResourceId: cloudVnet.outputs.resourceId
    clusterSettings: {
      clusterMode: 'activeActiveBgp'
      asn: 65515
      customBgpIpAddresses: ['169.254.22.10']
      secondCustomBgpIpAddresses: ['169.254.22.11']
    }
    enablePrivateIpAddress: false
    domainNameLabel: []
    diagnosticSettings: enablediagnostics ? [
      {
        workspaceResourceId: logAnalytics.?outputs.?resourceId ?? ''
      }
    ] : []
  }
}

module lngOnp1 'br/public:avm/res/network/local-network-gateway:0.4.0' = {
  name: 'lng-onp1'
  params: {
    name: 'lng-onp1'
    location: locationSite1
    localGatewayPublicIpAddress: strongSwanPip.outputs.ipAddress
    localNetworkAddressSpace: {
      addressPrefixes: ['10.100.0.0/16']
    }
    bgpSettings: {
      localAsn: 65511
      localBgpPeeringAddress: '169.254.22.20'
    }
  }
}


module connectionCloudToOnp1 'br/public:avm/res/network/connection:0.1.6' = {
  name: 'fromCloudtoOnp1'
  params: {
    name: 'fromCloudtoOnp1'
    location: locationSite1
    virtualNetworkGateway1: {
      id: cloudVpnGw.outputs.resourceId
    }
    connectionType: 'IPsec'
    localNetworkGateway2ResourceId: lngOnp1.outputs.resourceId
    vpnSharedKey: 'sharedpass'
    enableBgp: true
    gatewayCustomBgpIpAddresses: [
      {
        customBgpIpAddress: '169.254.22.10'
        ipConfigurationId: '${cloudVpnGw.outputs.resourceId}/ipConfigurations/vNetGatewayConfig1'
      }
      {
        customBgpIpAddress: '169.254.22.11'
        ipConfigurationId: '${cloudVpnGw.outputs.resourceId}/ipConfigurations/vNetGatewayConfig2'
      }
    ]
  }
}


module cloudvm 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'cloud-vm-deploy'
  params: {
    name: 'cloud-vm'
    location: locationSite1
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: cloudVnet.outputs.subnetResourceIds[0]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}

/* ****************************** Onpre-Vnet ****************************** */

module nsgSite2 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite2'
  params: {
    name: 'nsg-site2'
    location: locationSite2
  }
}

var strongSwanPrivateIp = '10.100.1.4'
module onpreRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'onpre-rt-deploy'
  params: {
    name: 'onpre-rt'
    location: locationSite2
    routes: [
      {
        name: 'to-cloud-vnet'
        properties: {
          addressPrefix: '10.0.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: strongSwanPrivateIp
        }
      }
    ]
  }
}

module onpreVnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'onpre-vnet'
  params: {
    name: 'onpre-vnet'
    location: locationSite2
    addressPrefixes: [
      '10.100.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.100.0.0/24'
        networkSecurityGroupResourceId: nsgSite2.outputs.resourceId
        routeTableResourceId: onpreRouteTable.outputs.resourceId
      }
      {
        name: 'StrongSwan-FRR-Subnet'
        addressPrefix: '10.100.1.0/24'
      }
    ]
  }
}

module strongSwanPip 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  name: 'strongswan-pip-deploy'
  params: {
    name: 'StrongSwanVM-pip'
    location: locationSite2
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
  }
}

var strongSwanSubnetGw = '10.100.1.1'
var vpnGwPip1 = cloudVpnGw.outputs.?primaryPublicIpAddress ?? ''
var vpnGwPip2 = cloudVpnGw.outputs.?secondaryPublicIpAddress ?? vpnGwPip1
var cloudInitContent = replace(
  replace(
    replace(
      replace(
        replace(loadTextContent('cloud-init.yml'), '\r', ''),
        '__STRONGSWAN_PIP__', strongSwanPip.outputs.ipAddress),
      '__VPNGW_PIP1__', vpnGwPip1),
    '__VPNGW_PIP2__', vpnGwPip2),
  '__SUBNET_GW__', strongSwanSubnetGw)

module StrongSwanVM 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'strongswan-vm-deploy'
  params: {
    name: 'StrongSwanVM'
    location: locationSite2
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    customData: cloudInitContent
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        enableIPForwarding: true
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: onpreVnet.outputs.subnetResourceIds[1]
            privateIPAddress: strongSwanPrivateIp
            privateIPAllocationMethod: 'Static'
            pipConfiguration: {
              publicIPAddressResourceId: strongSwanPip.outputs.resourceId
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}

module onpreVm 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'onpre-vm-deploy'
  params: {
    name: 'onpre-vm'
    location: locationSite2
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: onpreVnet.outputs.subnetResourceIds[0]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}

/* ****************************** enable diagnostic logs ****************************** */
var logAnalyticsWorkspaceName = '${uniqueString(resourceGroup().id)}la'
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = if (enablediagnostics) {
  name: 'logAnalyticsWorkspace'
  params: {
    name: logAnalyticsWorkspaceName
    location: locationSite1
  }
}
