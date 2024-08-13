param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** Global Load Balancer  ****************************** */

resource globalLBPIP 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: 'GlobalLBPIP'
  location: 'centralus'
  sku: {
    name: 'Standard'
    tier: 'Global'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource GlobalLB 'Microsoft.Network/loadBalancers@2023-02-01' = {
  name: 'GlobalLB'
  location: 'centralus'
  sku: {
    name: 'Standard'
    tier: 'Global'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'GlobalLBFrontend'
        properties: {
          publicIPAddress: {
            id: globalLBPIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'GlobalLBBackendPool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'GlobalLB', 'GlobalLBFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'GlobalLB', 'GlobalLBBackendPool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
        }
      }
    ]
  }
}

resource globalLBbackendpool 'Microsoft.Network/loadBalancers/backendAddressPools@2023-02-01' = {
  parent: GlobalLB
  name: 'GlobalLBBackendPool'
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'address1'
        properties: {
          loadBalancerFrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancer1.name, 'LoadBalancerFrontend')
          }
        }
      }
      {
        name: 'address2'
        properties: {
          loadBalancerFrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancer2.name, 'LoadBalancerFrontend')
          }
        }
      }
    ]
  }
  dependsOn: [
    loadBalancer1
    loadBalancer2
  ]
}


/* ****************************** Cloud-Vnet1 ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource cloud_vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet1'
  location: locationSite1
  tags: {
    tagName1: 'toizumi_recipes'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

resource LBfrontendIP1 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'LBFrontend-pip1'
  location: locationSite1
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource loadBalancer1 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'PublicLB1'
  location: locationSite1
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: LBfrontendIP1.id
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'PublicLB1', 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'PublicLB1', 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'PublicLB1', 'lbprobe')
          }
          protocol: 'tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 5
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'tcp'
          port: 80
          intervalInSeconds: 5
        }
        name: 'lbprobe'
      }
    ]
  }
}

module clientvm1 '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm1'
  params: {
    vmName: 'clientvm1'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet1.properties.subnets[0].id
    usePublicIP: true
  }
}

var numberOfInstances1 = 2
module backendvms1 '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfInstances1):{
  name: 'backend-vm${i}'
  params: {
    vmName: 'backendvm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet1.properties.subnets[0].id
    loadBalancerBackendAddressPoolsId: loadBalancer1.properties.backendAddressPools[0].id
    customData: loadFileAsBase64('cloud-init.yml')
  }
}]

/* ****************************** Cloud-Vnet2 ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'
  }
}
resource cloud_vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet2'
  location: locationSite2
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
    ]
  }
}

resource LBfrontendIP2 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'LBFrontend-pip2'
  location: locationSite2
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource loadBalancer2 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'PublicLB2'
  location: locationSite2
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: LBfrontendIP2.id
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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'PublicLB2', 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'PublicLB2', 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'PublicLB2', 'lbprobe')
          }
          protocol: 'tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 5
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'tcp'
          port: 80
          intervalInSeconds: 5
        }
        name: 'lbprobe'
      }
    ]
  }
}

module clientvm2 '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm2'
  params: {
    vmName: 'clientvm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    subnetId: cloud_vnet2.properties.subnets[0].id
    usePublicIP: true
  }
}

var numberOfInstances2 = 2
module backendvms2 '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfInstances2):{
  name: 'backend-vm2${i}'
  params: {
    vmName: 'backendvm2${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    subnetId: cloud_vnet2.properties.subnets[0].id
    loadBalancerBackendAddressPoolsId: loadBalancer2.properties.backendAddressPools[0].id
    customData: loadFileAsBase64('cloud-init.yml')
  }
}]
