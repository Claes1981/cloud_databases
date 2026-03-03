#:package MongoDB.Driver@3.*

using MongoDB.Driver;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

// Read the connection string from environment variable
var connectionString = Environment.GetEnvironmentVariable("COSMOS_CONNECTION_STRING")
    ?? throw new InvalidOperationException(
        "COSMOS_CONNECTION_STRING environment variable is not set. " +
        "Set it with: export COSMOS_CONNECTION_STRING=\"your-connection-string\"");

// Connect to Cosmos DB
var client = new MongoClient(connectionString);
var database = client.GetDatabase("bookmarks_db");
var collection = database.GetCollection<Bookmark>("bookmarks");

Console.WriteLine("Connected to Cosmos DB successfully!");
Console.WriteLine($"Database: bookmarks_db");
Console.WriteLine($"Collection: bookmarks");
Console.WriteLine();

// === CREATE: Insert bookmarks ===
Console.WriteLine("--- Inserting Bookmarks ---");

var bookmarks = new List<Bookmark>
{
    new()
    {
        Title = "Microsoft Learn",
        Url = "https://learn.microsoft.com",
        Category = "learning",
        Tags = ["microsoft", "documentation", "tutorials"]
    },
    new()
    {
        Title = "GitHub",
        Url = "https://github.com",
        Category = "development",
        Tags = ["git", "code", "collaboration"]
    },
    new()
    {
        Title = "Azure Portal",
        Url = "https://portal.azure.com",
        Category = "cloud",
        Tags = ["azure", "management", "portal"]
    },
    new()
    {
        Title = "Stack Overflow",
        Url = "https://stackoverflow.com",
        Category = "development",
        Tags = ["questions", "community", "programming"]
    }
};

await collection.InsertManyAsync(bookmarks);
Console.WriteLine($"Inserted {bookmarks.Count} bookmarks.");
Console.WriteLine();

// === READ: Query bookmarks ===
Console.WriteLine("--- All Bookmarks ---");

var allBookmarks = await collection.Find(_ => true).ToListAsync();
foreach (var b in allBookmarks)
{
    Console.WriteLine($"  [{b.Category}] {b.Title} - {b.Url}");
}
Console.WriteLine($"Total: {allBookmarks.Count} bookmarks");
Console.WriteLine();

// Filter by category
Console.WriteLine("--- Development Bookmarks ---");

var devFilter = Builders<Bookmark>.Filter.Eq(b => b.Category, "development");
var devBookmarks = await collection.Find(devFilter).ToListAsync();
foreach (var b in devBookmarks)
{
    Console.WriteLine($"  {b.Title} ({string.Join(", ", b.Tags)})");
}
Console.WriteLine($"Found: {devBookmarks.Count} development bookmarks");
Console.WriteLine();

// Filter by tag
Console.WriteLine("--- Bookmarks tagged 'azure' ---");

var tagFilter = Builders<Bookmark>.Filter.AnyEq(b => b.Tags, "azure");
var azureBookmarks = await collection.Find(tagFilter).ToListAsync();
foreach (var b in azureBookmarks)
{
    Console.WriteLine($"  {b.Title} - {b.Url}");
}
Console.WriteLine();

// === UPDATE: Modify a bookmark ===
Console.WriteLine("--- Updating a Bookmark ---");

var updateFilter = Builders<Bookmark>.Filter.Eq(b => b.Title, "GitHub");
var update = Builders<Bookmark>.Update
    .Set(b => b.Title, "GitHub - Where the world builds software")
    .Set(b => b.Tags, new[] { "git", "code", "collaboration", "open-source" });

var updateResult = await collection.UpdateOneAsync(updateFilter, update);
Console.WriteLine($"Matched: {updateResult.MatchedCount}, Modified: {updateResult.ModifiedCount}");

// Verify the update
var updatedBookmark = await collection.Find(updateFilter).FirstOrDefaultAsync();
if (updatedBookmark == null)
{
    // The title changed, so search by URL instead
    var urlFilter = Builders<Bookmark>.Filter.Eq(b => b.Url, "https://github.com");
    updatedBookmark = await collection.Find(urlFilter).FirstOrDefaultAsync();
}
Console.WriteLine($"Updated title: {updatedBookmark?.Title}");
Console.WriteLine($"Updated tags: {string.Join(", ", updatedBookmark?.Tags ?? [])}");
Console.WriteLine();

// === DELETE: Remove a bookmark ===
Console.WriteLine("--- Deleting a Bookmark ---");

var deleteFilter = Builders<Bookmark>.Filter.Eq(b => b.Title, "Stack Overflow");
var deleteResult = await collection.DeleteOneAsync(deleteFilter);
Console.WriteLine($"Deleted: {deleteResult.DeletedCount} bookmark(s)");
Console.WriteLine();

// Final count
var finalCount = await collection.CountDocumentsAsync(_ => true);
Console.WriteLine($"--- Final bookmark count: {finalCount} ---");

// Optional: Clean up all inserted documents
await collection.DeleteManyAsync(_ => true);
Console.WriteLine("All bookmarks deleted.");

// Document model
record Bookmark
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; init; }

    [BsonElement("title")]
    public required string Title { get; init; }

    [BsonElement("url")]
    public required string Url { get; init; }

    [BsonElement("category")]
    public required string Category { get; init; }

    [BsonElement("tags")]
    public string[] Tags { get; init; } = [];

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}
