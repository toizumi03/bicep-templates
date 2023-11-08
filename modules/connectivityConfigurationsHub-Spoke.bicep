param networkManagerName string
param connectivityConfigName string
param networkGroupId string
param hubVnetId string = ''
param useHubGateway string
param connectivityTopology string
param deleteExistingPeering string
param isGlobal string

resource networkManager 'Microsoft.Network/networkManagers@2023-04-01' existing = {
  name: networkManagerName 
}

resource connectivityconfig 'Microsoft.Network/networkManagers/connectivityConfigurations@2023-04-01' = {
  name: connectivityConfigName
  parent: networkManager
  properties: {
    appliesToGroups: [
      {
        groupConnectivity: 'None'
        isGlobal: isGlobal
        networkGroupId: networkGroupId
        useHubGateway: useHubGateway
      }
    ]
    connectivityTopology: connectivityTopology
    deleteExistingPeering: deleteExistingPeering
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: hubVnetId != '' ? hubVnetId : null
      }
    ]
    isGlobal: isGlobal
  }
}

output connectivityConfigId string = connectivityconfig.id
