param location string
param uniqueSeed string
param loadTestName string = 'eShopLoadTests'

resource loadTest 'Microsoft.LoadTestService/loadTests@2021-12-01-preview' = {
  name: loadTestName
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    description: 'eShop front page load test'
  }
}
