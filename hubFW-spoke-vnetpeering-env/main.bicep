param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
var useExisting = false


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
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
  dependsOn: [
    rt2
  ]
}

resource rt1 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'routeTable1'
  location: locationSite2
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'fw-spoke-route1'
        properties: {
          addressPrefix: '10.10.0.0/16'
          nextHopIpAddress: '10.0.1.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'fw-spoke-route2'
        properties: {
          addressPrefix: '10.20.0.0/16'
          nextHopIpAddress: '10.0.1.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

resource rt2 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'routeTable2'
  location: locationSite1
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'fw-onpre-route1'
        properties: {
          addressPrefix: '10.100.0.0/16'
          nextHopIpAddress: '10.0.1.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module azfw '../modules/azurefirewall.bicep' = {
  name: 'AzureFirewall'
  params: {
    azurefwName: 'AzureFirewall'
    location: locationSite1
    subnetid: cloud_vnet.properties.subnets[1].id
    firewallPolicyID: firewall_policy.id
    skuname: 'AZFW_VNet'
    skutier: 'Standard'
  }
}

resource firewall_policy 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: 'policy'
  location: locationSite1
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

resource firewall_network_rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  parent: firewall_policy
  name: 'networkrule1'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'allowAll'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

module cloudvm '../modules/ubuntu20.04.bicep' = {
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

resource cloud_onpre_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: cloud_vnet
  name: 'peer1'
  properties: {
    remoteVirtualNetwork: {
      id: onpre_vnet.id
    }
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}

resource onpre_cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: onpre_vnet
  name: 'peer2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet.id
    }
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}

resource spoke_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = [for i in range (0, numberofSpokeVnet): {
  parent: cloud_vnet
  name: 'spoke-peer${i}'
  properties: {
    remoteVirtualNetwork: {
      id: spoke_vnet[i].id
    }
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
  }
}]

/* ****************************** Cloud-SpokeVnet ****************************** */
var numberofSpokeVnet = 2
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = [for i in range (0, numberofSpokeVnet):{
  name: 'spoke-vnet${i+1}'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${i+1}0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.${i+1}0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
          routeTable: { id: rt2.id }
        }
      }
    ]
  }
  dependsOn: [
    rt1
  ]
}]

module spokevm '../modules/ubuntu20.04.bicep' = [for i in range (0, numberofSpokeVnet):{
  name: 'spoke-vm${i}'
  params: {
    vmName: 'spoke-vm${i+1}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: spoke_vnet[i].properties.subnets[0].id
  }
}]

resource cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = [for i in range (0, numberofSpokeVnet): {
  parent: spoke_vnet[i]
  name: 'cloud-peer${i+1}'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
}]

/* ****************************** Onpre-Vnet ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'  
  }
}

resource onpre_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet'
  location: locationSite2
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.100.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
          routeTable: {id: rt1.id}
        }
      }
    ]
  }
}


module onprevm '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-vm'
  params: {
    vmName: 'onpre-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
  }
}
