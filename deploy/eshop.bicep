param location string = resourceGroup().location
param uniqueSeed string = uniqueString(resourceGroup().id)
param keyVaultName string = 'eShopVaulthqyobk5cu5ahg'

param basketApiImageTag string
param blazorClientImageTag string
param catalogApiImageTag string
param identityApiImageTag string
param orderingApiImageTag string
param paymentApiImageTag string
param webshoppingAggImageTag string
param webshoppingGWImageTag string

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

////////////////////////////////////////////////////////////////////////////////
// Infrastructure
////////////////////////////////////////////////////////////////////////////////

module containerAppsEnvironment 'modules/infra/container-apps-env.bicep' = {
  name: '${deployment().name}-infra-container-app-env'
  params: {
    location: location
    uniqueSeed: uniqueSeed
    cosmosDbName: cosmos.outputs.cosmosDbName
    cosmosCollectionName: cosmos.outputs.cosmosCollectionName
    cosmosUrl: cosmos.outputs.cosmosUrl
    cosmosKey: keyVault.getSecret('cosmosKey')
    serviceBusConnectionString: keyVault.getSecret('serviceBusConnectionString')
  }
}

module cosmos 'modules/infra/cosmos-db.bicep' = {
  name: '${deployment().name}-infra-cosmos-db'
  params: {
    location: location
    uniqueSeed: uniqueSeed
    keyVaultName: keyVaultName
  }
}

module serviceBus 'modules/infra/service-bus.bicep' = {
  name: '${deployment().name}-infra-service-bus'
  params: {
    location: location
    uniqueSeed: uniqueSeed
    keyVaultName: keyVaultName
  }
}

module sqlServer 'modules/infra/sql-server.bicep' = {
  name: '${deployment().name}-infra-sql-server'
  params: {
    location: location
    uniqueSeed: uniqueSeed
    sqlAdministratorLoginPassword: keyVault.getSecret('sqlAdministratorLoginPassword')
    keyVaultName: keyVaultName
  }
}

////////////////////////////////////////////////////////////////////////////////
// Container apps
////////////////////////////////////////////////////////////////////////////////

module basketApi 'modules/containerapps/basket-api.bicep' = {
  name: '${deployment().name}-app-basket-api'
  dependsOn: [
    containerAppsEnvironment
    cosmos
    seq
    serviceBus
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    imageTag:basketApiImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module blazorClient 'modules/containerapps/blazor-client.bicep' = {
  name: '${deployment().name}-app-blazor-client'
  dependsOn: [
    containerAppsEnvironment
    seq
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    imageTag: blazorClientImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module catalogApi 'modules/containerapps/catalog-api.bicep' = {
  name: '${deployment().name}-app-catalog-api'
  dependsOn: [
    containerAppsEnvironment
    seq
    serviceBus
    sqlServer
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    catalogDbConnectionString: keyVault.getSecret('catalogDbConnectionString')
    imageTag: catalogApiImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module identityApi 'modules/containerapps/identity-api.bicep' = {
  name: '${deployment().name}-app-identity-api'
  dependsOn: [
    containerAppsEnvironment
    seq
    sqlServer
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    imageTag: identityApiImageTag
    identityDbConnectionString: keyVault.getSecret('identityDbConnectionString')
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module orderingApi 'modules/containerapps/ordering-api.bicep' = {
  name: '${deployment().name}-app-ordering-api'
  dependsOn: [
    containerAppsEnvironment
    cosmos
    seq
    serviceBus
    sqlServer
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    imageTag: orderingApiImageTag
    orderingDbConnectionString: keyVault.getSecret('orderingDbConnectionString')
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module paymentApi 'modules/containerapps/payment-api.bicep' = {
  name: '${deployment().name}-app-payment-api'
  dependsOn: [
    containerAppsEnvironment
    seq
    serviceBus
  ]
  params: {
    location: location
    seqFqdn: seq.outputs.fqdn
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    imageTag: paymentApiImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module seq 'modules/containerapps/seq.bicep' = {
  name: '${deployment().name}-app-seq'
  dependsOn: [
    containerAppsEnvironment
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
  }
}

module webshoppingAgg 'modules/containerapps/webshopping-agg.bicep' = {
  name: '${deployment().name}-app-webshopping-agg'
  dependsOn: [
    containerAppsEnvironment
    seq
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    seqFqdn: seq.outputs.fqdn
    imageTag: webshoppingAggImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module webshoppingGW 'modules/containerapps/webshopping-gw.bicep' = {
  name: '${deployment().name}-app-webshopping-gw'
  dependsOn: [
    containerAppsEnvironment
    seq
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
    imageTag: webshoppingGWImageTag
    registryPassword: keyVault.getSecret('registrypassword')
  }
}

module webstatus 'modules/containerapps/webstatus.bicep' = {
  name: '${deployment().name}-app-webstatus'
  dependsOn: [
    containerAppsEnvironment
    seq
  ]
  params: {
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    containerAppsEnvironmentDomain: containerAppsEnvironment.outputs.containerAppsEnvironmentDomain
  }
}
