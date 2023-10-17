param flowLogName string
param location string
param flowlogbool bool
param analiticsbool bool
param analyticsInterval int
param workspaceresourceId string
param workspaceId string
param workspaceRegion string
param existingNSG string
param storageAccount string
param retentionDays int
param flowLogsVersion int

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-04-01' = {
  name: 'NetworkWatcher_${location}/${flowLogName}'
  location: location
  properties: {
    enabled: flowlogbool
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: analiticsbool
        trafficAnalyticsInterval: analyticsInterval
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceresourceId
      }
    }
    retentionPolicy: {
      days: retentionDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: flowLogsVersion
    }
    targetResourceId: existingNSG
    storageId: storageAccount
  }
}
