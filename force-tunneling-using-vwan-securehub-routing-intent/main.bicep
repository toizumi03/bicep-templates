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
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
          routeTable: { id: rt1.id }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '192.168.2.0/24'
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: '192.168.3.0/24'
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
        name: 'defaultroute-to-AzureFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '192.168.2.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module azfw '../modules/azurefirewall-forcetunnel.bicep' = {
  name: 'AzureFirewall'
  params: {
    azurefwName: 'AzureFirewall'
    location: locationSite1
    subnetid: cloud_vnet1.properties.subnets[2].id
    firewallPolicyID: firewall_policy.id
    skuname: 'AZFW_VNet'
    skutier: 'Standard'
    mgdsubnetid: cloud_vnet1.properties.subnets[3].id
    logAnalyticsWorkspaceId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
  dependsOn: [
    cloudvpngateway
  ]
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

var cloudvpngwName = 'cloud-vpngw'
module cloudvpngateway '../modules/vpngw_act-act.bicep' = {
  name: cloudvpngwName
  params: {
    location: locationSite1
    gatewayName: cloudvpngwName
    vnetName: cloud_vnet1.name
    enablePrivateIpAddress: false
    bgpAsn: 65020
    useExisting: useExisting
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
  dependsOn: [
    cloudvm1
  ]
}

var lng01Name = 'lng-cloud1'
resource lng_cloud1 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng01Name
  location: locationSite1
  properties: {
    gatewayIpAddress: hubs2sgateway1.outputs.gwpublicip1
    bgpSettings:{
      asn: 65515
      bgpPeeringAddress: hubs2sgateway1.outputs.gwdefaultbgpip1
    }
  }
}

// Connection from Onp to Cloud
resource connectionOnptoCloud1 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud1'
  location: locationSite1
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_cloud1.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'sharedpass'
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

module hubs2sgateway1 '../modules/vhubs2sgateway.bicep' = {
  name: 'hubs2sgateway1'
  params:{
  hubgatewayName: 'hubs2sgateway1'
  location: locationSite1
  hubid: virtualhub1.outputs.virtualhubId
  vpnGatewayScaleUnit: 2
  logAnalyticsId: logAnalytics.id
  enablediagnostics: enablediagnostics
  }
}

// vhub vpn site
module vpnsite1 '../modules/vhubvpnsite.bicep' = {
  name: 'vpnsite1'
  params:{
    siteName: 'vpnsite1'
    location: locationSite1
    siteAddressPrefix : cloud_vnet1.properties.addressSpace.addressPrefixes[0]
    bgpasn : 65020
    bgpPeeringAddress : split(cloudvpngateway.outputs.bgpPeeringAddress, ',')[0]
    linkSpeedInMbps : 50
    vpnDeviceIpAddress : cloudvpngateway.outputs.publicIp01Address
    wanId : virtualwan.outputs.virtualwanId
  }
  dependsOn:[
    virtualwan
    virtualhub1
    cloudvpngateway
  ]
}

resource hubvpnsiteConnection1 'Microsoft.Network/vpnGateways/vpnConnections@2023-04-01' = {
  name: 'hubs2sgateway1/${vpnsite1.name}-connection'
  properties: {
    connectionBandwidth: 50
    enableBgp: true
    sharedKey: 'sharedpass'
    remoteVpnSite: {
      id: vpnsite1.outputs.vpnsiteid
    }
  }
  dependsOn:[
    hubs2sgateway1
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
      id: firewall_policy.id
    }
  }
  dependsOn: [
    virtualhub1
  ]
}

/* ****************************** enable diagnostic logs ****************************** */

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablediagnostics){
  name: vhubfw1.name
  scope: vhubfw1
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

resource routing_intent1 'Microsoft.Network/virtualHubs/routingIntent@2023-06-01' = {
  name: 'virtualhub1/routingIntent1'
  properties: {
    routingPolicies:[
      {
        destinations: [
          'Internet'
        ]
        name: 'InternetTraffic'
        nextHop:vhubfw1.id
      }
    ]
  }
  dependsOn: [
    virtualhub1
    vhubfw1
    diagnosticLogs
  ]
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
