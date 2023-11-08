param networkManagerName string
param networkGroupName string
param staticMemberName string
param resourceId string

resource networkManager 'Microsoft.Network/networkManagers@2023-04-01' existing = {
  name: networkManagerName

  resource networkGroup 'networkGroups@2023-04-01' existing = {
    name: networkGroupName
  }
}
resource staticMember 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2023-04-01' = {
  name: staticMemberName
  parent: networkManager::networkGroup
  properties: {
    resourceId: resourceId
  }
}
