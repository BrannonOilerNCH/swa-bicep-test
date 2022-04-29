param location string = resourceGroup().location
param keyVaultName string
param mongoDBAccountName string
param mongoDBName string

/** Static Web App params */
param swaApiLocation string = 'api'
param swaAppLocation string = '/public'
param swaBranch string = 'main'
param swaName string
param swaRepositoryUrl string

/** Values are referenced from KeyVault unless a new value is provided */
@description('Azure Client Id (press enter to use value stored in KeyVault)')
@secure()
param azureClientId string

@description('Azure Client Secret (press enter to use value stored in KeyVault)')
@secure()
param azureClientSecret string

@description('SWA Repository Token (press enter to use value stored in KeyVault)')
@secure()
param swaRepositoryToken string

module keyVaultModule 'key-vault.bicep' = {
  scope: resourceGroup()
  name: 'keyVaultModule'
  params: {
    keyVaultName: keyVaultName
    location: location
  }
}
var keyVaultNameOutput = keyVaultModule.outputs.keyVaultName

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  scope: resourceGroup()
  name: keyVaultName
}

module mongoDBModule 'mongo-db.bicep' = {
  scope: resourceGroup()
  name: 'mongoDBModule'
  params: {
    mongoDBAccountName: mongoDBAccountName
    keyVaultName: keyVaultNameOutput
    location: location
    mongoDBName: mongoDBName
  }
}
var mongoDBAccountConnectionStringSecretName = mongoDBModule.outputs.mongoDBAccountConnectionStringSecretName

/** KeyVault upserts */
module swaAzureClientIdSecret 'key-vault-secret-upsert.bicep' = {
  scope: resourceGroup()
  name: 'swaAzureClientIdSecret'
  params: {
    keyVaultName: keyVaultNameOutput
    secretName: 'swaAzureClientIdSecret'
    currentValue: keyVault.getSecret('swaAzureClientId')
    newValue: azureClientId
  }
}

module swaAzureClientSecretSecret 'key-vault-secret-upsert.bicep' = {
  scope: resourceGroup()
  name: 'swaAzureClientSecretSecret'
  params: {
    keyVaultName: keyVaultNameOutput
    secretName: 'swaAzureClientSecretSecret'
    currentValue: keyVault.getSecret('swaAzureClientSecret')
    newValue: azureClientSecret
  }
}

module swaRepositoryTokenSecret 'key-vault-secret-upsert.bicep' = {
  scope: resourceGroup()
  name: 'swaRepositoryTokenSecret'
  params: {
    keyVaultName: keyVaultNameOutput
    secretName: 'swaRepositoryTokenSecret'
    currentValue: keyVault.getSecret('swaRepositoryToken')
    newValue: swaRepositoryToken
  }
}

var swaAzureClientIdSecretName = swaAzureClientIdSecret.outputs.secretName
var swaAzureClientSecretSecretName = swaAzureClientSecretSecret.outputs.secretName
var swaRepositoryTokenSecretName = swaRepositoryTokenSecret.outputs.secretName

module swaModule 'static-web-app.bicep' = {
  scope: resourceGroup()
  name: 'swaModule'
  params: {
    azureClientId: keyVault.getSecret(swaAzureClientIdSecretName)
    azureClientSecret: keyVault.getSecret(swaAzureClientSecretSecretName)
    location: location
    mongoDBAccountConnectionString: keyVault.getSecret(mongoDBAccountConnectionStringSecretName)
    swaApiLocation: swaApiLocation
    swaAppLocation: swaAppLocation
    swaBranch: swaBranch
    swaName: swaName
    swaRepositoryToken: keyVault.getSecret(swaRepositoryTokenSecretName)
    swaRepositoryUrl: swaRepositoryUrl
  }
}

// module adB2CModule 'ad-b2c.bicep' = {
//   name: 'adB2CModule'
//   params: {
//     adB2CResourceGroupName: 'UNKNOWN'
//     adB2CSubscriptionId: 'UNKNOWN'
//     location: location
//   }
// }
