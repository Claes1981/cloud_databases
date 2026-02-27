# AGENTS.md
# Guidelines for Agentic Coding in cloud_databases Repository

## Overview
This repository contains infrastructure-as-code scripts for provisioning Azure CosmosDB resources. Currently, it includes:
- Bash scripts for Azure CLI-based provisioning

## Build/Lint/Test Commands

### Shell Scripts
```bash
# Make shell scripts executable
chmod +x provision-cosmosdb.sh

# Run shellcheck for linting (if available)
shellcheck provision-cosmosdb.sh

# Execute the provisioning script
./provision-cosmosdb.sh
```

### Running Tests
Since this is primarily an IaC repository with bash scripts, tests are typically integration tests that verify the provisioned resources.

```bash
# Test the script syntax
bash -n provision-cosmosdb.sh

# Dry-run approach (comment out destructive operations or use --dryrun flags where supported)
# Note: Azure CLI doesn't have universal dry-run support, so manual review is recommended
```

## Code Style Guidelines

### Bash Scripts
1. **Shebang**: Always include `#!/bin/bash` at the top
2. **Error Handling**: Use `set -euo pipefail` to fail fast on errors
3. **Indentation**: Use 2 spaces for indentation within blocks
4. **Quoting**: Always quote variables (`"$VAR"`) to handle spaces/special characters
5. **Comments**: 
   - File header comment explaining purpose
   - Section comments for major steps
   - Inline comments for complex logic
6. **Variables**: Use UPPER_CASE_SNAKE_CASE for constants/configuration
7. **Functions**: Use lowercase_with_underscores() for function names
8. **Exit Codes**: Return meaningful exit codes (0=success, non-zero=failure)
9. **Output**: Provide clear progress messages with echo statements

### Naming Conventions
- **Files**: lowercase-with-hyphens.sh (e.g., `provision-cosmosdb.sh`)
- **Variables**: UPPER_CASE_SNAKE_CASE for configuration
- **Functions**: lowercase_with_underscores()
- **Resources**: Follow Azure naming conventions (lowercase alphanumeric, max 63 chars)

### Error Handling
1. Validate inputs before using them
2. Check command success/failure explicitly when needed
3. Provide descriptive error messages
4. Clean up resources on failure when possible

Example pattern:
```bash
if ! az group create --name "$RESOURCE_GROUP" --location "$LOCATION"; then
    echo "ERROR: Failed to create resource group" >&2
    exit 1
fi
```

### Configuration Management
1. Place configurable values at the top of scripts with clear comments
2. Avoid hardcoding sensitive information (use environment variables or Azure Key Vault)
3. Document required permissions and prerequisites

### Best Practices
1. **Idempotency**: Design scripts to be safely rerunnable without side effects
2. **Modularity**: Break complex workflows into separate scripts/functions
3. **Documentation**: Include usage instructions in script headers
4. **Dependencies**: Document all prerequisites (Azure CLI version, subscriptions, etc.)
5. **Logging**: Use echo statements for progress tracking during execution

## Repository Structure
```
cloud_databases/
├── provision-cosmosdb.sh          # Main provisioning script
└── .git/                         # Git repository files
```

## Prerequisites
1. Azure CLI installed and configured
2. Appropriate Azure subscription and permissions
3. Bash shell environment

## Common Commands

### Azure CLI Setup
```bash
# Login to Azure
az login

# Set active subscription
az account set --subscription "Your-Subscription-ID"

# Verify installation
az --version
```

### Script Execution
```bash
# Run the provisioning script
./provision-cosmosdb.sh

# Customize parameters by setting environment variables before running
RESOURCE_GROUP="MyCustomRG" ./provision-cosmosdb.sh
```

### Resource Management
```bash
# List created resources
az group show --name CloudDatabasesRG

# Delete resources (cleanup)
az group delete --name CloudDatabasesRG --yes --no-wait
```

## Testing Strategy
Since this provisions real cloud resources:
1. Test in a dedicated test subscription/resource group
2. Start with minimal configurations
3. Verify each step independently where possible
4. Implement cleanup procedures
5. Consider using Azure CLI's `--dryrun` flag where available

## Security Guidelines
1. Never commit secrets or credentials
2. Use Azure Managed Identity where possible
3. Follow principle of least privilege for service principals
4. Clean up test resources promptly
5. Review Azure policy compliance requirements

## Contribution Workflow
1. Fork the repository
2. Create feature branches from main
3. Make minimal, focused changes
4. Test thoroughly before submitting PRs
5. Update documentation as needed
6. Follow semantic commit messages

## Example Commit Messages
- `feat: add CosmosDB serverless tier support`
- `fix: handle resource group creation conflicts`
- `docs: update provisioning script header comments`
- `refactor: extract database creation to separate function`

## Troubleshooting
Common issues and solutions:
1. **Authentication failures**: Run `az login` again
2. **Permission errors**: Check RBAC assignments
3. **Region unavailable**: Try different Azure region
4. **Script fails mid-execution**: Check previous steps for errors

For detailed error information, run commands with `--debug` flag.
