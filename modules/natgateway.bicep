param natgatewayName string
param location string

resource natgatewayIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'natgateway-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource natgateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: natgatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natgatewayIP.id
      }
    ]
  }
}

output natgatewayId string = natgateway.id
