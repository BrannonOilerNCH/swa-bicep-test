param keyVaultName string
param location string

var tenantId = subscription().tenantId

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
  }
}

output keyVaultName string = keyVault.name
