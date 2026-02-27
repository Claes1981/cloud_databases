@description('The name of the Cosmos DB account. Must be globally unique.')
param accountName string

@description('The Azure region for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name of the MongoDB database.')
param databaseName string = 'bookmarks_db'

@description('The name of the MongoDB collection.')
param collectionName string = 'bookmarks'

@description('The shard key for the collection.')
param shardKey string = 'category'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      {
        name: 'EnableServerless'
      }
      {
        name: 'EnableMongo'
      }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    apiProperties: {
      serverVersion: '4.2'
    }
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource collection 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections@2024-05-15' = {
  parent: database
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

@description('The name of the deployed Cosmos DB account.')
output accountNameOutput string = cosmosAccount.name

@description('The primary connection string for the Cosmos DB account.')
output connectionString string = cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
