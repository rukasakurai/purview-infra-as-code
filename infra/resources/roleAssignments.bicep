@description('Principal ID to assign roles to')
param principalId string

// Built-in Azure RBAC role definitions
// Owner role for the resource group
var ownerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

// Assign Owner role to the principal for the resource group
resource ownerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, ownerRoleDefinitionId)
  properties: {
    roleDefinitionId: ownerRoleDefinitionId
    principalId: principalId
    principalType: 'User'
  }
}

output roleAssignmentId string = ownerRoleAssignment.id
