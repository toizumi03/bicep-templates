param loadbalancerName string
param location string
param loadbalancingRules_protocol string
param loadbalancingRules_frontendPort int
param loadbalancingRules_backendPort int
param loadbalancingRules_idleTimeoutInMinutes int
param probes_protocol string
param probes_port int
param probes_intervalInSeconds int

resource LBfrontendIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'LBFrontend-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: loadbalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'LBFrontend-pip')
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadbalancerName, 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, 'lbprobe')
          }
          protocol: loadbalancingRules_protocol
          frontendPort: loadbalancingRules_frontendPort
          backendPort: loadbalancingRules_backendPort
          idleTimeoutInMinutes: loadbalancingRules_idleTimeoutInMinutes
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: probes_protocol
          port: probes_port
          intervalInSeconds: probes_intervalInSeconds
        }
        name: 'lbprobe'
      }
    ]
  }
}

output loadBalancerbackendAddressPools_id string = loadBalancer.properties.backendAddressPools[0].id
