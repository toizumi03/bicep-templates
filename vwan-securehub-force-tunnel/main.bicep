param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
var useExisting = false
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

resource vhubfw 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: 'vhubFW'
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
      id: firewall_policy.id
    }
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

resource firewall_network_rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-07-01' = {
  parent: firewall_policy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'anyallow'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'rulecollection'
        priority: 100
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
        nextHop:vhubfw.id
      }
    ]
  }
  dependsOn: [
    virtualhub1
    diagnosticLogs
    vhubfw
    vnet_peering_vhub1
  ]
}

resource hubRouteTable_default 'Microsoft.Network/virtualHubs/hubRouteTables@2023-05-01' = {
  name: 'virtualhub1/defaultRouteTable'
  properties: {
    routes: [
      {
        name: '_policy_PrivateTraffic'
        destinationType: 'CIDR'
        destinations: [
          '10.0.0.0/8'
          '172.16.0.0/12'
          '192.168.0.0/16'
        ]
        nextHopType: 'ResourceId'
        nextHop: vhubfw.id
      }
      {
        name: 'private_traffic'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: vhubfw.id
      }
    ]
    labels: [
      'default'
    ]
  }
  dependsOn: [
    routing_intent1
  ]
}

module hubergateway '../modules/vhubergateway.bicep' = {
  name: 'hubergateway1'
  params:{
  hubgatewayName: 'hubergateway1'
  location: locationSite1
  hubid: virtualhub1.outputs.virtualhubId
  autoscale_bounds_max: 2
  autoscale_bounds_min: 2
  }
}

resource vnet_peering_vhub1 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub1/vnetpeeringvhub1'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet1.id
    }
    enableInternetSecurity: true
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

/* ****************************** enable diagnostic logs ****************************** */

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablediagnostics){
  name: vhubfw.name
  scope: vhubfw
  properties: {
    workspaceId: logAnalytics.id
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



/* ****************************** Onpre-Vnet ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite1
    name: 'nsg-site2'  
  }
}

resource onpre_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-1'
        properties: {
          addressPrefix: '172.16.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'nva-subnet'
        properties: {
          addressPrefix: '172.16.1.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
          routeTable: { id: rt_nvasubnet.id }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '172.16.2.0/24'
        }
      }
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: '172.16.3.0/24'
        }
      }
    ]
  }
}

resource rt_nvasubnet 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-nvaSubnet'
  location: locationSite1
  properties: {
    routes: [
      {
        name: 'toInternet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

var onpreergwName = 'onpre-ergw'
module onpreergateway '../modules/ergw.bicep' = {
  name: onpreergwName
  params: {
    location: locationSite1
    gatewayName: onpreergwName
    vnetName: onpre_vnet.name
    sku: 'ErGw1Az'
  }
}

var routeservername = 'RouteServer'
module routeserver '../modules/routeserver.bicep' = {
  name: routeservername
  params: {
    location: locationSite1
    routeserverName: routeservername
    vnetName: onpre_vnet.name
    useExisting: useExisting
    bgpConnections: [
      {
        name: NVA.outputs.vmName
        ip: NVA.outputs.privateIP
        asn: '65010'
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
    location: locationSite1
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
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
    subnetId: onpre_vnet.properties.subnets[1].id
    enableIPForwarding: true
    customData: loadFileAsBase64('cloud-init.yml')
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
