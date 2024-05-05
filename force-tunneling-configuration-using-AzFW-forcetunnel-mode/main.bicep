param locationSite1 string
param locationSite2 string
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
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
          routeTable: { id: defalt_subnet_UDR.id}
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

resource defalt_subnet_UDR 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'defalt_subnet_UDR'
  location: locationSite1
  properties: {
    routes: [
      {
        name: 'toInternet1'
        properties: {
          addressPrefix: '0.0.0.0/1'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.2.4'
        }
      }
      {
        name: 'toInternet2'
        properties: {
          addressPrefix: '128.0.0.0/1'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.2.4'
        }
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
    vnetName: cloud_vnet.name
    enablePrivateIpAddress: false
    bgpAsn: 65020
    useExisting: useExisting
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
  dependsOn: [
    cloudvm1
    cloudvm2
  ]
}

module azfw '../modules/azurefirewall-forcetunnel.bicep' = {
  name: 'AzureFirewall'
  params: {
    azurefwName: 'AzureFirewall'
    location: locationSite1
    subnetid: cloud_vnet.properties.subnets[2].id
    firewallPolicyID: firewall_policy.id
    skuname: 'AZFW_VNet'
    skutier: 'Standard'
    mgdsubnetid: cloud_vnet.properties.subnets[3].id
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


resource conncetionCloudtoOnp 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp1'
  location: locationSite1
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    virtualNetworkGateway2: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    connectionType: 'vnet2vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}


module cloudvm1 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-ubuntuvm'
  params: {
    vmName: 'cloud-ubuntuvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet.properties.subnets[0].id
  }
}

module cloudvm2 '../modules/windows-server2022.bicep' = {
  name: 'cloud-winvm'
  params: {
    vmName: 'cloud-winvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet.properties.subnets[0].id
  }
}

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
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'NVA-Subnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
          routeTable: { id: rt_nvasubnet.id }
        }
        
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.2.0/24'
        }
      }
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: '192.168.3.0/24'
        }
      }
    ]
  }
}

resource rt_nvasubnet 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-nvaSubnet'
  location: locationSite2
  properties: {
    routes: [
      {
        name: 'toInternet1'
        properties: {
          addressPrefix: '0.0.0.0/1'
          nextHopType: 'Internet'
        }
      }
      {
        name: 'toInternet'
        properties: {
          addressPrefix: '128.0.0.0/1'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

var onprevpngwName = 'onpre-vpngw'
module onprevpngateway '../modules/vpngw_act-act.bicep' = {
  name: onprevpngwName
  params: {
    location: locationSite2
    gatewayName: onprevpngwName
    vnetName: onpre_vnet.name
    enablePrivateIpAddress: false
    bgpAsn: 65515
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

var routeservername = 'RouteServer'
module routeserver '../modules/routeserver.bicep' = {
  name: routeservername
  params: {
    location: locationSite2
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

module NVA '../modules/ubuntu20.04.bicep' = {
  name: 'NVA-FRR'
  params: {
    vmName: 'NVA-FRR'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[1].id
    enableIPForwarding: true
    customData: loadFileAsBase64('cloud-init.yml')
  }
}


// Connection from Onp to Cloud
resource connectionOnptoCloud 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud1'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    virtualNetworkGateway2: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    connectionType: 'vnet2vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

module onprevm1 '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-ubuntuvm'
  params: {
    vmName: 'onpre-ubuntuvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
  }
}

module onprevm2 '../modules/windows-server2022.bicep' = {
  name: 'onpre-winvm'
  params: {
    vmName: 'onpre-winvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
