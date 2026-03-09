param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** Cloud-Vnet ****************************** */
module nsgSite1 'br/public:avm/res/network/network-security-group:0.5.2' = {
  name: 'NetworkSecurityGroupSite1'
  params: {
    name: 'nsg-site1'
    location: locationSite1
  }
}

module cloudVnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: 'cloud-vnet'
  params: {
    tags: {
      project: 'toizumi_recipes'
    }
    name: 'cloud-vnet'
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
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.1.0/24'
      }
    ]
  }
}

module bastion 'br/public:avm/res/network/bastion-host:0.8.2' = {
  name: 'bastion-deploy'
  params: {
    name: 'bastion-host'
    location: locationSite1
    publicIPAddressObject: {
      name: 'bastion-pip'
    }
    virtualNetworkResourceId: cloudVnet.outputs.resourceId
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:2.0.1' = {
  name: 'nat-gateway-deploy'
  params: {
    name: 'nat-gateway'
    location: locationSite1
    availabilityZone: 1
    publicIPAddresses: [
      {
        name: 'nat-gateway-pip-01'
        availabilityZones: [1]
      }
    ]
  }
}

module Linuxvm 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'linux-vm-deploy'
  params: {
    name: 'linux-vm'
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
            subnetResourceId: cloudVnet.outputs.subnetResourceIds[0]
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

module windowsvm 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
name: 'windows-vm-deploy'
  params: {
    name: 'windows-vm'
    location: locationSite1
    osType: 'Windows'
    vmSize: 'Standard_D4s_v3'
    availabilityZone: -1
    adminUsername: vmAdminUsername
    adminPassword: vmAdminPassword
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2025-datacenter-g2'
      version: 'latest'
    }
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
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
            subnetResourceId: cloudVnet.outputs.subnetResourceIds[0]
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

