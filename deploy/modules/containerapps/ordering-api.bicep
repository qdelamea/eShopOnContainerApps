param location string
param seqFqdn string

param containerAppsEnvironmentId string
param containerAppsEnvironmentDomain string
param imageTag string

@secure()
param registryPassword string

@secure()
param orderingDbConnectionString string

var registryName = 'acrdw5jt22hnrywq'
var registryEndpoint = '${registryName}.azurecr.io'

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'ordering-api'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'ordering-api'
          image: '${registryEndpoint}/eshop/ordering-api:${imageTag}'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://0.0.0.0:80'
            }
            {
              name: 'IdentityUrl'
              value: 'https://identity-api.${containerAppsEnvironmentDomain}'
            }  
            {
              name: 'IdentityUrlExternal'
              value: 'https://identity-api.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'ConnectionStrings__OrderingDB'
              secretRef: 'orderingdb-connection-string'
            }
            {
              name: 'RetryMigrations'
              value: 'true'
            }
            {
              name: 'SeqServerUrl'
              value: 'https://${seqFqdn}'
            }
          ]      
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 5
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                  concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
    configuration: {
      activeRevisionsMode: 'single'
      dapr: {
        enabled: true
        appId: 'ordering-api'
        appPort: 80
      }
      ingress: {
        external: false
        targetPort: 80
        allowInsecure: true
      }
      registries: [
        {
          server: registryEndpoint
          username: registryName
          passwordSecretRef: 'registrypassword'
        }
      ]
      secrets: [
        {
          name: 'registrypassword'
          value: registryPassword
        }
        {
          name: 'orderingdb-connection-string'
          value: orderingDbConnectionString
        }
      ]
    }
  }
}
