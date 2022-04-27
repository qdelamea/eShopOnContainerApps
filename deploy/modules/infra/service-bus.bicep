param location string
param uniqueSeed string
param keyVaultName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: 'sb-${uniqueString(uniqueSeed)}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource serviceBusConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${keyVaultName}/serviceBusConnectionString'
  properties: {
    value: 'Endpoint=sb://${serviceBus.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryKey}'
  }
}
