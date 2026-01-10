param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
var useExisting = false
param enablediagnostics bool

/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource cloud_hubvnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-hub-vnet'
  location: locationSite1
  tags: {
    tagName1: 'toizumi_recipes'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

var cloudvpngwName = 'cloud-vpngw'
module cloudvpngateway '../modules/vpngw_single.bicep' = {
  name: cloudvpngwName
  params: {
    location: locationSite1
    gatewayName: cloudvpngwName
    vnetName: cloud_hubvnet.name
    enablePrivateIpAddress: false
    bgpAsn: 65010
    useExisting: useExisting
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

resource conncetionCloudtoOnp 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp'
  location: locationSite1
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    virtualNetworkGateway2: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

module cloudvm '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm'
  params: {
    vmName: 'cloud-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_hubvnet.properties.subnets[0].id
  }
}

resource spoke_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: cloud_hubvnet
  name: 'spoke-peer1'
  properties: {
    remoteVirtualNetwork: {
      id: spoke_vnet.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peerCompleteVnets: false
    localSubnetNames: [
      'default'
      'GatewaySubnet'
    ]
    remoteSubnetNames: [
      'subnet-1'
    ]
  }
}

/* ****************************** Cloud-SpokeVnet ****************************** */
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'spoke-vnet1'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
            {
        name: 'subnet-2'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

module spokevm1 '../modules/ubuntu20.04.bicep' = {
  name: 'spoke-vm1'
  params: {
    vmName: 'spoke-vm1'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: spoke_vnet.properties.subnets[0].id
  }
}

module spokevm2 '../modules/ubuntu20.04.bicep' = {
  name: 'spoke-vm2'
  params: {
    vmName: 'spoke-vm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: spoke_vnet.properties.subnets[1].id
  }
}

resource cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spoke_vnet
  name: 'cloud-peer1'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_hubvnet.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
    peerCompleteVnets: false
    localSubnetNames: [
      'subnet-1'
    ]
    remoteSubnetNames: [
      'default'
      'GatewaySubnet'
    ]
  }
  dependsOn: [
    cloudvpngateway
  ]
}

/* ****************************** Onpre-Vnet ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'  
  }
}

resource onpre_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet'
  location: locationSite2
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
        }
      }
    ]
  }
}

var onprevpngwName = 'onpre-vpngw'
module onprevpngateway '../modules/vpngw_single.bicep' = {
  name: onprevpngwName
  params: {
    location: locationSite2
    gatewayName: onprevpngwName
    vnetName: onpre_vnet.name
    enablePrivateIpAddress: false
    bgpAsn: 65020
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}


// Connection from Onp to Cloud
resource connectionOnptoCloud 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    virtualNetworkGateway2: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

module onprevm '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-vm'
  params: {
    vmName: 'onpre-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
