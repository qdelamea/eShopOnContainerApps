param location string
param uniqueSeed string
param cosmosAccountName string = 'cosmos-${uniqueString(uniqueSeed)}'
param cosmosDbName string = 'eShop'
param keyVaultName string

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-04-15' = {
  parent: cosmosAccount
  name: cosmosDbName
  properties: {
    resource: {
      id: cosmosDbName
    }
  }
}

resource cosmosCollection 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-04-15' = {
  parent: cosmosDb
  name: 'state'
  properties: {
    resource: {
      id: 'state'
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource cosmosKey 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${keyVaultName}/cosmosKey'
  properties: {
    value: cosmosAccount.listKeys().primaryMasterKey
  }
}

output cosmosAccountName string = cosmosAccount.name
output cosmosDbName string = cosmosDbName
output cosmosUrl string = cosmosAccount.properties.documentEndpoint
output cosmosCollectionName string = cosmosCollection.name
