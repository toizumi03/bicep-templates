param bastionName string
param location string
param subnetid string
param bastionsku string

resource bastionIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: bastionName
  location: location
  sku: {
    name: bastionsku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetid
          }
          publicIPAddress: {
            id: bastionIP.id
          }
        }
      }
    ]
  }
}
