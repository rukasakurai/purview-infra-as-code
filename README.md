# Purview Infrastructure as Code

This repository provides a reproducible, code-only setup for provisioning **Microsoft Purview Data Governance** in Azure using the Azure Developer CLI (azd) and Bicep templates. No Azure Portal interaction is required.

## Overview

This project treats **Purview as infrastructure**, not as an application. It provides a foundation for data governance that can be referenced in discussions about well-governed AI agents and data platforms in Azure.

### Key Principles

- **Infrastructure-Only**: This repository provisions Azure resources only. There is no application code to deploy.
- **No Portal Required**: Everything is automated via code. No manual steps in the Azure Portal are needed.
- **azd-Compatible**: Uses Azure Developer CLI for a streamlined, reproducible provisioning experience.

## Why Azure Developer CLI (azd)?

We use `azd` instead of plain Azure CLI or Bicep CLI for several reasons:

1. **Environment Management**: azd provides built-in environment management, making it easy to provision multiple instances (dev, test, prod) without manual configuration.
2. **Parameter Handling**: Automatically manages environment variables and parameters across commands.
3. **Simplified Workflow**: Single command (`azd provision`) handles authentication, parameter collection, and deployment.
4. **Modern Developer Experience**: azd represents Azure's modern infrastructure provisioning approach, with better defaults and conventions.
5. **Reproducibility**: azd up makes it easy for others to replicate the setup from a clean environment.

## Why azd deploy is NOT Used

This project **intentionally does not use** `azd deploy` because:

1. **Infrastructure-Only Scope**: Microsoft Purview is infrastructure, not an application service that requires deployment.
2. **No Application Code**: There are no containers, web apps, or functions to deploy. The Purview account itself is the deliverable.
3. **Immediate Availability**: Once provisioned via `azd provision`, the Purview account is ready to use. No deployment step is needed.
4. **Clear Separation**: This keeps the infrastructure provisioning concern separate from application deployment concerns.

If you run `azd deploy`, it will exit quickly as there are no services configured—this is intentional and expected.

## What Can Be Automated via IaC

### ✅ Fully Automated

- **Purview Account Creation**: Microsoft.Purview/accounts resource
- **Managed Identity**: System-assigned managed identity for the Purview account
- **Resource Group**: Dedicated resource group for Purview resources
- **Network Settings**: Public network access configuration
- **Role Assignments**: RBAC assignments for users/principals

### ❌ NOT Automated (Requires Portal or API)

The following Purview features require additional configuration after provisioning:

- **Data Source Registration**: Connecting to data sources (Azure SQL, ADLS, etc.)
- **Scanning Policies**: Defining and scheduling scans
- **Classification Rules**: Custom or modified classification rules
- **Business Glossary**: Terms, definitions, and relationships
- **Data Catalog**: Metadata and lineage (populated via scans)
- **Access Policies**: Fine-grained access policies for data sources
- **Private Endpoints**: Complex networking configurations

### Why These Boundaries Exist

Microsoft Purview separates **infrastructure provisioning** (via ARM/Bicep) from **governance configuration** (via Portal, PowerShell, or REST API). This is by design:

1. **Different Audiences**: Infrastructure teams provision accounts; data stewards configure governance.
2. **API Maturity**: Purview's configuration APIs are still evolving. Some features lack IaC support.
3. **Statefulness**: Scanning and cataloging are stateful operations that don't fit the declarative IaC model well.

