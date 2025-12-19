# Quick Start Guide

Get Microsoft Purview up and running in under 10 minutes.

## Prerequisites

✅ Azure subscription  
✅ Azure CLI installed  
✅ Azure Developer CLI (azd) installed  
✅ Contributor or Owner role on subscription

## Install Azure Developer CLI

If you don't have azd installed:

**Windows (PowerShell):**
```powershell
winget install microsoft.azd
```

**macOS (Homebrew):**
```bash
brew tap azure/azd && brew install azd
```

**Linux:**
```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

[More installation options](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)

## Three Steps to Purview

### 1. Clone and Initialize

```bash
# Clone this repository
git clone https://github.com/rukasakurai/purview-infra-as-code.git
cd purview-infra-as-code

# Login to Azure
azd auth login

# Initialize environment
azd init
```

When prompted:
- **Environment name**: `dev` (or any name you prefer)
- **Subscription**: Select your Azure subscription
- **Location**: `eastus` (or any supported region)

### 2. Provision

```bash
azd provision
```

This takes 5-10 minutes and will:
- ✅ Create a resource group
- ✅ Provision a Purview account
- ✅ Configure managed identity
- ✅ Assign permissions
- ✅ Output the Purview endpoint

### 3. Access Purview

After provisioning completes:

```bash
# Get the Purview endpoint
azd env get-values | grep PURVIEW_ENDPOINT
```

Open the URL in your browser to access the Purview Governance Portal.

## What's Next?

You now have a working Purview account! Next steps:

1. **Register Data Sources**: Connect Azure SQL, ADLS Gen2, or other sources
2. **Create Scans**: Set up automated scanning schedules
3. **Define Glossary**: Add business terms and definitions
4. **Explore Catalog**: Browse discovered assets and metadata

See [Purview Documentation](https://learn.microsoft.com/azure/purview/) for guidance.

## Common Commands

```bash
# View all environment variables
azd env get-values

# Check deployment status
azd show

# Create another environment (e.g., prod)
azd env new prod
azd provision

# Switch between environments
azd env select dev
azd env select prod

# Update infrastructure (after Bicep changes)
azd provision

# Delete everything
azd down
```

## Troubleshooting

### "Purview account name is not available"

Names must be globally unique. Generate a new one:

```bash
azd env set PURVIEW_ACCOUNT_NAME my-unique-name-$(date +%s)
azd provision
```

### "Insufficient permissions"

Ensure you have Contributor or Owner role:

```bash
# Check your role assignment
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) \
  --query "[?scope=='/subscriptions/$(az account show --query id -o tsv)'].roleDefinitionName"
```

### "Location not supported"

Check supported regions:

```bash
az provider show --namespace Microsoft.Purview \
  --query "resourceTypes[?resourceType=='accounts'].locations" -o table
```

Common regions: eastus, westus, westeurope, northeurope, southeastasia

### "Microsoft.Purview not registered"

Register the provider:

```bash
az provider register --namespace Microsoft.Purview
az provider show --namespace Microsoft.Purview --query registrationState
```

Wait for status to change to "Registered" (1-2 minutes).

## Cost Estimate

Running this setup costs approximately:
- **Purview**: ~$140/month (base capacity unit)
- **Storage**: ~$2-5/month
- **Event Hub**: ~$10-15/month

**Total: ~$150-160/month**

💡 **Tip**: Delete the environment when not in use: `azd down`

## Need Help?

- 📖 [Full README](./README.md)
- 🏗️ [Architecture Documentation](./ARCHITECTURE.md)
- 🐛 [Report an Issue](https://github.com/rukasakurai/purview-infra-as-code/issues)
- 💬 [Ask a Question](https://github.com/rukasakurai/purview-infra-as-code/discussions)

## Next Reading

Once you're comfortable with the basics:
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for design decisions
- Check [CONTRIBUTING.md](./CONTRIBUTING.md) to contribute improvements
- Explore [Azure Purview Best Practices](https://learn.microsoft.com/azure/purview/concept-best-practices)
