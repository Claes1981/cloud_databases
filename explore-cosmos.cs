#:package MongoDB.Driver@3.*

using MongoDB.Driver;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

// ============================================
// Configuration Module
// ============================================
var config = new CosmosConfig(
    connectionString: Environment.GetEnvironmentVariable("COSMOS_CONNECTION_STRING")
        ?? throw new InvalidOperationException(
            "COSMOS_CONNECTION_STRING environment variable is not set."),
    databaseName: Environment.GetEnvironmentVariable("COSMOS_DATABASE_NAME") ?? "bookmarks_db",
    collectionName: Environment.GetEnvironmentVariable("COSMOS_COLLECTION_NAME") ?? "bookmarks"
);

// ============================================
// Repository Module
// ============================================
var client = new MongoClient(config.ConnectionString);
var database = client.GetDatabase(config.DatabaseName);
var collection = database.GetCollection<Bookmark>(config.CollectionName);

var bookmarkRepository = new BookmarkRepository(collection);

// ============================================
// Application Logic
// ============================================
Console.WriteLine("Connected to Cosmos DB successfully!");
Console.WriteLine($"Database: {config.DatabaseName}");
Console.WriteLine($"Collection: {config.CollectionName}");
Console.WriteLine();

await RunDemo(bookmarkRepository);

async Task RunDemo(IBookmarkRepository repository)
{
    await CreateBookmarks(repository);
    await ReadBookmarks(repository);
    await UpdateBookmark(repository);
    await DeleteBookmark(repository);
    await ShowFinalCount(repository);
    await Cleanup(repository);
}

async Task CreateBookmarks(IBookmarkRepository repository)
{
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

    await repository.InsertManyAsync(bookmarks);
    Console.WriteLine($"Inserted {bookmarks.Count} bookmarks.");
    Console.WriteLine();
}

async Task ReadBookmarks(IBookmarkRepository repository)
{
    Console.WriteLine("--- All Bookmarks ---");

    var allBookmarks = await repository.GetAllAsync();
    foreach (var bookmark in allBookmarks)
    {
        Console.WriteLine($"  [{bookmark.Category}] {bookmark.Title} - {bookmark.Url}");
    }
    Console.WriteLine($"Total: {allBookmarks.Count} bookmarks");
    Console.WriteLine();

    Console.WriteLine("--- Development Bookmarks ---");

    var devBookmarks = await repository.GetByCategoryAsync("development");
    foreach (var bookmark in devBookmarks)
    {
        Console.WriteLine($"  {bookmark.Title} ({string.Join(", ", bookmark.Tags)})");
    }
    Console.WriteLine($"Found: {devBookmarks.Count} development bookmarks");
    Console.WriteLine();

    Console.WriteLine("--- Bookmarks tagged 'azure' ---");

    var azureBookmarks = await repository.GetByTagAsync("azure");
    foreach (var bookmark in azureBookmarks)
    {
        Console.WriteLine($"  {bookmark.Title} - {bookmark.Url}");
    }
    Console.WriteLine();
}

async Task UpdateBookmark(IBookmarkRepository repository)
{
    Console.WriteLine("--- Updating a Bookmark ---");

    var githubBookmark = await repository.GetByTitleAsync("GitHub");
    if (githubBookmark != null)
    {
        await repository.UpdateAsync(new Bookmark
        {
            Id = githubBookmark.Id,
            Title = "GitHub - Where the world builds software",
            Url = githubBookmark.Url,
            Category = githubBookmark.Category,
            Tags = ["git", "code", "collaboration", "open-source"],
            CreatedAt = githubBookmark.CreatedAt
        });

        var updated = await repository.GetByTitleAsync("GitHub - Where the world builds software");
        Console.WriteLine($"Updated title: {updated?.Title}");
        Console.WriteLine($"Updated tags: {string.Join(", ", updated?.Tags ?? [])}");
    }
    Console.WriteLine();
}

async Task DeleteBookmark(IBookmarkRepository repository)
{
    Console.WriteLine("--- Deleting a Bookmark ---");

    var stackOverflow = await repository.GetByTitleAsync("Stack Overflow");
    if (stackOverflow != null)
    {
        await repository.DeleteByIdAsync(stackOverflow.Id);
        Console.WriteLine("Deleted Stack Overflow bookmark.");
    }
    Console.WriteLine();
}

async Task ShowFinalCount(IBookmarkRepository repository)
{
    var count = await repository.CountAsync();
    Console.WriteLine($"--- Final bookmark count: {count} ---");
}

async Task Cleanup(IBookmarkRepository repository)
{
    await repository.DeleteAllAsync();
    Console.WriteLine("All bookmarks deleted.");
}

// ============================================
// Domain Model
// ============================================
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

// ============================================
// Configuration
// ============================================
record CosmosConfig
{
    public string ConnectionString { get; private set; }
    public string DatabaseName { get; private set; }
    public string CollectionName { get; private set; }

    public CosmosConfig(string connectionString, string databaseName, string collectionName)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentException("Connection string cannot be empty.", nameof(connectionString));
        }
        if (string.IsNullOrWhiteSpace(databaseName))
        {
            throw new ArgumentException("Database name cannot be empty.", nameof(databaseName));
        }
        if (string.IsNullOrWhiteSpace(collectionName))
        {
            throw new ArgumentException("Collection name cannot be empty.", nameof(collectionName));
        }

        ConnectionString = connectionString;
        DatabaseName = databaseName;
        CollectionName = collectionName;
    }
}

// ============================================
// Repository Pattern
// ============================================
interface IBookmarkRepository
{
    Task InsertManyAsync(IEnumerable<Bookmark> bookmarks);
    Task<List<Bookmark>> GetAllAsync();
    Task<List<Bookmark>> GetByCategoryAsync(string category);
    Task<List<Bookmark>> GetByTagAsync(string tag);
    Task<Bookmark?> GetByTitleAsync(string title);
    Task<Bookmark?> GetByIdAsync(string id);
    Task UpdateAsync(Bookmark bookmark);
    Task DeleteByIdAsync(string id);
    Task DeleteAllAsync();
    Task<long> CountAsync();
}

class BookmarkRepository : IBookmarkRepository
{
    private readonly IMongoCollection<Bookmark> _collection;

    public BookmarkRepository(IMongoCollection<Bookmark> collection)
    {
        _collection = collection;
    }

    public Task InsertManyAsync(IEnumerable<Bookmark> bookmarks)
        => _collection.InsertManyAsync(bookmarks);

    public Task<List<Bookmark>> GetAllAsync()
        => _collection.Find(_ => true).ToListAsync();

    public Task<List<Bookmark>> GetByCategoryAsync(string category)
        => _collection.Find(b => b.Category == category).ToListAsync();

    public Task<List<Bookmark>> GetByTagAsync(string tag)
        => _collection.Find(b => b.Tags.Contains(tag)).ToListAsync();

    public Task<Bookmark?> GetByTitleAsync(string title)
        => _collection.Find(b => b.Title == title).FirstOrDefaultAsync();

    public Task<Bookmark?> GetByIdAsync(string id)
        => _collection.Find(b => b.Id == id).FirstOrDefaultAsync();

    public Task UpdateAsync(Bookmark bookmark)
        => _collection.ReplaceOneAsync(
            b => b.Id == bookmark.Id,
            bookmark);

    public Task DeleteByIdAsync(string id)
        => _collection.DeleteOneAsync(b => b.Id == id);

    public Task DeleteAllAsync()
        => _collection.DeleteManyAsync(_ => true);

    public Task<long> CountAsync()
        => _collection.CountDocumentsAsync(_ => true);
}