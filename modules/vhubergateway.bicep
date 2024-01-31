param hubgatewayName string
param hubid string
param location string
param autoscale_bounds_max int
param autoscale_bounds_min int

resource hubergateway 'Microsoft.Network/expressRouteGateways@2023-04-01' = {
  name: hubgatewayName
  location: location
  properties: {
    virtualHub: {
      id: hubid
    }
    autoScaleConfiguration: {
      bounds: {
        max: autoscale_bounds_max
        min: autoscale_bounds_min
      }
    }
  }
}

output id string = hubergateway.id
output name string = hubergateway.name
