param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param deployBastion bool
param deployOnprecloud bool
param locationSite2 string
param enablediagnostics bool

/* ****************************** common-env ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${uniqueString(resourceGroup().id)}vfst'
  location: locationSite1
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

var VnetFlowLoglogAnalyticsWorkspace = 'vf-${uniqueString(resourceGroup().id)}-la'
resource VnetFlowlogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: VnetFlowLoglogAnalyticsWorkspace
  location: locationSite1
}

module hubvnetflowlogs '../modules/vnet_flow_log.bicep' = {
  name: 'hub_vnet_flowlog'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    vnetflowlogName: 'hub_vnet_flowlog'
    workspaceRegin: locationSite1
    workspaceResourceId: VnetFlowlogAnalytics.id
    storageID: storageAccount.id
    targetResourceId: hub_vnet.id
  }
}

module spokevnet1flowlogs '../modules/vnet_flow_log.bicep' = {
  name: 'spoke_vnet1_flowlog'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    vnetflowlogName: 'spoke_vnet1_flowlog'
    workspaceRegin: locationSite1
    workspaceResourceId: VnetFlowlogAnalytics.id
    storageID: storageAccount.id
    targetResourceId: spoke_vnet1.id
  }
}

module spokevnet2flowlogs '../modules/vnet_flow_log.bicep' = {
  name: 'spoke_vnet2_flowlog'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    vnetflowlogName: 'spoke_vnet2_flowlog'
    workspaceRegin: locationSite1
    workspaceResourceId: VnetFlowlogAnalytics.id
    storageID: storageAccount.id
    targetResourceId: spoke_vnet2.id
  }
}

module spokevnet3flowlogs '../modules/vnet_flow_log.bicep' = {
  name: 'spoke_vnet3_flowlog'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: locationSite1
    vnetflowlogName: 'spoke_vnet3_flowlog'
    workspaceRegin: locationSite1
    workspaceResourceId: VnetFlowlogAnalytics.id
    storageID: storageAccount.id
    targetResourceId: spoke_vnet3.id
  }
}

/* ****************************** cloud-hub-vnet ****************************** */

resource hub_vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'cloud-hub-vnet'
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
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

module hubvm '../modules/ubuntu20.04.bicep' = {
  name: 'hub-vm1'
  params: {
    vmName: 'hub-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: hub_vnet.properties.subnets[0].id
    usePublicIP: true
    customData: loadFileAsBase64('install_tcpping.yml')
  }
}

module bastion '../modules/bastion.bicep' = if (deployBastion){
  name: 'AzureBastion'
  params: {
    bastionName: 'AzureBastion'
    location: locationSite1
    bastionsku: 'Standard'
    subnetid: hub_vnet.properties.subnets[2].id
  }
}

module hubvnetvpngw '../modules/vpngw_single.bicep' = if (deployOnprecloud){
  name: 'hub-vnet-vpngw'
  params: {
    location: locationSite1
    gatewayName: 'hubvnet-vpngw'
    vnetName: hub_vnet.name
    enablePrivateIpAddress: false
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

resource conncetionCloudtoOnp 'Microsoft.Network/connections@2023-04-01' = if (deployOnprecloud){
  name: 'fromCloudtoOnp'
  location: locationSite1
  properties: {
    enableBgp: false
    virtualNetworkGateway1: {
      id: hubvnetvpngw.outputs.vpngwId
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

/* ****************************** cloud-hub-vnet / Option Onpre-Cloud ****************************** */

module defaultNSGSite2 '../modules/nsg.bicep' = if (deployOnprecloud){
  name: 'NetworkSecurityGroupSite2'
  params:{
    location: locationSite2
    name: 'nsg-site2'  
  }
}

resource onpre_vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = if (deployOnprecloud){
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
          addressPrefix: '192.168.1.0/16'
          networkSecurityGroup: { id: defaultNSGSite2.outputs.nsgId }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.2.0/16'
        }
      }
    ]
  }
}

var onprevpngwName = 'onpre-vpngw'
module onprevpngateway '../modules/vpngw_single.bicep' = if (deployOnprecloud){
  name: onprevpngwName
  params: {
    location: locationSite2
    gatewayName: onprevpngwName
    vnetName: onpre_vnet.name
    enablePrivateIpAddress: false
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
}

// Connection from Onp to Cloud
resource connectionOnptoCloud 'Microsoft.Network/connections@2023-11-01' = if (deployOnprecloud){
  name: 'fromOnptoCloud'
  location: locationSite2
  properties: {
    enableBgp: false
    virtualNetworkGateway1: {
      id: onprevpngateway.outputs.vpngwId
      properties:{}
    }
    virtualNetworkGateway2: {
      id: hubvnetvpngw.outputs.vpngwId
      properties:{}
    }
    connectionType: 'Vnet2Vnet'
    routingWeight: 0
    sharedKey: 'sharedpass'
  }
}

module onprevm '../modules/ubuntu20.04.bicep' = if (deployOnprecloud){
  name: 'onpre-vm'
  params: {
    vmName: 'onpre-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite2
    usePublicIP: true
    subnetId: onpre_vnet.properties.subnets[0].id
    customData: loadFileAsBase64('install_tcpping.yml')
  }
}

/* ****************************** cloud-spoke-vnet ****************************** */

/* ****************************** cloud-spoke-vnet1 ****************************** */

resource spoke_vnet1 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'cloud-spoke_vnet1'
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

var numberOfspoke1VM = 2
module spoke1vms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfspoke1VM):{
  name: 'spoke1-vm${i}'
  params: {
    vmName: 'spoke1-vm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: spoke_vnet1.properties.subnets[0].id
    usePublicIP: true
    customData: loadFileAsBase64('install_tcpping.yml')
  }
}]

