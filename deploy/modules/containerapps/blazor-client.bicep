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
  name: 'blazor-client'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'blazor-client'
          image: '${registryEndpoint}/eshop/blazor-client:${imageTag}'
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
              name: 'ApiGatewayUrlExternal'
              value: 'https://webshopping-gw.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'IdentityUrlExternal'
              value: 'https://identity-api.${containerAppsEnvironmentDomain}'
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
      ingress: {
        external: true
        targetPort: 80
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
