param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param enablediagnostics bool
var suffix = take(uniqueString(resourceGroup().id), 6)
var cloudVpnGwName = 'cloud-vpngw-${suffix}'
var onpreVpnGwName = 'onpre-vpngw-${suffix}'

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
    skuName: 'VpnGw1'
    virtualNetworkResourceId: cloudVnet.outputs.resourceId
    clusterSettings: {
      clusterMode: 'activeActiveBgp'
      asn: 65010
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
    localGatewayPublicIpAddress: onpreVpnGw.outputs.?primaryPublicIpAddress ?? ''
    localNetworkAddressSpace: {
      addressPrefixes: []
    }
    bgpSettings: {
      localAsn: 65020
      localBgpPeeringAddress: onpreVpnGw.outputs.?defaultBgpIpAddresses ?? ''
    }
  }
}

module lngOnp2 'br/public:avm/res/network/local-network-gateway:0.4.0' = {
  name: 'lng-onp2'
  params: {
    name: 'lng-onp2'
    location: locationSite1
    localGatewayPublicIpAddress: onpreVpnGw.outputs.?secondaryPublicIpAddress ?? ''
    localNetworkAddressSpace: {
      addressPrefixes: []
    }
    bgpSettings: {
      localAsn: 65020
      localBgpPeeringAddress: onpreVpnGw.outputs.?secondaryDefaultBgpIpAddress ?? ''
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
    routingWeight: 0
  }
}

module connectionCloudToOnp2 'br/public:avm/res/network/connection:0.1.6' = {
  name: 'fromCloudtoOnp2'
  params: {
    name: 'fromCloudtoOnp2'
    location: locationSite1
    virtualNetworkGateway1: {
      id: cloudVpnGw.outputs.resourceId
    }
    connectionType: 'IPsec'
    localNetworkGateway2ResourceId: lngOnp2.outputs.resourceId
    vpnSharedKey: 'sharedpass'
    enableBgp: true
    routingWeight: 0
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
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.100.1.0/24'
      }
    ]
  }
}

module onpreVpnGw 'br/public:avm/res/network/virtual-network-gateway:0.10.1' = {
  name: onpreVpnGwName
  params: {
    name: onpreVpnGwName
    location: locationSite2
    gatewayType: 'Vpn'
    skuName: 'VpnGw1'
    virtualNetworkResourceId: onpreVnet.outputs.resourceId
    clusterSettings: {
      clusterMode: 'activeActiveBgp'
      asn: 65020
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

module lngCloud1 'br/public:avm/res/network/local-network-gateway:0.4.0' = {
  name: 'lng-cloud1'
  params: {
    name: 'lng-cloud1'
    location: locationSite2
    localGatewayPublicIpAddress: cloudVpnGw.outputs.?primaryPublicIpAddress ?? ''
    localNetworkAddressSpace: {
      addressPrefixes: []
    }
    bgpSettings: {
      localAsn: 65010
      localBgpPeeringAddress: cloudVpnGw.outputs.?defaultBgpIpAddresses ?? ''
    }
  }
}

module lngCloud2 'br/public:avm/res/network/local-network-gateway:0.4.0' = {
  name: 'lng-cloud2'
  params: {
    name: 'lng-cloud2'
    location: locationSite2
    localGatewayPublicIpAddress: cloudVpnGw.outputs.?secondaryPublicIpAddress ?? ''
    localNetworkAddressSpace: {
      addressPrefixes: []
    }
    bgpSettings: {
      localAsn: 65010
      localBgpPeeringAddress: cloudVpnGw.outputs.?secondaryDefaultBgpIpAddress ?? ''
    }
  }
}

// Connection from Onp to Cloud
module connectionOnpToCloud1 'br/public:avm/res/network/connection:0.1.6' = {
  name: 'fromOnptoCloud1'
  params: {
    name: 'fromOnptoCloud1'
    location: locationSite2
    virtualNetworkGateway1: {
      id: onpreVpnGw.outputs.resourceId
    }
    connectionType: 'IPsec'
    localNetworkGateway2ResourceId: lngCloud1.outputs.resourceId
    vpnSharedKey: 'sharedpass'
    enableBgp: true
    routingWeight: 0
  }
}

module connectionOnpToCloud2 'br/public:avm/res/network/connection:0.1.6' = {
  name: 'fromOnptoCloud2'
  params: {
    name: 'fromOnptoCloud2'
    location: locationSite2
    virtualNetworkGateway1: {
      id: onpreVpnGw.outputs.resourceId
    }
    connectionType: 'IPsec'
    localNetworkGateway2ResourceId: lngCloud2.outputs.resourceId
    vpnSharedKey: 'sharedpass'
    enableBgp: true
    routingWeight: 0
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

/* ****************************** Log Analytics ****************************** */
var logAnalyticsWorkspaceName = '${uniqueString(resourceGroup().id)}la'
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = if (enablediagnostics) {
  name: 'logAnalyticsWorkspace'
  params: {
    name: logAnalyticsWorkspaceName
    location: locationSite1
  }
}
