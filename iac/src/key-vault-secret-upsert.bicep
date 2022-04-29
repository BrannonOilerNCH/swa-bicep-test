/** Updates {secret} in {keyVault} with new non-null and non-empty value
  * when supplied through CLI, for reference later in the script.
  * 
  * Note: must use {secretName} later in script or new value may not be used.
  */

param keyVaultName string
param secretName string

@secure()
param currentValue string
param newValue string

var value = (newValue != null && newValue == '') ? newValue : currentValue

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: secretName
  parent: keyVault
  properties: {
    value: value
  }
}

output secretName string = secret.name
