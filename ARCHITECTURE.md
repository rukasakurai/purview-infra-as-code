# Architecture Overview

This document explains the architectural decisions and design patterns used in this Purview Infrastructure as Code project.

## Design Principles

### 1. Infrastructure-Only Approach

This repository treats Microsoft Purview as **pure infrastructure**, similar to how you would provision a virtual network, storage account, or database. This is a deliberate choice:

- **Clear Boundaries**: Separates infrastructure provisioning (DevOps/Platform team) from governance configuration (Data Governance team)
- **Reproducibility**: Anyone can spin up a Purview instance in minutes without manual steps
- **Foundation for Automation**: Provides a base for higher-level automation (PowerShell scripts, CI/CD pipelines)

### 2. Subscription-Scoped Deployment

The main Bicep template uses `targetScope = 'subscription'` because:

- **Resource Group Creation**: Allows the template to create its own resource group
- **Isolation**: Each environment gets a dedicated resource group
- **RBAC Flexibility**: Enables assigning roles at different scopes (subscription, resource group)

### 3. Modular Bicep Structure

```
infra/
├── main.bicep                    # Orchestration layer (subscription scope)
└── resources/
    ├── purview.bicep            # Purview account (resource group scope)
    └── roleAssignments.bicep    # RBAC assignments (resource group scope)
```

Benefits:
- **Reusability**: Resource modules can be used in other projects
- **Maintainability**: Changes to one resource don't affect others
- **Testing**: Each module can be validated independently
- **Readability**: Clear separation of concerns

## Resource Definitions

### Microsoft.Purview/accounts

The Purview account is the core resource. Key configuration choices:

#### System-Assigned Managed Identity

```bicep
identity: {
  type: 'SystemAssigned'
}
```

**Why**: 
- Automatic lifecycle management (identity deleted with account)
- Required for Purview to scan Azure resources
- No need to manage separate service principals
- Built-in integration with Azure RBAC

#### Public Network Access

```bicep
publicNetworkAccess: 'Enabled'
```

**Why**:
- Default configuration for initial provisioning
- Simplest setup for getting started
- Can be changed to 'Disabled' after private endpoints are configured
- Supports the "get started quickly" goal of this project

**Security Note**: For production, consider:
- Setting `publicNetworkAccess: 'Disabled'`
- Adding Azure Private Link/Private Endpoints
- Implementing network policies in a separate module

#### Managed Resource Group

```bicep
managedResourceGroupName: 'managed-rg-${name}'
```

**Why**:
- Purview creates auxiliary resources (storage, event hub) in this group
- Explicit naming avoids Azure-generated random names
- Makes resources easier to identify and audit
- User can customize the name pattern

### Role Assignments

The role assignment module is **optional** (controlled by `if (!empty(principalId))`):

```bicep
module roleAssignments './resources/roleAssignments.bicep' = if (!empty(principalId)) {
  ...
}
```

**Why**:
- **azd Integration**: When using `azd provision`, the authenticated user's principal ID is automatically passed
- **Automation Friendly**: In CI/CD, you might not want to assign roles automatically
- **Flexibility**: Can be omitted for service principal provisioning

The Owner role is assigned to enable:
- Full management of the Purview account
- Configuration of data sources and scans
- Assignment of Purview-specific roles (Data Curator, Data Reader, etc.)

## Parameter Strategy

### Environment Variables vs. Parameters

The template uses a hybrid approach:

**azd Environment Variables** (preferred):
```bash
azd env set AZURE_LOCATION eastus
```
- Set once, used across all azd commands
- Persisted in `.azure/{env}/.env` (git-ignored)
- Natural fit for environment-specific config

**Bicep Parameters** (for advanced scenarios):
```bicep
param purviewAccountName string = ''
```
- Computed defaults (using `uniqueString()`)
- Can be overridden via environment variables
- Validated at deployment time

### Naming Convention

Resources follow Azure naming conventions:

- `rg-{environmentName}`: Resource group (clear prefix, environment-specific)
- `purview-{resourceToken}`: Purview account (globally unique via `uniqueString()`)

The `resourceToken` is generated as:
```bicep
uniqueString(subscription().id, environmentName, location)
```

This ensures:
- **Deterministic**: Same inputs = same name
- **Unique**: Across subscriptions and environments
- **Reproducible**: Redeploying same environment uses same names

## Integration with Azure Developer CLI

### azure.yaml Configuration

```yaml
infra:
  provider: bicep
  path: infra
  module: main
```

- **provider: bicep**: azd uses Bicep (vs. Terraform)
- **path: infra**: Where to find templates
- **module: main**: Entry point is `main.bicep`

### Parameter Mapping

`main.parameters.json` maps azd environment variables to Bicep parameters:

```json
{
  "environmentName": { "value": "${AZURE_ENV_NAME}" },
  "location": { "value": "${AZURE_LOCATION}" },
  "principalId": { "value": "${AZURE_PRINCIPAL_ID}" }
}
```

azd automatically sets:
- `AZURE_ENV_NAME`: From `azd init` or `azd env new`
- `AZURE_LOCATION`: From user selection or default
- `AZURE_PRINCIPAL_ID`: From `azd auth login` (current user)

## Extending This Template

### Adding Network Isolation

To add private endpoints:

1. Create `infra/resources/privateEndpoint.bicep`:
```bicep
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: name
  location: location
  properties: {
    subnet: { id: subnetId }
    privateLinkServiceConnections: [{
      name: name
      properties: {
        privateLinkServiceId: purviewAccountId
        groupIds: ['account']
      }
    }]
  }
}
```

2. Update `main.bicep` to reference the new module
3. Add VNet/subnet parameters

