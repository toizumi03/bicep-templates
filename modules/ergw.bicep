param location string
param gatewayName string
param vnetName string
param sku string
param useExisting bool = false

resource vnet01 'Microsoft.Network/virtualNetworks@2023-04-01' existing =  {
  name: vnetName
  resource GatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
}

resource Ergwpip 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (!useExisting) {
  name: '${gatewayName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource ergw 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = if (!useExisting) {
  name: gatewayName
  location: location
  properties: {
    sku: {
      name: sku
      tier: sku
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: { id: Ergwpip.id }
          subnet: { id: vnet01::GatewaySubnet.id }
        }
      }
    ]
    gatewayType: 'ExpressRoute'
  }
}

resource extErgw 'Microsoft.Network/virtualNetworkGateways@2023-04-01' existing = if (useExisting) {
  name: gatewayName  
  }

  
output vpngwName string = !useExisting ? Ergwpip.name : extErgw.name
output vpngwId string = !useExisting ? Ergwpip.id : extErgw.id
output publicIpName string = Ergwpip.name
output ErpublicIp string = Ergwpip.properties.ipAddress
