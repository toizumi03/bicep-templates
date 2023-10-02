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

resource cloud_vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet1'
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

resource cloud_vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet2'
  location: locationSite1
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
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

resource cloud_vnet3 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet3'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.20.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

module virtualwan '../modules/virtualwan.bicep' = {
  name: 'virtualwan'
  params:{
    virtualwanName: 'virtualwan'
    location: locationSite1
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
  }
}

var numberofhub = 2
module virtualhub '../modules/virtualhub.bicep' = [for i in range(1, numberofhub):{
  name: 'virtualhub${i}'
  params:{
    virtualhubName: 'virtualhub${i}'
    location: locationSite1
    vhubAddressPrefix: '10.100.${i}0.0/24'
    allowBranchToBranchTraffic: true
    virtualwanId: virtualwan.outputs.virtualwanId
  }
  dependsOn: [
    virtualwan
  ]
}]

module connect1 '../modules/hubvirtualnetworkconnection.bicep' = {
  name: 'hub2vnet1connection'
  params:{
    hub2vnetconnection: 'virtualhub1/hub2vnet1connection'
    vnetid: cloud_vnet1.id
  }
  dependsOn: [
    virtualwan
    virtualhub
    cloud_vnet1
  ]
}

module connect2 '../modules/hubvirtualnetworkconnection.bicep' = {
  name: 'hub2vnet2connection'
  params:{
    hub2vnetconnection: 'virtualhub1/hub2vnet2connection'
    vnetid: cloud_vnet2.id
  }
  dependsOn: [
    virtualwan
    virtualhub
    cloud_vnet2
  ]
}

module connect3 '../modules/hubvirtualnetworkconnection.bicep' = {
  name: 'hub2vnet3connection'
  params:{
    hub2vnetconnection: 'virtualhub2/hub2vnet3connection'
    vnetid: cloud_vnet3.id
  }
  dependsOn: [
    virtualwan
    virtualhub
    cloud_vnet3
  ]
}

module cloudvm1 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm1'
  params: {
    vmName: 'cloud-vm1'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet1.properties.subnets[0].id
  }
}

module cloudvm2 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm2'
  params: {
    vmName: 'cloud-vm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet2.properties.subnets[0].id
  }
}

module cloudvm3 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm3'
  params: {
    vmName: 'cloud-vm3'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet3.properties.subnets[0].id
  }
}

