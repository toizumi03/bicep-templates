param privatelinkserviceName string
param location string
param loadBalancerFrontendIPConfigurationsID string
param subnetID string
param subscriptionId string

resource privatelinkservice 'Microsoft.Network/privateLinkServices@2023-04-01' = {
  name: privatelinkserviceName
  location: location
  properties: {
    autoApproval: {
      subscriptions: [subscriptionId]
    }
    enableProxyProtocol: false
    fqdns: []
    visibility: {
      subscriptions: [subscriptionId]
    }
    loadBalancerFrontendIpConfigurations: [
      {
        id: loadBalancerFrontendIPConfigurationsID
      }
    ]
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

output privatelinkResourceId string = privatelinkservice.id
