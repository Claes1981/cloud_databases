// ============================================
// Cosmos DB MongoDB Infrastructure Module
// Provisions Cosmos DB with MongoDB API
// ============================================

// -----------------------------
// Parameters
// -----------------------------

@description('The name of the Cosmos DB account. Must be globally unique, lowercase, 3-44 characters.')
@minLength(3)
@maxLength(44)
param accountName string

@description('The Azure region for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name of the MongoDB database.')
@minLength(1)
@maxLength(31)
param databaseName string = 'bookmarks_db'

@description('The name of the MongoDB collection.')
@minLength(1)
@maxLength(31)
param collectionName string = 'bookmarks'

@description('The shard key field name for the collection.')
param shardKey string = 'category'

// -----------------------------
// Variables
// -----------------------------

var serverVersion = '4.2'
var databaseAccountOfferType = 'Standard'
var failoverPriority = 0
var isZoneRedundant = false

var capabilities = [
  {
    name: 'EnableServerless'
  }
  {
    name: 'EnableMongo'
  }
]

var locations = [
  {
    locationName: location
    failoverPriority: failoverPriority
    isZoneRedundant: isZoneRedundant
  }
]

// -----------------------------
// Resources
// -----------------------------

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: databaseAccountOfferType
    capabilities: capabilities
    locations: locations
    apiProperties: {
      serverVersion: serverVersion
    }
  }
}

resource mongodbDatabase 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource mongoCollection 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections@2024-05-15' = {
  parent: mongodbDatabase
  name: collectionName
  properties: {
    resource: {
      id: collectionName
      shardKey: {
        '${shardKey}': 'Hash'
      }
    }
  }
}

// -----------------------------
// Outputs
// -----------------------------

@description('The name of the deployed Cosmos DB account.')
output accountNameOutput string = cosmosAccount.name

@description('The location of the deployed Cosmos DB account.')
output accountLocation string = cosmosAccount.location

@description('The deployed MongoDB database name.')
output deployedDatabaseName string = mongodbDatabase.name

@description('The deployed MongoDB collection name.')
output deployedCollectionName string = mongoCollection.name

@description('The shard key used for the collection.')
output collectionShardKey string = shardKey