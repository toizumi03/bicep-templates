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
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'nva-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
          routeTable: { id: rt_nvasubnet.id }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'RouteServerSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}


module expressRouteGateway1 '../modules/ergw.bicep' = {
  name: 'cloud-ergw'
  params: {
    location: locationSite1
    gatewayName: 'cloud-ergw'
    sku: 'Standard'
    vnetName: cloud_vnet.name
  }
}

var routeservername = 'RouteServer'
module routeserver '../modules/routeserver.bicep' = {
  name: routeservername
  params: {
    location: locationSite1
    routeserverName: routeservername
    vnetName: cloud_vnet.name
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
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet.properties.subnets[1].id
    enableIPForwarding: true
    customData: loadFileAsBase64('cloud-init.yml')
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

/* ****************************** cloud-Vnet2 ****************************** */

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
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.10.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
    ]
  }
}


module expressRouteGateway2 '../modules/ergw.bicep' = {
  name: 'cloud-ergw2'
  params: {
    location: locationSite1
    gatewayName: 'cloud-ergw2'
    sku: 'Standard'
    vnetName: cloud_vnet2.name
  }
}

module cloudvm2 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-ubuntuvm2'
  params: {
    vmName: 'cloud-ubuntuvm2'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet2.properties.subnets[0].id
  }
}

/* ****************************** cloud-Vnet3 ****************************** */

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
        name: 'subnet-1'
        properties: {
          addressPrefix: '10.20.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.20.1.0/24'
        }
      }
    ]
  }
}


module expressRouteGateway3 '../modules/ergw.bicep' = {
  name: 'cloud-ergw3'
  params: {
    location: locationSite1
    gatewayName: 'cloud-ergw3'
    sku: 'Standard'
    vnetName: cloud_vnet3.name
  }
}

module cloudvm3 '../modules/ubuntu20.04.bicep' = {
  name: 'cloud-ubuntuvm3'
  params: {
    vmName: 'cloud-ubuntuvm3'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    usePublicIP: true
    subnetId: cloud_vnet3.properties.subnets[0].id
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
