param location string
param uniqueSeed string
param containerAppsEnvironmentName string = 'containerappenv-${uniqueString(uniqueSeed)}'

var logAnalyticsWorkspaceName = 'logs-${containerAppsEnvironmentName}'
var appInsightsName = 'appins-${containerAppsEnvironmentName}'

param cosmosDbName string
param cosmosCollectionName string
param cosmosUrl string
@secure()
param cosmosKey string

@secure()
param serviceBusConnectionString string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  location: location
  name: containerAppsEnvironmentName
  properties: {
    daprAIInstrumentationKey: reference(appInsights.id, '2020-02-02').InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }

  resource daprStateStoreComponent 'daprComponents@2022-01-01-preview' = {
    name: 'eshop-statestore'
    properties: {
      componentType: 'state.azure.cosmosdb'
      version: 'v1'
      ignoreErrors: false
      metadata: [
        {
          name: 'url'
          value: cosmosUrl
        }
        {
          name: 'database'
          value: cosmosDbName
        }
        {
          name: 'collection'
          value: cosmosCollectionName
        }
        {
          name: 'actorStateStore'
          value: 'true'
        }
      ]
      scopes: [
        'basket-api'
        'ordering-api'
      ]
      secrets: [
        {
          name: 'masterKey'
          value: cosmosKey
        }
      ]
    }
  }
  
  resource daprPubSubComponent 'daprComponents@2022-01-01-preview' = {
    name: 'pubsub'
    properties: {
      componentType: 'pubsub.azure.servicebus'
      version: 'v1'
      ignoreErrors: false
      scopes: [
        'basket-api'
        'catalog-api'
        'ordering-api'
        'payment-api'
      ]
      secrets: [
        {
          name: 'connectionString'
          value: serviceBusConnectionString
        }
      ]
    }
  } 
}

output containerAppsEnvironmentId string = containerAppsEnvironment.id
output containerAppsEnvironmentDomain string = containerAppsEnvironment.properties.defaultDomain
