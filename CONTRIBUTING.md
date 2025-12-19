# Contributing to Purview Infrastructure as Code

Thank you for your interest in contributing to this project! This repository serves as a reference implementation for provisioning Microsoft Purview via Azure Developer CLI and Bicep.

## Project Goals

This project aims to:
1. Provide a reproducible, code-only setup for Microsoft Purview provisioning
2. Demonstrate Azure infrastructure-as-code best practices
3. Serve as a foundation for data governance discussions and implementations
4. Maintain clarity and simplicity as a reference architecture

## Types of Contributions Welcome

### Encouraged Contributions

- **Bug Fixes**: Errors in Bicep templates, incorrect documentation, broken links
- **Documentation Improvements**: Clarity, accuracy, additional examples
- **Bicep Best Practices**: More efficient or idiomatic Bicep patterns
- **azd Integration**: Better parameter handling, environment management
- **Testing**: Validation scripts, what-if analysis improvements
- **Examples**: Additional configuration scenarios (networking, multi-region, etc.)

### Discouraged Contributions

- **Scope Creep**: Adding features beyond Purview infrastructure provisioning
- **Application Code**: This is infrastructure-only (no app deployments)
- **Portal Automation**: Out of scope (see README for rationale)
- **Alternative IaC Tools**: This project uses Bicep + azd specifically

## How to Contribute

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/purview-infra-as-code.git
cd purview-infra-as-code
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Use prefixes:
- `feature/` - New capabilities
- `fix/` - Bug fixes
- `docs/` - Documentation only
- `refactor/` - Code improvements without behavior change

### 3. Make Your Changes

- **Test Locally**: Validate Bicep templates with `az bicep build`
- **Follow Conventions**: Match existing code style and structure
- **Update Documentation**: If behavior changes, update README/ARCHITECTURE
- **Keep It Focused**: One logical change per PR

### 4. Validate Your Changes

```bash
# Validate Bicep syntax
az bicep build --file infra/main.bicep

# Test deployment (optional, costs money)
azd auth login
azd env new test-contribution
azd provision
azd down --force --purge
```

### 5. Commit and Push

```bash
git add .
git commit -m "Brief description of your change"
git push origin feature/your-feature-name
```

Commit message guidelines:
- Use present tense ("Add feature" not "Added feature")
- Be concise but descriptive
- Reference issues if applicable ("Fix #123")

### 6. Open a Pull Request

- Go to your fork on GitHub
- Click "New Pull Request"
- Fill out the PR template (if provided)
- Link related issues

## Code Standards

### Bicep

- Use descriptive parameter and variable names
- Add `@description()` to all parameters
- Follow [Azure naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- Prefer explicit over implicit (e.g., explicit resource dependencies)
- Add comments for complex logic

Example:
```bicep
@minLength(3)
@maxLength(24)
@description('Name of the storage account')
param storageAccountName string
```

### Documentation

- Use clear, concise language
- Provide examples for complex concepts
- Link to official Azure documentation where relevant
- Keep the "why" as important as the "how"

### Testing

Before submitting:
- [ ] Bicep templates build without errors
- [ ] Changes tested in a clean environment (if possible)
- [ ] Documentation updated to reflect changes
- [ ] No unrelated changes included

## Pull Request Process

1. **Review**: Maintainers will review your PR within a few days
2. **Feedback**: Address any requested changes
3. **Approval**: Once approved, maintainer will merge
4. **Release**: Changes appear in the main branch immediately

## Questions or Issues?

- **Bug Reports**: Open an issue with details and steps to reproduce
- **Feature Requests**: Open an issue describing the use case and benefit
- **Questions**: Open a discussion or issue for clarification

## Code of Conduct

Be respectful, constructive, and professional. This is an educational project—we're all here to learn and improve.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Thank You!

Your contributions help make this a better reference for the Azure community. Every improvement, no matter how small, is appreciated.
