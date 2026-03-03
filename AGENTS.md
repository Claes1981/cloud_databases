# AGENTS.md
# Guidelines for Agentic Coding in cloud_databases Repository

## Overview
This repository contains infrastructure-as-code scripts for provisioning Azure CosmosDB resources with MongoDB API.

## Quick Start
```bash
# Validate script syntax
bash -n provision-cosmosdb.sh

# Lint with shellcheck
shellcheck provision-cosmosdb.sh

# Run provisioning
./provision-cosmosdb.sh
```

## Build/Lint/Test Commands

### Linting
```bash
# Lint all shell scripts
shellcheck *.sh

# Lint with specific checks disabled
shellcheck -e SC1091 provision-cosmosdb.sh
```

### Testing
```bash
# Syntax validation (required before commit)
bash -n provision-cosmosdb.sh

# Full validation pipeline
bash -n provision-cosmosdb.sh && shellcheck provision-cosmosdb.sh
```

Note: This is an IaC repository. Integration tests provision real Azure resources.

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

### What to Avoid
- Never use `cd <directory> && <command>` - use `--workdir` or `--cwd` flags
- Don't use unquoted variables: `$VAR` should be `"$VAR"`
- Avoid `set +e` or disabling error handling
- Don't hardcode secrets or credentials
- Never use interactive commands that require user input

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
```bash
# Azure CLI setup
az login
az account set --subscription "Your-Subscription-ID"

# Run provisioning script
./provision-cosmosdb.sh
RESOURCE_GROUP="MyCustomRG" ./provision-cosmosdb.sh

# Resource cleanup
az group delete --name CloudDatabasesRG --yes --no-wait
```

## Testing & Security
- Test in dedicated test subscription/resource group
- Never commit secrets or credentials
- Use Azure Managed Identity where possible
- Follow principle of least privilege for service principals
- Clean up test resources promptly

## Troubleshooting
Common issues and solutions:
1. **Authentication failures**: Run `az login` again
2. **Permission errors**: Check RBAC assignments
3. **Region unavailable**: Try different Azure region
4. **Script fails mid-execution**: Check previous steps for errors

For detailed error information, run commands with `--debug` flag.

## For Agents: Creating New Scripts
When adding new provisioning scripts:
1. Follow existing patterns in `provision-cosmosdb.sh`
2. Use `set -euo pipefail` at line 2
3. Quote all variables: `"$VAR"` not `$VAR`
4. Add progress messages with `echo`
5. Run `shellcheck` before committing
6. Ensure idempotency where possible
