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
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          routeTable: { id: rt1.id }
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

resource rt1 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'routeTable1'
  location: locationSite1
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'fw-spoke-route1'
        properties: {
          addressPrefix: '10.10.0.0/16'
          nextHopIpAddress: '10.0.2.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'fw-spoke-route2'
        properties: {
          addressPrefix: '10.20.0.0/16'
          nextHopIpAddress: '10.0.2.4'
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
        name: 'defaultRouteToFW'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.0.2.4'
          nextHopType: 'VirtualAppliance'
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
    bgpAsn: 65010
    useExisting: useExisting
  }
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
    enablediagnostics: enablediagnostics
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

resource conncetionCloudtoOnp 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp'
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
    connectionType: 'Vnet2Vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
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

resource spoke_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = [for i in range (0, numberofSpokeVnet): {
  parent: cloud_vnet
  name: 'spoke-peer${i}'
  properties: {
    remoteVirtualNetwork: {
      id: spoke_vnet[i].id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
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
    useRemoteGateways: true
  }
  dependsOn: [
    cloudvpngateway
  ]
}]

/* ****************************** Onpre-Vnet ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'
  }
}

resource rt_nvasubnet 'Microsoft.Network/routeTables@2023-04-01' = {
  name: 'rt-nvaSubnet'
  location: locationSite2
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
        name: 'subnet-1'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'nva-subnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
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

var onprevpngwName = 'onpre-vpngw'
module onprevpngateway '../modules/vpngw_act-act.bicep' = {
  name: onprevpngwName
  params: {
    location: locationSite2
    gatewayName: onprevpngwName
    vnetName: onpre_vnet.name
    enablePrivateIpAddress: false
    bgpAsn: 65515
    useExisting: useExisting
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

resource conncetionOnptoCloud 'Microsoft.Network/connections@2023-04-01' = {
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