For governance configuration automation, consider:
- [Purview PowerShell module](https://learn.microsoft.com/en-us/powershell/module/az.purview/)
- [Purview REST APIs](https://learn.microsoft.com/en-us/rest/api/purview/)
- [Azure CLI purview extension](https://learn.microsoft.com/en-us/cli/azure/purview)

## Prerequisites

- **Azure Subscription**: An active Azure subscription
- **Azure CLI**: Version 2.50.0 or higher
- **Azure Developer CLI (azd)**: Version 1.5.0 or higher
  - Install: https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd
- **Permissions**: 
  - Contributor or Owner role on the subscription
  - Ability to create resource groups and role assignments

## Getting Started

### 1. Initialize the Environment

```bash
azd auth login
azd init
```

When prompted:
- **Environment name**: Choose a name (e.g., `dev`, `prod`, `myenv`)
- **Azure subscription**: Select your subscription
- **Azure location**: Choose a region (e.g., `eastus`, `westeurope`)

### 2. Provision the Infrastructure

```bash
azd provision
```

This command will:
1. Create a resource group named `rg-{environmentName}`
2. Provision a Microsoft Purview account with a globally unique name
3. Configure system-assigned managed identity
4. Assign Owner role to your user on the resource group (if authenticated)
5. Output the Purview endpoint and resource details

### 3. Verify the Deployment

After provisioning completes, you can:

```bash
# View outputs
azd env get-values

# Access Purview Governance Portal
# URL will be: https://{purviewAccountName}.purview.azure.com
```

You can now log into the Purview Governance Portal to configure data sources, scans, and policies.

## Project Structure

```
.
├── azure.yaml                          # azd project configuration
├── infra/
│   ├── main.bicep                      # Main Bicep template (subscription scope)
│   ├── main.parameters.json            # Parameter mappings for azd
│   └── resources/
│       ├── purview.bicep               # Purview account resource definition
│       └── roleAssignments.bicep       # RBAC role assignments
└── README.md                           # This file
```

## Configuration

### Environment Variables

azd uses environment variables to parameterize deployments. Key variables:

- `AZURE_ENV_NAME`: Environment name (used in resource naming)
- `AZURE_LOCATION`: Azure region for resources
- `AZURE_PRINCIPAL_ID`: User/service principal ID for role assignment
- `AZURE_SUBSCRIPTION_ID`: Target subscription (set by azd init)

You can override defaults by setting environment variables before running `azd provision`:

```bash
azd env set AZURE_LOCATION westus2
azd provision
```

### Custom Purview Account Name

By default, the Purview account name is generated as `purview-{uniqueString}`. To specify a custom name:

```bash
azd env set PURVIEW_ACCOUNT_NAME my-custom-purview
azd provision
```

**Note**: Purview account names must be globally unique, 3-63 characters, lowercase letters and numbers only.

## Multiple Environments

To create multiple independent Purview instances (e.g., dev and prod):

```bash
# Create dev environment
azd env new dev
azd env set AZURE_LOCATION eastus
azd provision

# Create prod environment
azd env new prod
azd env set AZURE_LOCATION westeurope
azd provision

# Switch between environments
azd env select dev
azd env select prod
```

## Cleanup

To delete all resources:

```bash
azd down
```

This removes:
- The Purview account
- The resource group
- All associated resources

**Warning**: This action is irreversible. Ensure you've backed up any important data or configurations.

## Troubleshooting

### "Purview account name is not available"

Purview account names must be globally unique. Try a different name:

```bash
azd env set PURVIEW_ACCOUNT_NAME another-unique-name
azd provision
```

### "Insufficient permissions"

Ensure you have:
- Contributor or Owner role on the subscription
- `Microsoft.Purview` resource provider registered

Register the provider:

```bash
az provider register --namespace Microsoft.Purview
az provider show --namespace Microsoft.Purview --query "registrationState"
```

### "Location not supported"

Not all Azure regions support Purview. Check supported regions:

```bash
az provider show --namespace Microsoft.Purview \
  --query "resourceTypes[?resourceType=='accounts'].locations" -o table
```

## Contributing

This repository is designed as a reference implementation. Contributions that improve clarity, correctness, or Azure best practices are welcome.

## License

This project is provided as-is for educational and reference purposes.

## Related Resources

- [Microsoft Purview Documentation](https://learn.microsoft.com/azure/purview/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Purview REST API Reference](https://learn.microsoft.com/rest/api/purview/)