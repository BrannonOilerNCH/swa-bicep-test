param adB2CSubscriptionId string
param adB2CResourceGroupName string
param location string

/** TODO: Not sure if needed */
/** Ensure {appRegistrationDeploymentScript} will run every time */
param forceUpdateTag string = utcNow('u')

/** TODO: Add to parameters.json */
param activeDirectoryB2CName string = 'NCHAccess.onmicrosoft.com'

resource activeDirectoryB2C 'Microsoft.AzureActiveDirectory/b2cDirectories@2021-04-01' existing = {
  /** TODO: Add to parameters.json */
  name: activeDirectoryB2CName
  scope: resourceGroup(adB2CSubscriptionId, adB2CResourceGroupName)
}

/** Create app registration using deployment scripts 
  *   https://stackoverflow.com/questions/69120936/how-do-i-use-bicep-or-arm-to-create-an-ad-app-registration-and-roles
  *   https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template
  */
resource appRegistrationDeploymentScript 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: 'appRegistrationDeploymentScript'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('app-reg-automation', 'Microsoft.ManagedIdentity/userAssignedIdentities', 'AppRegCreator')}': {}
    }
  }
  properties: {
    azPowerShellVersion: '5.0'
    arguments: '-resourceName "${activeDirectoryB2CName}"'
    scriptContent: '''
        param([string] $resourceName)
        $token = (Get-AzAccessToken -ResourceUrl https://graph.microsoft.com).Token
        $headers = @{'Content-Type' = 'application/json'; 'Authorization' = 'Bearer ' + $token}
  
        $template = @{
          displayName = $resourceName
          requiredResourceAccess = @(
            @{
              resourceAppId = "00000003-0000-0000-c000-000000000000"
              resourceAccess = @(
                @{
                  id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                  type = "Scope"
                }
              )
            }
          )
          signInAudience = "AzureADMyOrg"
        }
        
        // Upsert App registration
        $app = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/applications?filter=displayName eq '$($resourceName)'").value
        $principal = @{}
        if ($app) {
          $ignore = Invoke-RestMethod -Method Patch -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)" -Body ($template | ConvertTo-Json -Depth 10)
          $principal = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/servicePrincipals?filter=appId eq '$($app.appId)'").value
        } else {
          $app = (Invoke-RestMethod -Method Post -Headers $headers -Uri "https://graph.microsoft.com/beta/applications" -Body ($template | ConvertTo-Json -Depth 10))
          $principal = Invoke-RestMethod -Method POST -Headers $headers -Uri  "https://graph.microsoft.com/beta/servicePrincipals" -Body (@{ "appId" = $app.appId } | ConvertTo-Json)
        }
        
        // Creating client secret
        $app = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)")
        
        foreach ($password in $app.passwordCredentials) {
          Write-Host "Deleting secret with id: $($password.keyId)"
          $body = @{
            "keyId" = $password.keyId
          }
          $ignore = Invoke-RestMethod -Method POST -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)/removePassword" -Body ($body | ConvertTo-Json)
        }
        
        $body = @{
          "passwordCredential" = @{
            "displayName"= "Client Secret"
          }
        }
        $secret = (Invoke-RestMethod -Method POST -Headers $headers -Uri  "https://graph.microsoft.com/beta/applications/$($app.id)/addPassword" -Body ($body | ConvertTo-Json)).secretText
        
        $DeploymentScriptOutputs = @{}
        $DeploymentScriptOutputs['objectId'] = $app.id
        $DeploymentScriptOutputs['clientId'] = $app.appId
        $DeploymentScriptOutputs['clientSecret'] = $secret
        $DeploymentScriptOutputs['principalId'] = $principal.id
  
      // create app role
      $app = (Invoke-RestMethod -Method Get -Headers $headers -Uri "https://graph.microsoft.com/beta/applications/$($app.id)")
      $body1 = @{
        Id = [Guid]::NewGuid().ToString()
        IsEnabled = true
        AllowedMemberTypes =@("application")
        Description = "My Role Description.."
        DisplayName = "My Custom Role"
        Value = "MyCustomRole"
      }
      $createapprole= Invoke-RestMethod -Method POST -Headers $headers -Uri  "https://graph.microsoft.com/beta/applications/$($app.id)/appRoles" -Body ($body1 | ConvertTo-Json)
      '''
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: forceUpdateTag
  }
}
