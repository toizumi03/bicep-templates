param afdName string
param afdlocation string
param location string
param sku string
param afdEndpointName string
param enabledState string
param originGroupName string
param privateLinkResourceId string
param logAnalyticsId string
param enablediagnostics bool

resource cdnprofiles 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: afdName
  location: afdlocation
  sku: {
    name: sku
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource afdendpoints 'Microsoft.Cdn/profiles/afdEndpoints@2023-07-01-preview' = {
  name: afdEndpointName
  location: location
  parent: cdnprofiles
  properties: {
    enabledState: enabledState
  }
}

resource originGroups 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' = {
  name: originGroupName
  parent: cdnprofiles
  properties: {
    healthProbeSettings: {
      probeIntervalInSeconds: 100
      probePath: '/'
      probeProtocol: 'Http'
      probeRequestType: 'HEAD'
    }
    loadBalancingSettings: {
      additionalLatencyInMilliseconds: 4
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    sessionAffinityState: 'Disabled'
  }
}

resource routes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-07-01-preview' = {
  name: 'route1'
  parent: afdendpoints
  properties: {
    customDomains: []
    originGroup: {
      id: originGroups.id
    }
    ruleSets: []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
  dependsOn: [
    origin
    originGroups
  ]
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-07-01-preview' = {
  name: 'origin1'
  parent: originGroups
  properties: {
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
    hostName: '10.0.0.100'
    httpPort: 80
    httpsPort: 443
    originHostHeader: '10.0.0.100'
    priority: 1
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkResourceId
      }
      privateLinkLocation: location
      requestMessage: 'Private link to ILB from Front Door'
    }
    weight: 1000
  }
}

/* ****************************** enable diagnostic logs ****************************** */

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablediagnostics){
  name: '${afdName}-logs'
  scope:cdnprofiles
  properties: {
    workspaceId: logAnalyticsId
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}
