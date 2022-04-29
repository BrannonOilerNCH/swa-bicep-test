param mongoDBAccountName string
param keyVaultName string
param location string
param mongoDBName string

/** MongoDB */
resource mongoDBAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: mongoDBAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    apiProperties: {
      serverVersion: '4.0'
    }
    capabilities: [
      {
        name: 'EnableMongo'
      }
      {
        name: 'DisableRateLimitingResponses'
      }
      {
        name: 'EnableServerless'
      }
    ]
  }
}
var mongoDBAccountConnectionString = first(mongoDBAccount.listConnectionStrings().connectionStrings).connectionString

resource mongoDB 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2021-10-15' = {
  name: mongoDBName
  parent: mongoDBAccount
  properties: {
    resource: {
      id: mongoDBName
    }
  }
}

/** (Existing) Key Vault */
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource mongoDBAccountConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: 'mongoDBAccountConnectionString'
  parent: keyVault
  properties: {
    value: mongoDBAccountConnectionString
  }
}

output mongoDBAccountConnectionStringSecretName string = mongoDBAccountConnectionStringSecret.name
