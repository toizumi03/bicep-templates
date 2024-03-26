param locationSite1 string
param locationSite2 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
var useExisting = false
param enablediagnostics bool

/* ****************************** Virtual Wan ****************************** */
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

resource vnet_peering_vhub3 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-05-01' = {
  name: 'virtualhub2/vnetpeeringvhub3'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet3.id
    }
  }
  dependsOn: [
    virtualhub2
  ]
}


// vhub vpn site
module vpnsite1 '../modules/vhubvpnsite.bicep' = {
  name: 'vpnsite1'
  params:{
    siteName: 'vpnsite1'
    location: locationSite1
    siteAddressPrefix : onpre_vnet1.properties.addressSpace.addressPrefixes[0]
    bgpasn : 65010
    bgpPeeringAddress : split(onprevpngateway1.outputs.bgpPeeringAddress, ',')[0]
    linkSpeedInMbps : 50
    vpnDeviceIpAddress : onprevpngateway1.outputs.vpnpublicIp
    wanId : virtualwan.outputs.virtualwanId
  }
  dependsOn:[
    virtualwan
    virtualhub1
    onprevpngateway1
  ]
}

module vpnsite2 '../modules/vhubvpnsite.bicep' = {
  name: 'vpnsite2'
  params:{
    siteName: 'vpnsite2'
    location: locationSite1
    siteAddressPrefix : onpre_vnet2.properties.addressSpace.addressPrefixes[0]
    bgpasn : 65020
    bgpPeeringAddress : split(onprevpngateway2.outputs.bgpPeeringAddress, ',')[0]
    linkSpeedInMbps : 50
    vpnDeviceIpAddress : onprevpngateway2.outputs.vpnpublicIp
    wanId : virtualwan.outputs.virtualwanId
  }
  dependsOn:[
    virtualwan
    virtualhub1
    onprevpngateway2
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

resource hubvpnsiteConnection2 'Microsoft.Network/vpnGateways/vpnConnections@2023-04-01' = {
  name: 'hubs2sgateway1/${vpnsite2.name}-connection'
  properties: {
    connectionBandwidth: 50
    enableBgp: true
    sharedKey: 'sharedpass'
    remoteVpnSite: {
      id: vpnsite2.outputs.vpnsiteid
    }
  }
  dependsOn:[
    hubs2sgateway1
    hubvpnsiteConnection1
  ]
}

module routemap1 '../modules/routemap.bicep' = {
  name: 'routemap1'
  params:{
    routemapname: 'virtualhub1/routemap1'
    rulename: 'rule1'
    matchcriteria_prefix: ['192.168.0.0/15']
    matchCondition: 'Contains'
    nextStepIfMatched: 'Continue'
    associatedInboundConnections: [
      hubvpnsiteConnection1.id
      hubvpnsiteConnection2.id
    ]
    associatedOutboundConnections: [
      hubvpnsiteConnection1.id
      hubvpnsiteConnection2.id
    ]
    action_prefix: ['192.168.0.0/15']
    action_type: 'Replace'
  }
  dependsOn:[
    hubs2sgateway1
    hubvpnsiteConnection1
    hubvpnsiteConnection2
  ]
}


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


/* ****************************** Onpre-nsg ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'  
  }
}

/* ****************************** Onpre-Vnet1 ****************************** */

resource onpre_vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet1'
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

var onprevpngw1Name = 'onpre-vpngw1'
module onprevpngateway1 '../modules/vpngw_single.bicep' = {
  name: onprevpngw1Name
  params: {
    location: locationSite2
    gatewayName: onprevpngw1Name
    vnetName: onpre_vnet1.name
    enablePrivateIpAddress: false
    bgpAsn: 65010
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

// Connection from Onp to Cloud
resource connectionOnptoCloud1 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud1'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway1.outputs.vpngwId
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

module onprevm1 '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-vm1'
  params: {
    vmName: 'onpre-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet1.properties.subnets[0].id
  }
}

/* ****************************** Onpre-Vnet2 ****************************** */

resource onpre_vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet2'
  location: locationSite2
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.169.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.169.1.0/24'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.169.2.0/24'
        }
      }
    ]
  }
}

var onprevpngw2Name = 'onpre-vpngw2'
module onprevpngateway2 '../modules/vpngw_single.bicep' = {
  name: onprevpngw2Name
  params: {
    location: locationSite2
    gatewayName: onprevpngw2Name
    vnetName: onpre_vnet2.name
    enablePrivateIpAddress: false
    bgpAsn: 65020
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

var lng02Name = 'lng-cloud2'
resource lng_cloud2 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng02Name
  location: locationSite2
  properties: {
    gatewayIpAddress: hubs2sgateway1.outputs.gwpublicip1
    bgpSettings:{
      asn: 65515
      bgpPeeringAddress: hubs2sgateway1.outputs.gwdefaultbgpip1
    }
  }
}


resource connectionOnptoCloud2 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud2'
  location: locationSite2
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: onprevpngateway2.outputs.vpngwId
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

module onprevm2 '../modules/ubuntu20.04.bicep' = {
  name: 'onpre-vm2'
  params: {
    vmName: 'onpre-vm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet2.properties.subnets[0].id
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
