targetScope = 'resourceGroup'
param vnetLocation string
param vnetName string
param NetworkAddressPrefix string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        NetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: cidrSubnet(NetworkAddressPrefix, 24, 0)
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
