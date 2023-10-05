param location string
param routeserverName string
param vnetName string
param useExisting bool = false
param bgpConnections array = []

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  parent: vnet
  name: 'RouteServerSubnet'
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-${routeserverName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource routeserver 'Microsoft.Network/virtualHubs@2023-04-01' = if (!useExisting) {
  name: routeserverName
  location: location
  properties: {
    sku: 'Standard'
    allowBranchToBranchTraffic: true
  }
  resource ipconfig 'ipConfigurations' = if (!useExisting) {
    name: 'ipconfig'
    properties: {
      publicIPAddress: { id: pip.id }
      subnet: { id: subnet.id }
    }
  }
}

@batchSize(1)
resource bgp_conn 'Microsoft.Network/virtualHubs/bgpConnections@2023-04-01' = [for peer in bgpConnections: {
  parent: routeserver
  name: peer.name
  properties: {
    peerIp: peer.ip
    peerAsn: peer.asn
  }
  dependsOn: [
    routeserver::ipconfig
  ]
}]
