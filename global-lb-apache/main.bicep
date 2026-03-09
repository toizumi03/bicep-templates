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
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LoadBalancer1.name, 'LoadBalancerFrontend')
          }
        }
      }
      {
        name: 'address2'
        properties: {
          loadBalancerFrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LoadBalancer2.name, 'LoadBalancerFrontend')
          }
        }
      }
    ]
  }
}

/* ****************************** Cloud-Vnet1 ****************************** */

module nsgSite1 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite1'
  params: {
    name: 'nsg-site1'
    location: locationSite1
    securityRules: [
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

module cloudVnet1 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet1'
  params: {
    tags: {
      project: 'toizumi_recipes'
    }
    name: 'cloud-vnet1'
    location: locationSite1
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
    ]
  }
}

module LoadBalancer1 'br/public:avm/res/network/load-balancer:0.6.0' = {
  name: 'PublicLB1'
  params: {
    name: 'PublicLB1'
    location: locationSite1
    skuName: 'Standard'
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        publicIPAddressConfiguration: {
          name: 'PublicLB1-pip-01'
          skuName: 'Standard'
          publicIPAllocationMethod: 'Static'
          availabilityZones: [
            1
            2
            3
          ]
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
        name: 'lbrule'
        frontendIPConfigurationName: 'LoadBalancerFrontend'
        backendAddressPoolName: 'BackendPool1'
        probeName: 'lbprobe'
        protocol: 'Tcp'
        frontendPort: 80
        backendPort: 80
        idleTimeoutInMinutes: 5
        enableFloatingIP: false
      }
    ]
    probes: [
      {
        name: 'lbprobe'
        protocol: 'Tcp'
        port: 80
        intervalInSeconds: 5
      }
    ]
  }
}


module clientvm 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
  name: 'client-vm-deploy'
  params: {
    name: 'client-vm'
    location: locationSite1
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: cloudVnet1.outputs.subnetResourceIds[0]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
              skuName: 'Standard'
              publicIPAllocationMethod: 'Static'
              availabilityZones: [
                1
                2
                3
              ]
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}



var numberOfInstances1 = 2
module backendvms 'br/public:avm/res/compute/virtual-machine:0.21.0' = [for i in range(0, numberOfInstances1): {
  name: 'backend-vm-site1-${i}'
  params: {
    name: 'backend-vm-site1-${i}'
    location: locationSite1
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    customData: loadTextContent('cloud-init.yml')
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: cloudVnet1.outputs.subnetResourceIds[0]
            loadBalancerBackendAddressPools: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LoadBalancer1.outputs.name, 'BackendPool1')
              }
            ]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}]

/* ****************************** Cloud-Vnet2 ****************************** */

module nsgSite2 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite2'
  params: {
    name: 'nsg-site2'
    location: locationSite2
    securityRules: [
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

module cloudVnet2 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet2'
  params: {
    tags: {
      project: 'toizumi_recipes'
    }
    name: 'cloud-vnet2'
    location: locationSite2
    addressPrefixes: [
      '10.10.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.10.0.0/24'
        networkSecurityGroupResourceId: nsgSite2.outputs.resourceId
      }
    ]
  }
}

module LoadBalancer2 'br/public:avm/res/network/load-balancer:0.6.0' = {
  name: 'PublicLB2'
  params: {
    name: 'PublicLB2'
    location: locationSite2
    skuName: 'Standard'
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        publicIPAddressConfiguration: {
          name: 'PublicLB2-pip-01'
          skuName: 'Standard'
          publicIPAllocationMethod: 'Static'
          availabilityZones: [
            1
            2
            3
          ]
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
        name: 'lbrule'
        frontendIPConfigurationName: 'LoadBalancerFrontend'
        backendAddressPoolName: 'BackendPool1'
        probeName: 'lbprobe'
        protocol: 'Tcp'
        frontendPort: 80
        backendPort: 80
        idleTimeoutInMinutes: 5
        enableFloatingIP: false
      }
    ]
    probes: [
      {
        name: 'lbprobe'
        protocol: 'Tcp'
        port: 80
        intervalInSeconds: 5
      }
    ]
  }
}


var numberOfInstances2 = 2
module backendvms2 'br/public:avm/res/compute/virtual-machine:0.21.0' = [for i in range(0, numberOfInstances2): {
  name: 'backend-vm-site2-${i}'
  params: {
    name: 'backendvm-site2-${i}'
    location: locationSite2
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    customData: loadTextContent('cloud-init.yml')
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 30
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: cloudVnet2.outputs.subnetResourceIds[0]
            loadBalancerBackendAddressPools: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LoadBalancer2.outputs.name, 'BackendPool1')
              }
            ]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}]
