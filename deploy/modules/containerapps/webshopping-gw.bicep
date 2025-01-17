param location string

param containerAppsEnvironmentId string
param containerAppsEnvironmentDomain string
param imageTag string

@secure()
param registryPassword string

var registryName = 'acrdw5jt22hnrywq'
var registryEndpoint = '${registryName}.azurecr.io'

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'webshopping-gw'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'webshopping-gw'
          image: '${registryEndpoint}/eshop/webshoppingapigw:${imageTag}'
          env: [
            {
              name: 'ENVOY_CATALOG_API_ADDRESS'
              value: 'catalog-api.internal.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'ENVOY_CATALOG_API_PORT'
              value: '80'
            }
            {
              name: 'ENVOY_ORDERING_API_ADDRESS'
              value: 'ordering-api.internal.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'ENVOY_ORDERING_API_PORT'
              value: '80'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
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
        appId: 'webshoppingapigw'
        appPort: 80
      }
      ingress: {
        external: true
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
