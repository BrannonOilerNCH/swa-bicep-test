@secure()
param azureClientId string
@secure()
param azureClientSecret string
@secure()
param mongoDBAccountConnectionString string
@secure()
param swaRepositoryToken string

param location string
param swaName string
param swaRepositoryUrl string
param swaBranch string
param swaAppLocation string
param swaApiLocation string

resource staticWebApp 'Microsoft.Web/staticSites@2021-03-01' = {
  name: swaName
  location: location
  properties: {
    repositoryUrl: swaRepositoryUrl
    branch: swaBranch
    repositoryToken: swaRepositoryToken
    buildProperties: {
      appLocation: swaAppLocation
      apiLocation: swaApiLocation
    }
  }
  sku: {
    tier: 'Free'
    name: 'Free'
  }
}

resource staticWebAppConfig 'Microsoft.Web/staticSites/config@2021-03-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    'CONNECTION_STRING': mongoDBAccountConnectionString
    'AZURE_CLIENT_ID': azureClientId
    'AZURE_CLIENT_SECRET': azureClientSecret
  }
}
