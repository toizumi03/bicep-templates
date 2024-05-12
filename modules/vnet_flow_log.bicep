param location string
param vnetflowlogName string 
param workspaceRegin string
param workspaceResourceId string
param storageID string
param targetResourceId string

resource VnetFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  name: 'NetworkWatcher_${location}/${vnetflowlogName}'
  location: location
  properties: {
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        trafficAnalyticsInterval: 10
        workspaceRegion: workspaceRegin
        workspaceResourceId: workspaceResourceId
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: 0
      enabled: false
    }
    storageId: storageID
    targetResourceId: targetResourceId
  }
}
