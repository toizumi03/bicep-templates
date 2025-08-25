param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param enablediagnostics bool

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
          routeTable: { id: rt1.id }
        }
      }
    ]
  }
}

resource rt1 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'routeTable1'
  location: locationSite1
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'toVnet1'
        properties: {
          addressPrefix: '10.0.0.0/16'
          nextHopIpAddress: '10.10.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

resource cloud_peer1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: cloud_vnet2
  name: 'vnet2tovnet3'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet3.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
  }
}

resource cloud_peer2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: cloud_vnet3
  name: 'vnet3tovnet2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet2.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
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

module virtualhub1 '../modules/virtualhub.bicep' = {
  name: 'virtualhub1'
  params:{
    virtualhubName: 'virtualhub1'
    location: locationSite1
    vhubAddressPrefix: '10.100.0.0/24'
    allowBranchToBranchTraffic: true
    virtualwanId: virtualwan.outputs.virtualwanId
  }
  dependsOn: [
    virtualwan
  ]
}

module hubbgpconnection '../modules/virtualhubbgpconnection.bicep' = {
  name: 'hubbgpconnection'
  params: {
    virtualHubName: 'virtualhub1'
    bgpconnectionname: 'bgp-connection-1'
    hubVirtualNetworkConnectionID: vnet_peering_vhub2.id
    ASN: 65001
    peerIp: '10.10.0.4'
  }
  dependsOn: [
    virtualhub1
    vnet_peering_vhub1
    vhubfw1
    routing_intent1
  ]
}

resource vhubfw1 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: 'vhubFW1'
  location: locationSite1
  properties: {
    virtualHub: {
    id: virtualhub1.outputs.virtualhubId
    }
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    firewallPolicy: {
      id: firewall_policy1.id
    }
  }
  dependsOn: [
    virtualhub1
  ]
}


resource firewall_policy1 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: 'policy1'
  location: locationSite1
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

resource firewall_network_rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  parent: firewall_policy1
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

resource routing_intent1 'Microsoft.Network/virtualHubs/routingIntent@2024-07-01' = {
  name: 'virtualhub1/routingIntent1'
  properties: {
    routingPolicies:[
      {
        destinations: [
          'PrivateTraffic'
        ]
        name: 'PrivateTraffic'
        nextHop:vhubfw1.id
      }
    ]
  }
  dependsOn: [
    virtualhub1
    vhubfw1
    diagnosticLogs
    vnet_peering_vhub1
    vnet_peering_vhub2
  ]
}


resource vnet_peering_vhub1 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub1/vnetpeeringvhub1'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet1.id
    }
  }
  dependsOn: [
    virtualhub1
  ]
}

resource vnet_peering_vhub2 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub1/vnetpeeringvhub2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet2.id
    }
  }
  dependsOn: [
    virtualhub1
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
    subnetId: cloud_vnet3.properties.subnets[0].id
  }
}

module NVA '../modules/ubuntu20.04.bicep' = {
  name: 'NVA-FRR'
  params: {
    vmName: 'NVA-FRR'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet2.properties.subnets[0].id
    enableIPForwarding: true
    customData: loadFileAsBase64('cloud-init.yml')
  }
}

/* ****************************** enable diagnostic logs ****************************** */

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablediagnostics){
  name: vhubfw1.name
  scope: vhubfw1
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}