/* ****************************** cloud-spoke-vnet2 ****************************** */

resource spoke_vnet2 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'cloud-spoke_vnet2'
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
    encryption: {
      enabled: true
      enforcement: 'AllowUnencrypted'
    }
  }
}

var numberOfspoke2VM = 2
module speke2vms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfspoke2VM):{
  name: 'spoke2-vm${i}'
  params: {
    vmName: 'spoke2-vm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: spoke_vnet2.properties.subnets[0].id
    usePublicIP: true
    enableAcceleratedNetworking: true
    customData: loadFileAsBase64('install_tcpping.yml')
  }
}]

/* ****************************** cloud-spoke-vnet3 ****************************** */

resource spoke_vnet3 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'cloud-spoke_vnet3'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.30.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.30.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'appgwsubnet'
        properties: {
          addressPrefix: '10.30.1.0/24'
        }
      }
      {
        name: 'backendsubnet'
        properties: {
          addressPrefix: '10.30.2.0/24'
        }
      }
    ]
  }
}

module appgwwafv2 '../modules/applicationgateway.bicep' ={
  name: 'appgw-wafv2'
  params:{
    location: locationSite1
    appGwName: 'appgw-wafv2'
    maxCapacity: 5
    minCapacity: 0
    backendHttpSettings_port: 80
    backendHttpSettings_protocol: 'Http'
    subnet_id: spoke_vnet3.properties.subnets[1].id
    backendVMPrivateIPs:[for i in range(0,numberOfInstances):backendvms[i].outputs.privateIP]
    enablediagnostics: enablediagnostics
    logAnalyticsID: logAnalytics.id
  }
}

var numberOfInstances = 2
module backendvms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfInstances):{
  name: 'backend-vm${i}'
  params: {
    vmName: 'backendvm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: spoke_vnet3.properties.subnets[2].id
    customData: loadFileAsBase64('nginx.yml')
  }
}]

/* ****************************** AVNM Setting and Deployment ****************************** */

module avnm '../modules/virtualnetworkmanager.bicep' = {
  name: 'VirtualNetworkManager'
  params: {
    virtualNetworkManagerName: 'VirtualNetworkManager'
    location: locationSite1
    networkmanagerscopeaccess: 'Connectivity'
    subscription: ['/subscriptions/${subscription().subscriptionId}']
    managementGroup: []
  }
  dependsOn: [
    appgwwafv2
  ]
}

module avnmnetworkGroup '../modules/networkGroups.bicep' ={
  name: 'avnmnetworkGroup'
  params:{
    networkManagerName: 'VirtualNetworkManager'
    networkGroupName: 'Group1'
  }
  dependsOn: [
    avnm
  ]
}

var staticMembers = [
  hub_vnet.id
  spoke_vnet1.id
  spoke_vnet2.id
  spoke_vnet3.id
]

@batchSize(1)
module networkGroup_staticMembers '../modules/static-member.bicep' = [for (staticMember, index) in staticMembers: {
  name: 'NetworkGroup-StaticMembers-${index}'
  params: {
    networkManagerName: 'VirtualNetworkManager'
    networkGroupName: 'Group1'
    staticMemberName: 'staticMember${index}'
    resourceId: staticMembers[index]
  }
  dependsOn:[
    avnm
    avnmnetworkGroup
    appgwwafv2
  ]
}]

var useHubGW = deployOnprecloud ? 'true' : 'false'
module connectivityconfiguration '../modules/connectivityConfigurationsHub-Spoke.bicep' ={
  name: 'connectivityconfiguration1'
  params: {
    networkManagerName: 'VirtualNetworkManager'
    connectivityConfigName: 'hub-spoke-config'
    networkGroupId: avnmnetworkGroup.outputs.networkGroupId
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'false'
    hubVnetId: hub_vnet.id
    useHubGateway: useHubGW
    isGlobal: 'false'
  }
  dependsOn:[
    avnm
    avnmnetworkGroup
    networkGroup_staticMembers
  ]
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'userAssignedIdentity1'
  location: locationSite1
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedIdentity.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

module deploymentScriptConnectivityConfigs '../modules/avnmDeploymentScript.bicep' = {
  name: 'deploymentScript-connectivityconfigs'
  dependsOn: [
    roleAssignment
    connectivityconfiguration
    networkGroup_staticMembers
  ]
  params: {
    location: locationSite1
    userAssignedIdentityId: userAssignedIdentity.id
    configurationIds: connectivityconfiguration.outputs.connectivityConfigId
    configType: 'Connectivity'
    networkManagerName: avnm.name
    deploymentScriptName: 'deploymentScript-connectivityconfigs'
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
