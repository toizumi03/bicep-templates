param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** Cloud-Vnet ****************************** */

// Network Security Group
module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}

// Virtual Network
resource cloud_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet'
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

// virtual machine
module cloudvm '../modules/windows-server2022.bicep' = {
  name: 'cloud-vm'
  params: {
    vmName: 'cloud-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet.properties.subnets[0].id
  }
}

