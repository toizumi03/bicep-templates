param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** VNet1 ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}

resource vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet1'
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

module vm1 '../modules/ubuntu20.04.bicep' = {
  name: 'vm1'
  params: {
    vmName: 'vm1'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: vnet1.properties.subnets[0].id
  }
}

resource vnet1_to_vnet2_peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: vnet1
  name: 'vnet1tovnet2'
  properties: {
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}

/* ****************************** VNet2 ****************************** */
resource vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet2'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

module vm2 '../modules/ubuntu20.04.bicep' = {
  name: 'vm2'
  params: {
    vmName: 'vm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: vnet2.properties.subnets[0].id
  }
}

resource vnet2_to_vnet1_peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: vnet2
  name: 'vnet2tovnet1'
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
}

// Outputs for reference
output vm1Name string = vm1.outputs.vmName
output vm1PrivateIP string = vm1.outputs.privateIP
output vm2Name string = vm2.outputs.vmName
output vm2PrivateIP string = vm2.outputs.privateIP