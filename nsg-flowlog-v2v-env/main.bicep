param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** NSG flow Setting ****************************** */

var storageAccountName = 'flowlogs${uniqueString(resourceGroup().id)}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: locationSite1
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'trafficAnalyticsWorkspace'
  location: locationSite1
}

module flowlog1 '../modules/nsgflowlog.bicep' = {
  name: 'flowlog1'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    flowLogName: 'flowlog1'
    flowlogbool: true
    analiticsbool: true
    analyticsInterval: 10
    workspaceId: logAnalyticsWorkspace.properties.customerId
    workspaceRegion: locationSite1
    workspaceresourceId: logAnalyticsWorkspace.id
    existingNSG: defaultNSGSite1.outputs.nsgId
    storageAccount: storageAccount.id
    retentionDays: 0
    flowLogsVersion: 2
  }
}

module flowlog2 '../modules/nsgflowlog.bicep' = {
  name: 'flowlog2'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    flowLogName: 'flowlog2'
    flowlogbool: true
    analiticsbool: true
    analyticsInterval: 10
    workspaceId: logAnalyticsWorkspace.properties.customerId
    workspaceRegion: locationSite1
    workspaceresourceId: logAnalyticsWorkspace.id
    existingNSG: defaultNSGSite2.outputs.nsgId
    storageAccount: storageAccount.id
    retentionDays: 0
    flowLogsVersion: 2
  }
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
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

resource cloud_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: cloud_vnet1
  name: 'peer1'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet2.id
    }
    allowVirtualNetworkAccess: true
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
    enableNetWatchExtention: true
    nicnsg: defaultNSGSite1.outputs.nsgId
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

resource cloud_vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet2'
  location: locationSite1
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
    ]
  }
}

resource onpre_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: cloud_vnet2
  name: 'peer2'
  properties: {
    remoteVirtualNetwork: {
      id: cloud_vnet1.id
    }
    allowVirtualNetworkAccess: true
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
    enableNetWatchExtention: true
    nicnsg: defaultNSGSite2.outputs.nsgId
  }
}
