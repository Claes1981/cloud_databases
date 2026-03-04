#!/bin/bash
set -euo pipefail

# ============================================
# CosmosDB Provisioning Script
# Provisions a CosmosDB account with MongoDB API
# ============================================

# -----------------------------
# Configuration
# -----------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-CloudDatabasesRG}"
LOCATION="${LOCATION:-northeurope}"
ACCOUNT_NAME="${ACCOUNT_NAME:-cosmosdb-claes-bcd}"
DATABASE_NAME="${DATABASE_NAME:-bookmarks_db}"
COLLECTION_NAME="${COLLECTION_NAME:-bookmarks}"
SHARD_KEY="${SHARD_KEY:-category}"

# -----------------------------
# Logger Module
# -----------------------------
log_info() {
    echo "$1"
}

log_success() {
    echo "✓ $1"
}

log_error() {
    echo "✗ ERROR: $1" >&2
}

log_section() {
    echo ""
    echo "=== $1 ==="
}

# -----------------------------
# Validator Module
# -----------------------------
validate_resource_name() {
    local name="$1"
    local field="$2"
    
    if [[ -z "$name" ]]; then
        log_error "$field cannot be empty"
        return 1
    fi
    
    if [[ ${#name} -gt 63 ]]; then
        log_error "$field exceeds maximum length of 63 characters"
        return 1
    fi
    
    if ! [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
        log_error "$field must start with alphanumeric and contain only alphanumeric, hyphen, underscore, or period"
        return 1
    fi
    
    return 0
}

validate_configuration() {
    local validation_failed=0
    
    if ! validate_resource_name "$RESOURCE_GROUP" "Resource Group"; then
        validation_failed=1
    fi
    
    if ! validate_resource_name "$LOCATION" "Location"; then
        validation_failed=1
    fi
    
    if ! validate_resource_name "$ACCOUNT_NAME" "Account Name"; then
        validation_failed=1
    fi
    
    if ! validate_resource_name "$DATABASE_NAME" "Database Name"; then
        validation_failed=1
    fi
    
    if ! validate_resource_name "$COLLECTION_NAME" "Collection Name"; then
        validation_failed=1
    fi
    
    if [[ $validation_failed -eq 1 ]]; then
        return 1
    fi
    
    return 0
}

# -----------------------------
# Azure Resource Group Module
# -----------------------------
resource_group_exists() {
    local rg_name="$1"
    
    az group shows \
        --name "$rg_name" \
        --output none \
        >/dev/null 2>&1
}

create_resource_group() {
    local rg_name="$1"
    local location="$2"
    
    if resource_group_exists "$rg_name"; then
        log_info "Resource group '$rg_name' already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating resource group '$rg_name' in '$location'..."
    
    if ! az group create \
        --name "$rg_name" \
        --location "$location" \
        --output none; then
        log_error "Failed to create resource group '$rg_name'"
        return 1
    fi
    
    log_success "Resource group '$rg_name' created successfully"
    return 0
}

# -----------------------------
# CosmosDB Account Module
# -----------------------------
cosmosdb_account_exists() {
    local account_name="$1"
    local rg_name="$2"
    
    az cosmosdb shows \
        --name "$account_name" \
        --resource-group "$rg_name" \
        --output none \
        >/dev/null 2>&1
}

create_cosmosdb_account() {
    local account_name="$1"
    local rg_name="$2"
    local location="$3"
    
    if cosmosdb_account_exists "$account_name" "$rg_name"; then
        log_info "CosmosDB account '$account_name' already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating CosmosDB account '$account_name' (this may take several minutes)..."
    
    if ! az cosmosdb create \
        --name "$account_name" \
        --resource-group "$rg_name" \
        --kind MongoDB \
        --server-version "4.2" \
        --capabilities EnableServerless \
        --locations regionName="$location" failoverPriority=0 isZoneRedundant=false \
        --output none; then
        log_error "Failed to create CosmosDB account '$account_name'"
        return 1
    fi
    
    log_success "CosmosDB account '$account_name' created successfully"
    return 0
}

# -----------------------------
# MongoDB Database Module
# -----------------------------
mongodb_database_exists() {
    local account_name="$1"
    local rg_name="$2"
    local db_name="$3"
    
    az cosmosdb mongodb database shows \
        --account-name "$account_name" \
        --resource-group "$rg_name" \
        --name "$db_name" \
        --output none \
        >/dev/null 2>&1
}

create_mongodb_database() {
    local account_name="$1"
    local rg_name="$2"
    local db_name="$3"
    
    if mongodb_database_exists "$account_name" "$rg_name" "$db_name"; then
        log_info "Database '$db_name' already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating database '$db_name'..."
    
    if ! az cosmosdb mongodb database create \
        --account-name "$account_name" \
        --resource-group "$rg_name" \
        --name "$db_name" \
        --output none; then
        log_error "Failed to create database '$db_name'"
        return 1
    fi
    
    log_success "Database '$db_name' created successfully"
    return 0
}

# -----------------------------
# MongoDB Collection Module
# -----------------------------
mongodb_collection_exists() {
    local account_name="$1"
    local rg_name="$2"
    local db_name="$3"
    local collection_name="$4"
    
    az cosmosdb mongodb collection shows \
        --account-name "$account_name" \
        --resource-group "$rg_name" \
        --database-name "$db_name" \
        --name "$collection_name" \
        --output none \
        >/dev/null 2>&1
}

create_mongodb_collection() {
    local account_name="$1"
    local rg_name="$2"
    local db_name="$3"
    local collection_name="$4"
    local shard_key="$5"
    
    if mongodb_collection_exists "$account_name" "$rg_name" "$db_name" "$collection_name"; then
        log_info "Collection '$collection_name' already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating collection '$collection_name' with shard key '$shard_key'..."
    
    if ! az cosmosdb mongodb collection create \
        --account-name "$account_name" \
        --resource-group "$rg_name" \
        --database-name "$db_name" \
        --name "$collection_name" \
        --shard "$shard_key" \
        --output none; then
        log_error "Failed to create collection '$collection_name'"
        return 1
    fi
    
    log_success "Collection '$collection_name' created successfully"
    return 0
}

# -----------------------------
# Connection String Module
# -----------------------------
get_connection_string() {
    local account_name="$1"
    local rg_name="$2"
    
    log_info "Retrieving connection string..."
    
    local connection_string
    connection_string=$(az cosmosdb keys list \
        --name "$account_name" \
        --resource-group "$rg_name" \
        --type connection-strings \
        --query "connectionStrings[0].connectionString" \
        --output tsv)
    
    if [[ -z "$connection_string" ]]; then
        log_error "Failed to retrieve connection string"
        return 1
    fi
    
    echo "$connection_string"
    return 0
}

# -----------------------------
# Output Module
# -----------------------------
print_provisioning_summary() {
    local account_name="$1"
    local db_name="$2"
    local collection_name="$3"
    local connection_string="$4"
    
    log_section "Provisioning Complete"
    echo "Account:    $account_name"
    echo "Database:   $db_name"
    echo "Collection: $collection_name"
    echo ""
    echo "Connection String:"
    echo "$connection_string"
}

# -----------------------------
# Main Orchestration
# -----------------------------
main() {
    log_section "CosmosDB Provisioning Script"
    
    log_info "Validating configuration..."
    if ! validate_configuration; then
        log_error "Configuration validation failed"
        exit 1
    fi
    log_success "Configuration validated"
    
    log_section "Provisioning Resources"
    
    if ! create_resource_group "$RESOURCE_GROUP" "$LOCATION"; then
        exit 1
    fi
    
    if ! create_cosmosdb_account "$ACCOUNT_NAME" "$RESOURCE_GROUP" "$LOCATION"; then
        exit 1
    fi
    
    if ! create_mongodb_database "$ACCOUNT_NAME" "$RESOURCE_GROUP" "$DATABASE_NAME"; then
        exit 1
    fi
    
    if ! create_mongodb_collection "$ACCOUNT_NAME" "$RESOURCE_GROUP" "$DATABASE_NAME" "$COLLECTION_NAME" "$SHARD_KEY"; then
        exit 1
    fi
    
    local connection_string
    if ! connection_string=$(get_connection_string "$ACCOUNT_NAME" "$RESOURCE_GROUP"); then
        exit 1
    fi
    
    print_provisioning_summary "$ACCOUNT_NAME" "$DATABASE_NAME" "$COLLECTION_NAME" "$connection_string"
    
    log_success "All resources provisioned successfully"
}

main "$@"