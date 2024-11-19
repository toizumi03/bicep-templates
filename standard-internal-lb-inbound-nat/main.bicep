@description('Username for the Virtual Machine.')
param vmAdminUsername string
@description('Password for the Virtual Machine.')
@secure()
param vmAdminPassword string
@description('All resources will be deployed to this location.')
param locationSite1 string

/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource cloud_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet'
  location: locationSite1
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

resource InternalLB 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'InternalLB'
  location: locationSite1
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'cloud-vnet', 'default')
          }
          privateIPAddress: '10.0.0.100'
          privateIPAllocationMethod: 'Static'
        }
        name: 'LoadBalancerFrontend'
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    inboundNatRules: [
      {
        name: 'InboundNATRule1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'InternalLB', 'LoadBalancerFrontend')
          }
          protocol: 'Tcp'
          frontendPort: 0
          backendPort: 22
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          enableTcpReset: false
          frontendPortRangeStart:500
          frontendPortRangeEnd: 510
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'InternalLB', 'BackendPool1')
          }
        }
      }
    ]
  }
  dependsOn: [
    cloud_vnet
  ]
}

module clientvm '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm'
  params: {
    vmName: 'clientvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet.properties.subnets[0].id
    usePublicIP: true
  }
}

var numberOfInstances = 5
module backendvms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfInstances):{
  name: 'backend-vm${i}'
  params: {
    vmName: 'backendvm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet.properties.subnets[0].id
    loadBalancerBackendAddressPoolsId: InternalLB.properties.backendAddressPools[0].id
    usePublicIP: true
  }
}]

