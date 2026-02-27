#!/bin/bash
set -euo pipefail

# ============================================
# CosmosDB Provisioning Script
# Provisions a CosmosDB account with MongoDB API
# ============================================

# Configuration — change these for your environment
RESOURCE_GROUP="CloudDatabasesRG"
LOCATION="northeurope"
ACCOUNT_NAME="cosmosdb-claes-bcd"
DATABASE_NAME="bookmarks_db"
COLLECTION_NAME="bookmarks"

echo "=== CosmosDB Provisioning Script ==="
echo ""

# Step 1: Resource Group
echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output none

# Step 2: CosmosDB Account
echo "Creating CosmosDB account '$ACCOUNT_NAME' (this may take several minutes)..."
az cosmosdb create \
  --name $ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind MongoDB \
  --server-version "4.2" \
  --capabilities EnableServerless \
  --locations regionName=$LOCATION failoverPriority=0 isZoneRedundant=false \
  --output none

# Step 3: Database
echo "Creating database '$DATABASE_NAME'..."
az cosmosdb mongodb database create \
  --account-name $ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --name $DATABASE_NAME \
  --output none

# Step 4: Collection
echo "Creating collection '$COLLECTION_NAME' with shard key 'category'..."
az cosmosdb mongodb collection create \
  --account-name $ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --database-name $DATABASE_NAME \
  --name $COLLECTION_NAME \
  --shard "category" \
  --output none

# Step 5: Retrieve Connection String
echo "Retrieving connection string..."
CONNECTION_STRING=$(az cosmosdb keys list \
  --name $ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --type connection-strings \
  --query "connectionStrings[0].connectionString" \
  --output tsv)

echo ""
echo "=== Provisioning Complete ==="
echo "Account:    $ACCOUNT_NAME"
echo "Database:   $DATABASE_NAME"
echo "Collection: $COLLECTION_NAME"
echo ""
echo "Connection String:"
echo "$CONNECTION_STRING"
