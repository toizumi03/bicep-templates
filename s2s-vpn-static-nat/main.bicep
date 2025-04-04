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
module cloudvpngateway '../modules/vpngw_single_gw2az.bicep' = {
  name: cloudvpngwName
  params: {
    location: locationSite1
    gatewayName: cloudvpngwName
    vnetName: cloud_vnet.name
    enablePrivateIpAddress: false
    useExisting: useExisting
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
    egressinternalmapping: '10.0.0.0/16'
    egressexternalmapping: '10.10.0.0/16'
    ingressinternalmapping: '10.0.0.0/16'
    ingressexternalmapping: '10.20.0.0/16'
  }
}


var lng01Name = 'lng-onp'
resource lng_onp 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng01Name
  location: locationSite1
  properties: {
    gatewayIpAddress: onprevpngateway.outputs.vpnpublicIp
    localNetworkAddressSpace:{
      addressPrefixes:[
        onpre_vnet.properties.addressSpace.addressPrefixes[0]
      ]
    }
  }
}

resource conncetionCloudtoOnp 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromCloudtoOnp'
  location: locationSite1
  properties: {
    enableBgp: false
    virtualNetworkGateway1: {
      id: cloudvpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_onp.id
      properties:{}
    }
    egressNatRules: [
      {
        id: cloudvpngateway.outputs.egressnatrule
      }
    ]
    ingressNatRules: [
      {
        id: cloudvpngateway.outputs.ingressnatrule
      }
    ]
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


resource onpre_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'onpre-vnet'
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

var onprevpngwName = 'onpre-vpngw'
module onprevpngateway '../modules/vpngw_single_gw2az.bicep' = {
  name: onprevpngwName
  params: {
    location: locationSite1
    gatewayName: onprevpngwName
    vnetName: onpre_vnet.name
    enablePrivateIpAddress: false
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
    egressinternalmapping: '10.0.0.0/16'
    egressexternalmapping: '10.20.0.0/16'
    ingressinternalmapping: '10.0.0.0/16'
    ingressexternalmapping: '10.10.0.0/16'
  }
}

var lng02Name = 'lng-cloud'
resource lng_cloud 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: lng02Name
  location: locationSite1
  properties: {
    gatewayIpAddress:cloudvpngateway.outputs.vpnpublicIp
    localNetworkAddressSpace:{
      addressPrefixes:[
        cloud_vnet.properties.addressSpace.addressPrefixes[0]
      ]
    }
  }
}


// Connection from Onp to Cloud
resource connectionOnptoCloud 'Microsoft.Network/connections@2023-04-01' = {
  name: 'fromOnptoCloud'
  location: locationSite1
  properties: {
    enableBgp: false
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    localNetworkGateway2: {
      id: lng_cloud.id
      properties:{}
    }
    egressNatRules: [
      {
        id: onprevpngateway.outputs.egressnatrule
      }
    ]
    ingressNatRules: [
      {
        id: onprevpngateway.outputs.ingressnatrule
      }
    ]
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
    location: locationSite1
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
