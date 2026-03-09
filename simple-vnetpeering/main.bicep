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
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
    ]
    peerings: [
      {
        remoteVirtualNetworkResourceId: cloudVnet2.outputs.resourceId
        allowForwardedTraffic: true
        allowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
      }
    ]
  }
}

module cloudvm1 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'cloud1-vm-deploy'
  params: {
    name: 'cloud-vm1'
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
            }
          }
        ]
      }
    ]
    encryptionAtHost: false
  }
}


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
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '10.100.0.0/24'
        networkSecurityGroupResourceId: nsgSite1.outputs.resourceId
      }
    ]
  }
}

module cloudvm2 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'cloud-vm2-deploy'
  params: {
    name: 'cloud-vm2'
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
            subnetResourceId: cloudVnet2.outputs.subnetResourceIds[0]
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
