param location string
param seqFqdn string

param containerAppsEnvironmentId string
param containerAppsEnvironmentDomain string
param imageTag string

@secure()
param registryPassword string

var registryName = 'acrdw5jt22hnrywq'
var registryEndpoint = '${registryName}.azurecr.io'

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'webshopping-agg'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'webshopping-agg'
          image: '${registryEndpoint}/eshop/webshoppingagg:${imageTag}'
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
              name: 'SeqServerUrl'
              value: 'https://${seqFqdn}'
            }
            {
              name: 'BasketUrlHC'
              value: 'http://basket-api.internal.${containerAppsEnvironmentDomain}/hc'
            }
            {
              name: 'CatalogUrlHC'
              value: 'http://catalog-api.internal.${containerAppsEnvironmentDomain}/hc'
            }
            {
              name: 'IdentityUrlHC'
              value: 'https://identity-api.${containerAppsEnvironmentDomain}/hc'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
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
        appId: 'webshoppingagg'
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
      ]
    }
  }
}
