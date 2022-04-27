param location string

param containerAppsEnvironmentId string
param containerAppsEnvironmentDomain string

resource containerApp 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'webshopping-gw'
  location: location
  properties: {
    kubeEnvironmentId: containerAppsEnvironmentId
    template: {
      containers: [
        {
          name: 'webshopping-gw'
          image: 'eshopdapr/webshoppingapigw:latest'
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
        maxReplicas: 1
      }
      dapr: {
        enabled: true
        appId: 'webshoppingapigw'
        appPort: 80
      }
    }
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: true
      }
    }
  }
}
