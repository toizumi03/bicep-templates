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
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

var lng01Name = 'lng-onp1'
resource lng_onp1 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng01Name
  location: locationSite1
  properties: {
    gatewayIpAddress: onprevpngateway.outputs.publicIp01Address
    bgpSettings:{
      asn: 65020
      bgpPeeringAddress: split(onprevpngateway.outputs.bgpPeeringAddress, ',')[0]
    }
  }
}

var lng02Name = 'lng-onp2'
resource lng_onp2 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng02Name
  location: locationSite1
  properties: {
    gatewayIpAddress: onprevpngateway.outputs.publicIp02Address
    bgpSettings:{
      asn: 65020
      bgpPeeringAddress: split(onprevpngateway.outputs.bgpPeeringAddress, ',')[1]
    }
  }
}

resource conncetionCloudtoOnp1 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp1'
  location: locationSite1
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_onp1.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

resource conncetionCloudtoOnp2 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp2'
  location: locationSite1
  properties: {
    enableBgp: true
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_onp2.id
      properties:{}
    }
    connectionType: 'IPsec'
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
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.100.1.0/24'
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
    bgpAsn: 65020
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

var lng03Name = 'lng-cloud1'
resource lng_cloud1 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng03Name
  location: locationSite2
  properties: {
    gatewayIpAddress:cloudvpngateway.outputs.publicIp01Address
    bgpSettings:{
      asn: 65010
      bgpPeeringAddress: split(cloudvpngateway.outputs.bgpPeeringAddress, ',')[0]
    }
  }
}

var lng04Name = 'lng-cloud2'
resource lng_cloud2 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng04Name
  location: locationSite2
  properties: {
    gatewayIpAddress:cloudvpngateway.outputs.publicIp02Address
    bgpSettings:{
      asn: 65010
      bgpPeeringAddress: split(cloudvpngateway.outputs.bgpPeeringAddress, ',')[1]
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

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
