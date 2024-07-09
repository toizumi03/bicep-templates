targetScope = 'tenant'
param locationSite1 string
param sub1Id string
param sub1rgName string
param sub2Id string
param sub2rgName string

// create sub1 rg, resource
module rg1 'createRG.bicep' = {
  scope: subscription(sub1Id)
  name: sub1rgName
  params: {
    rglocation: locationSite1
    rgname: sub1rgName
  }
}

module sub1vnet 'createVnet.bicep' = {
  scope: resourceGroup(sub1Id, rg1.name)
  name: 'sub1-vnet'
  params: {
    vnetLocation: locationSite1
    vnetName: 'sub1-vnet'
    NetworkAddressPrefix: '10.1.0.0/16'
  }
}

module peering1 'createPeering.bicep' = {
  scope: resourceGroup(sub1Id, rg1.name)
  name: 'sub1-to-sub2-peering'
  params: {
    PeeringName: 'sub1-to-sub2-peering'
    remoteVnetID: sub2vnet.outputs.virtualNetworkId
    virtualNetworkName: sub1vnet.name
  }
}

// create sub2 rg, resource
module rg2 'createRG.bicep' = {
  scope: subscription(sub2Id)
  name: sub2rgName
  params: {
    rglocation: locationSite1
    rgname: sub2rgName
  }
}

module sub2vnet 'createVnet.bicep' = {
  scope: resourceGroup(sub2Id, rg2.name)
  name: 'sub2-vnet'
  params: {
    vnetLocation: locationSite1
    vnetName: 'sub2-vnet'
    NetworkAddressPrefix: '10.2.0.0/16'
  }
}

module peering2 'createPeering.bicep' = {
  scope: resourceGroup(sub2Id, rg2.name)
  name: 'sub2-to-sub1-peering'
  params: {
    PeeringName: 'sub2-to-sub1-peering'
    remoteVnetID: sub1vnet.outputs.virtualNetworkId
    virtualNetworkName: sub2vnet.name
  }
}
