@description('Name of the Purview account')
param name string

@description('Location for the Purview account')
param location string

@description('Tags to apply to the Purview account')
param tags object = {}

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Managed resource group name for Purview')
param managedResourceGroupName string = 'managed-rg-${name}'

// Microsoft Purview Account
resource purviewAccount 'Microsoft.Purview/accounts@2021-07-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    managedResourceGroupName: managedResourceGroupName
  }
}

// Outputs
output id string = purviewAccount.id
output name string = purviewAccount.name
output endpoint string = 'https://${purviewAccount.name}.purview.azure.com'
output managedResourceGroupName string = purviewAccount.properties.managedResourceGroupName
output principalId string = purviewAccount.identity.principalId
