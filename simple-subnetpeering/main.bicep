param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string


/* ****************************** Cloud-Vnet1 ****************************** */
module nsgSite1 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite1'
  params: {
    name: 'nsg-site1'
    location: locationSite1
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
      '172.16.0.0/16'
    ]
    subnets: [
      {
        name: 'subnet-1'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
      {
        name: 'subnet-2'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'subnet-3'
        addressPrefix: '172.16.0.0/16'
      }
    ]
  }
}

module cloudVnet1vms 'br/public:avm/res/compute/virtual-machine:0.21.0' = [for i in range(0, 3): {
  name: 'cloud-vm${i + 1}-deploy'
  params: {
    name: 'cloud-vm${i + 1}'
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
            subnetResourceId: cloudVnet1.outputs.subnetResourceIds[i]
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
module cloudVnet2 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet2'
  params: {
    tags: {
      project: 'toizumi_recipes'
    }
    name: 'cloud-vnet2'
    location: locationSite1
    addressPrefixes: [
      '10.100.0.0/16'
      '172.16.0.0/16'
    ]
    subnets: [
      {
        name: 'subnet-4'
        addressPrefix: '10.100.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
      {
        name: 'subnet-5'
        addressPrefix: '10.100.1.0/24'
      }
      {
        name: 'subnet-6'
        addressPrefix: '172.16.0.0/16'
      }
    ]
  }
}

module cloudVnet2vms 'br/public:avm/res/compute/virtual-machine:0.21.0' = [for i in range(0, 3): {
  name: 'cloud-vm${i + 4}-deploy'
  params: {
    name: 'cloud-vm${i + 4}'
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
            subnetResourceId: cloudVnet2.outputs.subnetResourceIds[i]
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


/* ****************************** Subnet Peering ****************************** */
resource cloudVnet1Ref 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'cloud-vnet1'
}

resource cloudVnet2Ref 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'cloud-vnet2'
}

resource vnet1toVnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: cloudVnet1Ref
  name: 'vnet1tovnet2'
  properties: {
    remoteVirtualNetwork: {
      id: cloudVnet2Ref.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    peerCompleteVnets: false
    localSubnetNames: [
      'subnet-1'
      'subnet-2'
    ]
    remoteSubnetNames: [
      'subnet-4'
      'subnet-5'
    ]
  }
  dependsOn: [
    cloudVnet1
    cloudVnet2
  ]
}

resource vnet2toVnet1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: cloudVnet2Ref
  name: 'vnet2tovnet1'
  properties: {
    remoteVirtualNetwork: {
      id: cloudVnet1Ref.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    peerCompleteVnets: false
    localSubnetNames: [
      'subnet-4'
      'subnet-5'
    ]
    remoteSubnetNames: [
      'subnet-1'
      'subnet-2'
    ]
  }
  dependsOn: [
    cloudVnet1
    cloudVnet2
  ]
}
