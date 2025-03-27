param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string


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
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
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
    subnetId: cloud_vnet1.properties.subnets[1].id
  }
}

resource spoke_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: cloud_vnet1
  name: 'vnet1tovnet2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet2.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    peerCompleteVnets: false
    localSubnetNames: [
      'subnet-1'
      'subnet-2'
    ]
    remoteSubnetNames: [
      'subnet-3'
      'subnet-4'
    ]
  }
}

/* ****************************** Cloud-Vnet2 ****************************** */
resource cloud_vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet2'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-3'
        properties: {
          addressPrefix: '10.100.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'subnet-4'
        properties: {
          addressPrefix: '10.100.1.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'subnet-5'
        properties: {
          addressPrefix: '10.100.2.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
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
    subnetId: cloud_vnet2.properties.subnets[0].id
  }
}

module cloudvm4 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm4'
  params: {
    vmName: 'cloud-vm4'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet2.properties.subnets[1].id
  }
}

module cloudvm5 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-vm5'
  params: {
    vmName: 'cloud-vm5'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet2.properties.subnets[2].id
  }
}

resource cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: cloud_vnet2
  name: 'vnet2tovnet1'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet1.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    peerCompleteVnets: false
    localSubnetNames: [
      'subnet-3'
      'subnet-4'
    ]
    remoteSubnetNames: [
      'subnet-1'
      'subnet-2'
    ]
  }
}

