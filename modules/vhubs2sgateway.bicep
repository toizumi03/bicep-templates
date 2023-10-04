param hubgatewayName string
param hubid string
param location string
param vpnGatewayScaleUnit int

resource hubvpngateway 'Microsoft.Network/vpnGateways@2023-04-01' = {
  name: hubgatewayName
  location: location
  properties: {
    virtualHub: {
      id: hubid
    }
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
  }
}

output id string = hubvpngateway.id
output name string = hubvpngateway.name
output gwpublicip1 string = hubvpngateway.properties.ipConfigurations[0].publicIpAddress
output gwpublicip2 string = hubvpngateway.properties.ipConfigurations[1].publicIpAddress
output gwprivateip string = hubvpngateway.properties.ipConfigurations[0].privateIpAddress
output gwdefaultbgpip1 string = hubvpngateway.properties.bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]
output gwdefaultbgpip2 string = hubvpngateway.properties.bgpSettings.bgpPeeringAddresses[1].defaultBgpIpAddresses[0]
