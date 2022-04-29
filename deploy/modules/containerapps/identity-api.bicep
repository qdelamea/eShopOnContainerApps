param location string
param seqFqdn string

param containerAppsEnvironmentId string
param containerAppsEnvironmentDomain string
param imageTag string

@secure()
param registryPassword string

@secure()
param identityDbConnectionString string

var registryName = 'acrdw5jt22hnrywq'
var registryEndpoint = '${registryName}.azurecr.io'

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'identity-api'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'identity-api'
          image: '${registryEndpoint}/eshop/identity-api:${imageTag}'
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
              name: 'BlazorClientUrlExternal'
              value: 'https://blazor-client.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'IssuerUrl'
              value: 'https://identity-api.${containerAppsEnvironmentDomain}'
            }
            {
              name: 'ConnectionStrings__IdentityDB'
              secretRef: 'identitydb-connection-string'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
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
        {
          name: 'identitydb-connection-string'
          value: identityDbConnectionString
        }
      ]
    }
  }
}
