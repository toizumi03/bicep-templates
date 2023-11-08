param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}

resource hub_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'hub-vnet'
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
        }
      }
    ]
  }
}

var numberOfspokevnet = 3
resource spoke_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = [for i in range(0, numberOfspokevnet): {
  name: 'spoke-vnet${i}'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${i}.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.${i}.0.0/24'
        }
      }
    ]
  }
}]

module hubvm '../modules/ubuntu20.04.bicep' = {
  name: 'hub-vm'
  params: {
    vmName: 'hub-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: hub_vnet.properties.subnets[0].id
    usePublicIP: true
  }
}

module spokevms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfspokevnet):{
  name: 'spoke-vm${i}'
  params: {
    vmName: 'spokevm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: spoke_vnet[i].properties.subnets[0].id
    usePublicIP: true
  }
  dependsOn: [
    spoke_vnet[i]
  ]
}]

module avnm '../modules/virtualnetworkmanager.bicep' = {
  name: 'VirtualNetworkManager'
  params: {
    virtualNetworkManagerName: 'VirtualNetworkManager'
    location: locationSite1
    networkmanagerscopeaccess: 'Connectivity'
    subscription: ['/subscriptions/${subscription().subscriptionId}']
    managementGroup: []
  }
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
  spoke_vnet[0].id
  spoke_vnet[1].id
  spoke_vnet[2].id
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
  ]
}]

module connectivityconfiguration '../modules/connectivityConfigurationsHub-Spoke.bicep' ={
  name: 'connectivityconfiguration1'
  params: {
    networkManagerName: 'VirtualNetworkManager'
    connectivityConfigName: 'hub-spoke-config'
    networkGroupId: avnmnetworkGroup.outputs.networkGroupId
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'false'
    hubVnetId: hub_vnet.id
    useHubGateway: 'false'
    isGlobal: 'false'
  }
  dependsOn:[
    avnm
    avnmnetworkGroup
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
