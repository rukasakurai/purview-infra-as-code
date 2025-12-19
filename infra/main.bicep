targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the Purview account. Must be globally unique.')
param purviewAccountName string = ''

@description('Id of the principal to assign as owner of the resource group')
param principalId string = ''

// Generate a unique suffix for resource names
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Purview Account Module
module purview './resources/purview.bicep' = {
  name: 'purview-account'
  scope: rg
  params: {
    name: !empty(purviewAccountName) ? purviewAccountName : 'purview-${resourceToken}'
    location: location
    tags: tags
  }
}

// Role assignments module (if principalId is provided)
module roleAssignments './resources/roleAssignments.bicep' = if (!empty(principalId)) {
  name: 'role-assignments'
  scope: rg
  params: {
    principalId: principalId
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output PURVIEW_ACCOUNT_NAME string = purview.outputs.name
output PURVIEW_ENDPOINT string = purview.outputs.endpoint
output PURVIEW_MANAGED_RESOURCE_GROUP_NAME string = purview.outputs.managedResourceGroupName
