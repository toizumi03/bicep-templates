param locationSite1 string
param locationSite2 string
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

module virtualhub2 '../modules/virtualhub.bicep' = {
  name: 'virtualhub2'
  params:{
    virtualhubName: 'virtualhub2'
    location: locationSite1
    vhubAddressPrefix: '10.100.10.0/24'
    allowBranchToBranchTraffic: true
    virtualwanId: virtualwan.outputs.virtualwanId
  }
  dependsOn: [
    virtualwan
  ]
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

resource vnet_peering_vhub2 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub1/vnetpeeringvhub2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet2.id
    }
    enableInternetSecurity: true
  }
  dependsOn: [
    virtualhub1
    vnet_peering_vhub1
  ]
}

resource vnet_peering_vhub3 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub2/vnetpeeringvhub3'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet3.id
    }
    enableInternetSecurity: true
  }
  dependsOn: [
    virtualhub2
  ]
}


// vhub vpn site1
resource vpnsite1 'Microsoft.Network/vpnSites@2023-04-01' = {
  name: 'vpnsite1'
  location: locationSite1
  properties: {
    virtualWan: {
      id: virtualwan.outputs.virtualwanId
    }
    vpnSiteLinks: [
      {
        name: 'Link1'
        properties: {
          bgpProperties: {
            asn: 65010
            bgpPeeringAddress: split(onprevpngateway.outputs.bgpPeeringAddress, ',')[0]
          }
            ipAddress: onprevpngateway.outputs.publicIp01Address
            linkProperties: {
              linkProviderName: 'MS'
              linkSpeedInMbps: 50
        }
      }
    }
    {
      name: 'Link2'
      properties: {
        bgpProperties: {
          asn: 65010
          bgpPeeringAddress: split(onprevpngateway.outputs.bgpPeeringAddress, ',')[1]
        }
        ipAddress: onprevpngateway.outputs.publicIp02Address
        linkProperties: {
          linkProviderName: 'MS'
          linkSpeedInMbps: 50
        }
      }
    }
    ]
  }
  dependsOn:[
    virtualwan
    virtualhub1
    onprevpngateway
  ]
}


resource hubvpnsiteConnection1 'Microsoft.Network/vpnGateways/vpnConnections@2023-11-01' = {
  name: 'hubs2sgateway1/${vpnsite1.name}-connection'
  properties:{
    remoteVpnSite: {
      id: vpnsite1.id
    }
    vpnLinkConnections: [
      {
        id: '${resourceId('Microsoft.Network/vpnGateways/vpnConnections',hubs2sgateway1.name,'vpnsite1-connection')}/vpnLinkConnections/link1'
        name: 'Link1'
        properties: {
          connectionBandwidth: 50
          dpdTimeoutSeconds: 0
          enableBgp: true
          enableRateLimiting: false
          ipsecPolicies: []
          routingWeight: 0
          sharedKey: 'sharedpass'
          useLocalAzureIpAddress: false
          usePolicyBasedTrafficSelectors: false
          vpnConnectionProtocolType: 'IKEv2'
          vpnGatewayCustomBgpAddresses: []
          vpnLinkConnectionMode: 'Default'
          vpnSiteLink: {
            id: '${resourceId('Microsoft.Network/vpnSites',vpnsite1.name)}/vpnSiteLinks/link1'
          }
        }
      }
      {
        id: '${resourceId('Microsoft.Network/vpnGateways/vpnConnections',hubs2sgateway1.name,'vpnsite1-connection')}/vpnLinkConnections/link2'
        name: 'Link2'
        properties: {
          connectionBandwidth: 50
          dpdTimeoutSeconds: 0
          enableBgp: true
          enableRateLimiting: false
          ipsecPolicies: []
          routingWeight: 0
          sharedKey: 'sharedpass'
          useLocalAzureIpAddress: false
          usePolicyBasedTrafficSelectors: false
          vpnConnectionProtocolType: 'IKEv2'
          vpnGatewayCustomBgpAddresses: []
          vpnLinkConnectionMode: 'Default'
          vpnSiteLink: {
            id: '${resourceId('Microsoft.Network/vpnSites',vpnsite1.name)}/vpnSiteLinks/link2'
          }
        }
      }
    ]
  }
  dependsOn:[
    hubs2sgateway1
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
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.1.0/24'
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
    bgpAsn: 65010
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

var lng01Name = 'lng-cloud1'
resource lng_cloud1 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng01Name
  location: locationSite2
  properties: {
    gatewayIpAddress: hubs2sgateway1.outputs.gwpublicip1
    bgpSettings:{
      asn: 65515
      bgpPeeringAddress: hubs2sgateway1.outputs.gwdefaultbgpip1
    }
  }
}

var lng02Name = 'lng-cloud2'
resource lng_cloud2 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng02Name
  location: locationSite2
  properties: {
    gatewayIpAddress:hubs2sgateway1.outputs.gwpublicip2
    bgpSettings:{
      asn: 65515
      bgpPeeringAddress: hubs2sgateway1.outputs.gwdefaultbgpip2
    }
  }
}

// Connection from Onp to Cloud
resource connectionOnptoCloud1 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud1'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
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

resource connectionOnptoCloud2 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud2'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_cloud2.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

module onprevm1 '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-vm1'
  params: {
    vmName: 'onpre-vm1'
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
