param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

@allowed([
  true
  false
])
param createLoganalytics bool
@allowed([
  true
  false
])
param createAisearch bool
@allowed([
  true
  false
])
param createCosmosdb bool
@allowed([
  true
  false
])
param createEventhubs bool
@allowed([
  true
  false
])
param createKeyvault bool
@allowed([
  true
  false
])
param createSqldb bool
@allowed([
  true
  false
])
param createStoragaccount bool

/* ****************************** Network Security Perimeter ****************************** */

resource perimeter 'Microsoft.Network/networkSecurityPerimeters@2023-08-01-preview' = {
  name: 'test-perimeter'
  location: locationSite1
  properties: {}
  dependsOn: [
    logAnalytics
    search
    cosmosdbaccount
    eventHub
    keyvault
    sqlServer
    storageAccount
  ]
}

/*
resource linkreference 'Microsoft.Network/networkSecurityPerimeters/linkReferences@2023-08-01-preview' = {
  parent: perimeter
  name: 'linkreference1'
}

resource links 'Microsoft.Network/networkSecurityPerimeters/links@2023-08-01-preview' = {
  parent: perimeter
  name: 'link1'
  properties: {
    autoApprovedRemotePerimeterResourceId: 'string'
    description: 'string'
    localInboundProfiles: [
      'string'
    ]
    remoteInboundProfiles: [
      'string'
    ]
  }
}
*/

resource profiles 'Microsoft.Network/networkSecurityPerimeters/profiles@2023-08-01-preview' = {
  parent: perimeter
  location: locationSite1
  name: 'defaultProfile'
  properties: {}
}
resource accuessrules 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2023-08-01-preview' = {
  parent: profiles
  location: locationSite1
  name: 'rule1'
  properties: {
    addressPrefixes: [
      '8.8.8.8/32'
    ]
    direction: 'Inbound'
    emailAddresses: [
    ]
    fullyQualifiedDomainNames: [
    ]
    phoneNumbers: [
    ]
    serviceTags: [
    ]
  }
}

resource resourceAssociations1 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createLoganalytics) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource1'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: logAnalytics.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations2 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createAisearch) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource2'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: search.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations3 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createCosmosdb) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource3'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: cosmosdbaccount.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations4 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createEventhubs) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource4'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: eventHub.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations5 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createKeyvault) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource5'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: keyvault.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations6 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createSqldb) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource6'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: sqlServer.id
    }
    profile: {
      id: profiles.id
    }
  }
}

resource resourceAssociations7 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-08-01-preview' = if(createStoragaccount) {
  parent: perimeter
  location: locationSite1
  name: 'associatedResource7'
  properties: {
    accessMode: 'Learning'
    privateLinkResource: {
      id: storageAccount.id
    }
    profile: {
      id: profiles.id
    }
  }
}

/* ****************************** LogAnalytics Workspace ****************************** */
var logAnalyticsWorkspace  = 'logana-${uniqueString(resourceGroup().id)}la'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01'= if(createLoganalytics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}

/* ****************************** Azure AI Search	 ****************************** */
var searchServiceName = 'search-${uniqueString(resourceGroup().id)}'

resource search 'Microsoft.Search/searchServices@2020-08-01' = if(createAisearch) {
  name: searchServiceName
  location: locationSite1
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

/* ****************************** Cosmos DB	 ****************************** */
var accountName = 'cosmos-${uniqueString(resourceGroup().id)}'

@description('The name for the SQL API database')
var databaseName = 'cosmos-${uniqueString(resourceGroup().id)}'

@description('The name for the SQL API container')
var containerName = 'cosmos-${uniqueString(resourceGroup().id)}'

resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = if(createCosmosdb) {
  name: toLower(accountName)
  location: locationSite1
  properties: {
    enableFreeTier: false
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: locationSite1
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' =  if(createCosmosdb) {
  parent: cosmosdbaccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 1000
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' =  if(createCosmosdb) {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
    }
  }
}


/* ****************************** Event Hubs ****************************** */
var projectName = 'project-${uniqueString(resourceGroup().id)}'
var eventHubNamespaceName = '${projectName}ns'
var eventHubName = projectName

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = if(createEventhubs) {
  name: eventHubNamespaceName
  location: locationSite1
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = if(createEventhubs) {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
}

/* ****************************** Key Vault	 ****************************** */

var vaultName = 'keyvalut-${uniqueString(resourceGroup().id)}'
var keyName = 'keyname-${uniqueString(resourceGroup().id)}'
var keyType = 'RSA'
var keyOps  = []
var keySize = 2048
var curveName = 'P-256'

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = if(createKeyvault) {
  name: vaultName
  location: locationSite1
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2023-07-01' = if(createKeyvault){
  parent: keyvault
  name: keyName
  properties: {
    kty: keyType
    keyOps: keyOps
    keySize: keySize
    curveName: curveName
  }
}


/* ****************************** SQL DB ****************************** */
var serverName = uniqueString('sql', resourceGroup().id)
var sqlDBName = 'SampleDB'

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = if(createSqldb) {
  name: serverName
  location: locationSite1
  properties: {
    administratorLogin: vmAdminUsername
    administratorLoginPassword: vmAdminPassword
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2023-05-01-preview' = if(createSqldb){
  parent: sqlServer
  name: sqlDBName
  location: locationSite1
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

/* ****************************** Storage ****************************** */
var storageAccountName = 'storage${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if(createStoragaccount) {
  name: storageAccountName
  location: locationSite1
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}
