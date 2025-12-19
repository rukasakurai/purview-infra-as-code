@description('Principal ID to assign roles to')
param principalId string

@description('Type of principal (User, Group, or ServicePrincipal)')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'User'

// Built-in Azure RBAC role definitions
// Reader role for the resource group
var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

// Assign Reader role to the principal for the resource group
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, readerRoleDefinitionId)
  properties: {
    roleDefinitionId: readerRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = readerRoleAssignment.id