### Adding Multiple Purview Accounts

Use Bicep's loop syntax:

```bicep
var purviewAccounts = [
  { name: 'purview-dev', location: 'eastus' }
  { name: 'purview-prod', location: 'westus' }
]

module purview './resources/purview.bicep' = [for account in purviewAccounts: {
  name: 'purview-${account.name}'
  scope: rg
  params: {
    name: account.name
    location: account.location
    tags: tags
  }
}]
```

### Adding Data Source Connections

Purview data source registration is **not** supported via Bicep/ARM templates. Use:

1. **PowerShell**:
```powershell
Install-Module -Name Az.Purview
New-AzPurviewAzureSqlDatabaseDataSource ...
```

2. **REST API**:
```bash
curl -X PUT "https://{purview-account}.purview.azure.com/scan/datasources/{datasource-name}?api-version=2022-07-01-preview" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{ "kind": "AzureSqlDatabase", ... }'
```

3. **Azure Portal**: For manual/exploratory configuration

## Deployment Lifecycle

### Initial Provisioning

```
azd init → azd provision
   ↓           ↓
 Set up    1. Create resource group
 local     2. Deploy Purview account
 env       3. Configure managed identity
           4. Assign RBAC roles
           5. Output endpoints
```

### Updates

```
azd provision (again)
   ↓
1. Detect changes (Bicep diff)
2. Apply incremental updates
3. Preserve existing data/config
```

**Note**: Certain properties (like account name) are **immutable**. Changing them creates a new resource.

### Deletion

```
azd down
   ↓
1. Delete resource group
2. Delete Purview account
3. Delete managed resources
4. Remove RBAC assignments
```

**Warning**: This is destructive. The managed resource group (with storage/event hub) is also deleted.

## Security Considerations

### Managed Identity vs. Service Principal

**System-Assigned Managed Identity** (used here):
- ✅ Automatic lifecycle management
- ✅ No credential storage/rotation
- ✅ Built into resource
- ❌ Can't be shared across resources

**Service Principal** (not used):
- ✅ Reusable across resources
- ✅ Can have multiple credentials
- ❌ Manual creation/management
- ❌ Requires secret storage

For this use case, managed identity is preferred.

### RBAC Roles

The template assigns **Owner** to the provisioning user. This is intentional for a getting-started setup.

For production, consider:
- **Purview Data Curator**: Can manage the data catalog
- **Purview Data Reader**: Read-only access to catalog
- **Purview Data Source Administrator**: Manage data sources and scans
- **Contributor**: Manage Azure resources (not Purview catalog)

Assign these via the Portal or Azure CLI after provisioning.

### Network Security

Current setup:
- ✅ Public network access enabled (simple)
- ❌ No private endpoints (consider for production)
- ❌ No firewall rules (all IPs allowed)

For production:
1. Add private endpoints
2. Disable public network access
3. Implement network policies
4. Use Azure Firewall or NSGs

## Testing Strategy

Since this is infrastructure-only, testing involves:

### 1. Bicep Validation

```bash
az bicep build --file infra/main.bicep
```

Checks:
- Syntax errors
- Type mismatches
- Invalid property values

### 2. What-If Deployment

```bash
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json \
  --what-if
```

Shows:
- Resources to be created/updated/deleted
- Property changes
- Potential issues

### 3. Deployment to Test Environment

```bash
azd env new test
azd provision
```

Validates:
- End-to-end workflow
- Resource creation
- RBAC assignments
- Outputs

### 4. Cleanup

```bash
azd down --force --purge
```

Ensures:
- Clean deletion
- No orphaned resources
- Ready for next test

## Limitations and Known Issues

### Purview Account Name Uniqueness

**Issue**: Purview account names are globally unique (like storage accounts).

**Impact**: First deployment might fail if name is taken.

**Solution**: The template uses `uniqueString()` to generate unique names. For conflicts, set a custom name:
```bash
azd env set PURVIEW_ACCOUNT_NAME my-unique-name-12345
```

### Managed Resource Group Persistence

**Issue**: The managed resource group isn't automatically deleted with the Purview account in some scenarios.

**Impact**: `azd down` might leave orphaned resources.

**Solution**: Manually delete the managed resource group via Portal or CLI:
```bash
az group delete --name managed-rg-purview-xxx
```

### Limited Purview Configuration

**Issue**: Most Purview configuration (scans, glossary, policies) isn't supported via IaC.

**Impact**: Post-provisioning manual or scripted setup is required.

**Solution**: This is by design. Use PowerShell/REST APIs for configuration automation (see main README).

### Region Availability

**Issue**: Not all Azure regions support Purview.

**Impact**: Deployment fails if unsupported region is chosen.

**Solution**: Check supported regions:
```bash
az provider show --namespace Microsoft.Purview \
  --query "resourceTypes[?resourceType=='accounts'].locations"
```

Common supported regions: eastus, westus, westeurope, northeurope, southeastasia

## Cost Considerations

Running this setup incurs Azure costs:

- **Purview Account**: ~$140/month (base capacity unit)
- **Managed Storage**: ~$2-5/month (small data volume)
- **Event Hub**: ~$10-15/month (standard tier)

**Total**: ~$150-160/month minimum

For cost optimization:
1. Delete environments when not in use (`azd down`)
2. Use a single shared Purview account across projects
3. Monitor costs via Azure Cost Management

## Conclusion

This architecture prioritizes:
- **Simplicity**: Easy to understand and deploy
- **Reproducibility**: Anyone can recreate the setup
- **Best Practices**: Follows Azure and azd conventions
- **Extensibility**: Clear patterns for adding features

It's designed as a **foundation**, not a complete solution. Build upon it based on your specific governance needs.
