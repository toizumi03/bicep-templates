@description('Username for the Virtual Machine.')
param vmAdminUsername string
@description('Password for the Virtual Machine.')
@secure()
param vmAdminPassword string
@description('All resources will be deployed to this location.')
param locationSite1 string

/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite1'
  params: {
    location: locationSite1
    name: 'nsg-site1'  
  }
}

module cloud_vnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet'
  params: {
    location: locationSite1
    name: 'cloud-vnet'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: defaultNSGSite1.outputs.resourceId
      }
    ]
  }
}

resource internalLB 'Microsoft.Network/loadBalancers@2025-05-01' = {
  name: 'internal-LB'
  location: locationSite1
  sku: {
    name: 'Basic'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'feConfig'
        properties: {
          privateIPAddress: '10.0.0.100'
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: cloud_vnet.outputs.subnetResourceIds[0]
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'bePool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'internal-LB', 'feConfig')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'internal-LB', 'bePool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'internal-LB', 'probe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'probe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
        }
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
            subnetResourceId: cloud_vnet.outputs.subnetResourceIds[0]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}

var numberOfInstances = 2
module backendvms 'br/public:avm/res/compute/virtual-machine:0.21.0' = [for i in range(0, numberOfInstances): {
  name: 'backend-vm${i}'
  params: {
    name: 'backendvm${i}'
    location: locationSite1
    osType: 'Linux'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    availabilitySetResourceId: availabilityset.outputs.resourceId
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
            subnetResourceId: cloud_vnet.outputs.subnetResourceIds[0]
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
              skuName: 'Basic'
              availabilityZones: []
            }
            loadBalancerBackendAddressPools: [
              {
                id: internalLB.properties.backendAddressPools[0].id
              }
            ]
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}]

module availabilityset 'br/public:avm/res/compute/availability-set:0.2.3' = {
  name: 'availabilityset'
  params: {
    name: 'availabilityset'
    location: locationSite1
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
    skuName: 'Aligned'
  }
}
