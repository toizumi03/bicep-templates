param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string


/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource cloud_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet'
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

module expressRouteGateway '../modules/ergw.bicep' = {
  name: 'cloud-ergw'
  params: {
    location: locationSite1
    gatewayName: 'cloud-ergw'
    sku: 'Standard'
    vnetName: cloud_vnet.name
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
    subnetId: cloud_vnet.properties.subnets[0].id
  }
}

resource spoke_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = [for i in range (0, numberofSpokeVnet): {
  parent: cloud_vnet
  name: 'spoke-peer${i}'
  properties: {
    remoteVirtualNetwork: {
      id: spoke_vnet[i].id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
  }
}]

/* ****************************** Cloud-SpokeVnet ****************************** */
var numberofSpokeVnet = 2
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = [for i in range (0, numberofSpokeVnet):{
  name: 'spoke-vnet${i+1}'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${i+1}0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.${i+1}0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}]

module spokevm '../modules/ubuntu20.04.bicep' = [for i in range (0, numberofSpokeVnet):{
  name: 'spoke-vm${i}'
  params: {
    vmName: 'spoke-vm${i+1}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: spoke_vnet[i].properties.subnets[0].id
  }
}]

resource cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = [for i in range (0, numberofSpokeVnet): {
  parent: spoke_vnet[i]
  name: 'cloud-peer${i+1}'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
  }
  dependsOn: [
    expressRouteGateway
  ]
}]
