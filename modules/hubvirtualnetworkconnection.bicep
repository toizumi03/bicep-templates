param hub2vnetconnection string
param vnetid string

resource connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-04-01' = {
  name: hub2vnetconnection
  properties: {
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    remoteVirtualNetwork: {
      id: vnetid
    }
  }
}
