param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

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
          natGateway: {
            id: natgateway.outputs.natgatewayId
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

var bastionName = 'AzureBastion'
module bastion '../modules/bastion.bicep' = {
  name: bastionName
  params: {
    bastionName: bastionName
    location: locationSite1
    bastionsku: 'Standard'
    subnetid: cloud_vnet.properties.subnets[1].id
  }
}

var natgatewayName = 'natgateway'
module natgateway '../modules/natgateway.bicep' = {
  name: natgatewayName
  params: {
    natgatewayName: natgatewayName
    location: locationSite1  
  }
}

module ubuntuvm '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm'
  params: {
    vmName: 'ubuntu-2004-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet.properties.subnets[0].id
  }
}

