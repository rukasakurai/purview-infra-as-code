# Purview Infrastructure as Code

> [!WARNING]
> This repository is a work in progress and may include incorrect or incomplete information. Use at your own risk.

This repository provides a reproducible, code-only setup for provisioning **Microsoft Purview Data Governance** in Azure using the Azure Developer CLI (azd) and Bicep templates. No Azure Portal interaction is required.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [What Can Be Automated via IaC](#what-can-be-automated-via-iac)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Multiple Environments](#multiple-environments)
- [Project Structure](#project-structure)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Related Resources](#related-resources)

## Overview

This project treats **Purview as infrastructure**, not as an application. It provides a foundation for data governance that can be referenced in discussions about well-governed AI agents and data platforms in Azure.

### Key Principles

- **Infrastructure-Only**: This repository provisions Azure resources only. There is no application code to deploy.
- **No Portal Required**: Everything is automated via code. No manual steps in the Azure Portal are needed.
- **azd-Compatible**: Uses Azure Developer CLI for a streamlined, reproducible provisioning experience.

## Features

✨ **Key Capabilities:**

- 🚀 **One-Command Deployment**: Provision Purview with a single `azd provision` command
- 🔄 **Reproducible**: Identical infrastructure every time, version-controlled setup
- 🔐 **Managed Identity**: Automatic system-assigned identity configuration
- 👥 **RBAC Integration**: Automatic role assignment for authenticated users
- 🌍 **Multi-Environment**: Easy dev/test/prod environment management
- 📝 **Pure Infrastructure as Code**: 100% Bicep templates, no manual Portal steps
- 🧹 **Clean Teardown**: Complete resource cleanup with `azd down`

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
git clone https://github.com/rukasakurai/purview-infra-as-code.git
cd purview-infra-as-code

azd auth login
azd init
```

When prompted:
- **Environment name**: Choose a name (e.g., `dev`, `prod`, `myenv`)
- **Azure subscription**: Select your subscription
- **Azure location**: Choose a region (e.g., `japaneast`)

### 2. (One-time) Register the Purview resource provider

Purview provisioning will fail validation if the `Microsoft.Purview` resource provider isn’t registered on the target subscription.

```bash
az provider register --namespace Microsoft.Purview
az provider show --namespace Microsoft.Purview --query "registrationState" -o tsv
```

If registration is in progress, wait a few minutes and re-run the `show` command until it returns `Registered`.

### 3. Provision the Infrastructure

```bash
azd provision
```

This command will:
1. Create a resource group named `rg-{environmentName}`
2. Provision a Microsoft Purview account with a globally unique name
3. Configure system-assigned managed identity
4. Assign Owner role on the resource group (if `AZURE_PRINCIPAL_ID` is provided)
5. Output the Purview endpoint and resource details

### 4. Verify the Deployment

After provisioning completes, you can:

```bash
# View outputs
azd env get-values

# Legacy account endpoint (may still appear in documentation)
# https://{purviewAccountName}.purview.azure.com
```

You can now log into the Purview Governance Portal to configure data sources, scans, and policies.
You can now access Microsoft Purview:

- **New Microsoft Purview portal**: https://purview.microsoft.com
- **Classic governance portal** (if needed): https://web.purview.azure.com/resource/{purviewAccountName}

Note: The legacy account endpoint format https://{purviewAccountName}.purview.azure.com may still appear in documentation as an *endpoint*, but the recommended portal entry point is https://purview.microsoft.com.

## Configuration

### Environment Variables

azd uses environment variables to parameterize deployments. Key variables:

- `AZURE_ENV_NAME`: Environment name (used in resource naming)
- `AZURE_LOCATION`: Azure region for resources
- `AZURE_PRINCIPAL_ID`: User/service principal ID for role assignment
- `AZURE_SUBSCRIPTION_ID`: Target subscription (set by azd init)

You can override defaults by setting environment variables before running `azd provision`:

```bash
azd env set AZURE_LOCATION japaneast
azd provision
```

### Custom Purview Account Name

By default, the Purview account name is generated as `purview-{uniqueString}`. To specify a custom name:

```bash
azd env set PURVIEW_ACCOUNT_NAME mycustompurview123
azd provision
```

**Note**: Purview account names must be globally unique. Spaces and symbols aren't allowed.

For best compatibility, use a DNS-safe name (letters/numbers and hyphens), and avoid leading/trailing hyphens.

## Multiple Environments

To create multiple independent Purview instances (e.g., dev and prod):

```bash
# Create dev environment
azd env new dev
azd env set AZURE_LOCATION japaneast
azd provision

# Create prod environment
azd env new prod
azd env set AZURE_LOCATION japaneast
azd provision

# Switch between environments
azd env select dev
azd env select prod
```
> [!IMPORTANT]
> Most tenants can create **only one** Microsoft Purview account per tenant. Creating multiple `azd` environments is supported,
> but provisioning more than one Purview account in the same tenant typically fails unless your tenant has a preexisting quota
> that allows multiple accounts.

## Project Structure

```
purview-infra-as-code/
├── .github/                 # GitHub workflows and configurations
├── infra/                   # Infrastructure as Code (Bicep templates)
│   ├── main.bicep          # Main orchestration template
│   ├── main.parameters.json # Parameter mappings
│   └── resources/          # Modular resource definitions
│       ├── purview.bicep   # Purview account module
│       └── roleAssignments.bicep # RBAC assignments
├── azure.yaml              # Azure Developer CLI configuration
├── .env.example            # Example environment variables
├── README.md               # This file
├── QUICKSTART.md           # Quick start guide (10-minute setup)
├── ARCHITECTURE.md         # Detailed architecture documentation
└── CONTRIBUTING.md         # Contribution guidelines
```

📚 **Documentation Guide:**
- **New to this project?** Start with [QUICKSTART.md](./QUICKSTART.md)
- **Want to understand the design?** Read [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Planning to contribute?** See [CONTRIBUTING.md](./CONTRIBUTING.md)

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

**Problem**: Purview account names must be globally unique across all Azure tenants.

**Solution**: Try a different name with additional uniqueness:

```bash
# Linux/macOS
azd env set PURVIEW_ACCOUNT_NAME another-unique-name-$(date +%s)

# Or use any unique suffix
azd env set PURVIEW_ACCOUNT_NAME my-purview-12345

azd provision
```

### "Insufficient permissions"

**Problem**: You don't have the required permissions on the subscription.

**Solution**: Ensure you have:
- Contributor or Owner role on the subscription
- `Microsoft.Purview` resource provider registered

Register the provider:

```bash
az provider register --namespace Microsoft.Purview
az provider show --namespace Microsoft.Purview --query "registrationState"
```

Wait for the status to become "Registered" (typically 1-2 minutes).

### "Location not supported"

**Problem**: Not all Azure regions support Purview.

**Solution**: Check supported regions and choose one:

```bash
az provider show --namespace Microsoft.Purview --query "resourceTypes[?resourceType=='accounts'].locations" -o table
```

Common supported regions: `eastus`, `westus`, `westeurope`, `northeurope`, `southeastasia`, `japaneast`

### Deployment is slow or hangs

**Problem**: Purview provisioning can take 5-15 minutes.

**Solution**: This is normal behavior. The deployment includes:
1. Creating the Purview account
2. Provisioning managed storage and Event Hub
3. Configuring managed identity
4. Setting up RBAC assignments

Be patient and check the Azure Portal for progress if needed.

### "azd command not found"

**Problem**: Azure Developer CLI is not installed.

**Solution**: Install azd following the [official guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) or use:

```bash
# Windows (PowerShell)
winget install microsoft.azd

# macOS
brew tap azure/azd && brew install azd

# Linux
curl -fsSL https://aka.ms/install-azd.sh | bash
```

## FAQ

### Can I provision multiple Purview accounts?

⚠️ **No, in most cases.** Azure limits most tenants to **one Purview account per tenant**. Attempting to create a second account typically fails unless your organization has special quota approval. You can create multiple `azd` environments, but they should point to the same Purview account or different tenants.

### How much does this cost?

💰 **Approximately $150-160/month** for a basic setup:
- Purview Account: ~$140/month (base capacity unit)
- Managed Storage: ~$2-5/month
- Event Hub: ~$10-15/month

Use `azd down` to delete resources when not in use to avoid charges.

### Can I automate data source scanning and classification?

🔧 **Partially.** This repository only provisions the infrastructure. Data source registration, scanning, and classification require:
- [Purview PowerShell module](https://learn.microsoft.com/en-us/powershell/module/az.purview/)
- [Purview REST APIs](https://learn.microsoft.com/en-us/rest/api/purview/)
- Azure Portal (for manual configuration)

See the [What Can Be Automated](#what-can-be-automated-via-iac) section for details.

### Is this production-ready?

⚠️ **Use with caution.** This is a reference implementation. For production:
- Review and adjust security settings (network isolation, private endpoints)
- Implement proper monitoring and alerting
- Follow your organization's compliance requirements
- Test thoroughly in a non-production environment first
- Consider engaging Azure support for production deployments

### Can I use this with existing Azure resources?

✅ **Yes.** This template creates a new resource group and Purview account. After provisioning, you can:
- Connect to existing data sources (Azure SQL, ADLS, etc.)
- Assign permissions to existing identities
- Integrate with existing Azure governance policies

### What if I need to customize the Bicep templates?

✅ **Go ahead!** The templates are designed to be modified. Common customizations:
- Change resource naming conventions
- Add private endpoints
- Modify RBAC assignments
- Add additional Azure resources

See [ARCHITECTURE.md](./ARCHITECTURE.md) for guidance on extending the templates.

### Does this work in Azure Government or other sovereign clouds?

🌐 **It should, with adjustments.** You'll need to:
- Set the correct Azure cloud environment
- Verify Purview availability in your region
- Update endpoints if needed

Consult Azure documentation for cloud-specific guidance.

## Contributing

This repository is designed as a reference implementation. Contributions that improve clarity, correctness, or Azure best practices are welcome.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines on how to contribute.

## License

This project is provided as-is for educational and reference purposes. See the repository for license details.

⚠️ **Disclaimer**: This is a community project and is not officially supported by Microsoft. Use at your own risk.

## Related Resources

### Documentation
- 📖 [Microsoft Purview Documentation](https://learn.microsoft.com/azure/purview/) - Official Purview documentation
- 🛠️ [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/) - Learn about azd
- 📝 [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/) - Infrastructure as Code reference
- 🔌 [Purview REST API Reference](https://learn.microsoft.com/rest/api/purview/) - API documentation

### Tools
- [Purview PowerShell Module](https://learn.microsoft.com/powershell/module/az.purview/) - Automate Purview configuration
- [Azure CLI Purview Extension](https://learn.microsoft.com/cli/azure/purview) - Command-line management

### Community
- 💬 [GitHub Discussions](https://github.com/rukasakurai/purview-infra-as-code/discussions) - Ask questions
- 🐛 [Report Issues](https://github.com/rukasakurai/purview-infra-as-code/issues) - Bug reports and feature requests

### Related Projects
- [Azure Developer CLI Templates](https://azure.github.io/awesome-azd/) - More azd templates
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates) - Bicep template examples

---

**Made with ❤️ for the Azure community** | [⭐ Star this repo](https://github.com/rukasakurai/purview-infra-as-code) if you find it helpful!