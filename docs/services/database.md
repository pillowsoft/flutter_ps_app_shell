# Database Service

The Database Service provides a powerful NoSQL document database with reactive queries, cloud synchronization, and offline-first architecture. Built on **InstantDB** for real-time local storage with automatic cloud sync.

## 🚀 Quick Start

### Basic Usage
```dart
final db = getIt<DatabaseService>();

// Create a document
final todoId = await db.create('todos', {
  'title': 'Buy groceries',
  'completed': false,
  'dueDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
});

// Find documents
final todos = await db.findByType('todos');

// Update a document
await db.update(todoId, {
  'completed': true,
});

// Delete a document
await db.delete(todoId);
```

### Reactive Queries
```dart
// Watch for changes in real-time
db.watchByType('todos').listen((documents) {
  print('Todos updated: ${documents.length} items');
});

// Use in UI with StreamBuilder
StreamBuilder<List<Map<String, dynamic>>>(
  stream: db.watchByType('todos'),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final todos = snapshot.data!;
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return ListTile(
          title: Text(todo['title']),
          trailing: Checkbox(
            value: todo['completed'] ?? false,
            onChanged: (value) => _toggleTodo(todo['_id'], value),
          ),
        );
      },
    );
  },
)
```

## 📊 Document Model

### Document Structure
```dart
class Document {
  int? id;                   // Unique identifier
  String type;               // Document type (e.g., 'todos', 'users')  
  String data;               // JSON data as string
  List<String> tags;         // Optional tags for categorization
  DateTime createdAt;        // Creation timestamp
  DateTime updatedAt;        // Last update timestamp
  int version;               // Version number for conflict resolution
  bool isDeleted;            // Soft delete flag
}
```

### Creating Documents
```dart
// Simple document
final id = await db.create('notes', {
  'title': 'My Note',
  'content': 'Note content here',
});

// Document with tags
final id = await db.create('articles', {
  'title': 'Flutter Best Practices',
  'content': 'Article content...',
}, tags: ['flutter', 'development', 'mobile']);
```

## 🔍 Querying Data

### Basic Queries
```dart
// Find all documents of a type
final allTodos = await db.findByType('todos');

// Find by ID
final todo = await db.read(todoId);

// Find with limit and offset
final recentTodos = await db.findByType('todos', limit: 10, offset: 0);
```

### Advanced Queries
```dart
// Find by tags
final flutterArticles = await db.findByTag('flutter');

// Count documents by type
final todoCount = await db.countByType('todos');

// Get all document types
final types = await db.getTypes();

// Clear all documents of a type
final deletedCount = await db.clearType('old_logs');
```

### Reactive Queries
```dart
// Watch all documents of a type
Stream<List<Map<String, dynamic>>> todoStream = db.watchByType('todos');
```

## 📝 CRUD Operations

### Create
```dart
// Basic creation
final id = await db.create('todos', {
  'title': 'New Task',
  'completed': false,
});

// With tags
final id = await db.create('projects', {
  'name': 'Flutter App',
  'description': 'My awesome app',
  'status': 'active',
}, tags: ['work', 'flutter']);
```

### Read
```dart
// Single document
final doc = await db.read(todoId);
if (doc != null) {
  print('Title: ${doc['title']}');
  print('Type: ${doc['_type']}');
  print('Created: ${doc['_createdAt']}');
}
```

### Update
```dart
// Partial update
await db.update(todoId, {
  'completed': true,
  'completedAt': DateTime.now().toIso8601String(),
});

// Update with tags
await db.update(todoId, {
  'priority': 'high',
}, tags: ['urgent', 'work']);
```

### Delete
```dart
// Soft delete (marks as deleted, keeps data)
await db.delete(todoId);

// Hard delete (permanently removes)
await db.hardDelete(todoId);
```

## ☁️ Real-time Synchronization

### Automatic Cloud Sync
InstantDB automatically handles cloud synchronization:
```dart
// Initialize with InstantDB (automatic from environment)
await db.initialize(
  appId: dotenv.env['INSTANTDB_APP_ID'],
  enableSync: true,
);
```

### Real-time Updates
```dart
// All changes sync automatically across clients
final id = await db.create('todos', {
  'title': 'New Task',
  'completed': false,
});

// Changes are immediately visible to all connected clients
// No manual sync operations needed!
```

### Built-in Conflict Resolution
InstantDB uses operational transforms for automatic conflict resolution:
- **Optimistic updates** - Changes appear immediately in UI
- **Automatic conflict resolution** - No manual intervention needed
- **Real-time synchronization** - All clients stay in sync
- **Offline-first** - Works seamlessly when disconnected

### Connection Monitoring
```dart
// Watch connection status with Signals
Watch((context) {
  final status = db.connectionStatus.value;
  
  return Row(
    children: [
      Icon(
        status == DatabaseConnectionStatus.connected 
          ? Icons.cloud_done 
          : Icons.cloud_off,
        color: status == DatabaseConnectionStatus.connected
          ? Colors.green
          : Colors.grey,
      ),
      Text('InstantDB: ${status.toString().split('.').last}'),
    ],
  );
});
```

## 🚀 Performance & Optimization

### InstantDB Features
InstantDB provides real-time NoSQL storage:
- **Real-time sync** - Changes propagate instantly to all connected clients
- **Offline-first** - Works seamlessly without internet connection  
- **Local caching** - Fast local queries with automatic cloud sync
- **Zero code generation** - No build_runner or generated files needed
- **Built-in authentication** - Magic links and social auth included
- **Schemaless** - No database migrations or schema changes needed

### Database Statistics
```dart
// Get detailed statistics
final stats = await db.getStats();
print('Total documents: ${stats.totalDocuments}');
print('Active documents: ${stats.activeDocuments}');
print('Deleted documents: ${stats.deletedDocuments}');
print('Document types: ${stats.documentTypes}');
print('Database size: ${stats.databaseSizeMB}MB');
```

## 🧪 Testing

### Test Database
```dart
void main() {
  late DatabaseService db;
  
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = DatabaseService.instance;
    await db.initialize();
  });
  
  test('should create and retrieve document', () async {
    final id = await db.create('todos', {
      'title': 'Test Todo',
      'completed': false,
    });
    
    final doc = await db.read(id);
    expect(doc, isNotNull);
    expect(doc!['title'], equals('Test Todo'));
    expect(doc['completed'], equals(false));
  });
  
  tearDown(() async {
    await db.close();
  });
}
```

## 🔧 Configuration

### Initialization Options
```dart
await db.initialize(
  // Automatic configuration from .env file
  appId: dotenv.env['INSTANTDB_APP_ID'],
  enableSync: dotenv.env['INSTANTDB_ENABLE_SYNC'] != 'false',
  verboseLogging: dotenv.env['INSTANTDB_VERBOSE_LOGGING'] == 'true',
);
```

### Connection Status
```dart
// Monitor database connection status with Signals
Watch((context) {
  final status = db.connectionStatus.value;
  
  return switch (status) {
    DatabaseConnectionStatus.connected => Icon(Icons.check_circle, color: Colors.green),
    DatabaseConnectionStatus.connecting => CircularProgressIndicator(),
    DatabaseConnectionStatus.error => Icon(Icons.error, color: Colors.red),
    DatabaseConnectionStatus.disconnected => Icon(Icons.offline_bolt),
  };
});
```

## 📊 Monitoring & Debugging

### Service Inspector Integration
The Database Service integrates with the Service Inspector for real-time monitoring:

- **Document counts** by type
- **Sync status** and last sync time
- **Connection status** monitoring
- **Error logs** and debugging information
- **Interactive testing** - create, update, delete documents

### Real-time Signals
The DatabaseService uses Signals for reactive status updates:
```dart
// Connection status
final connectionStatus = signal<DatabaseConnectionStatus>(DatabaseConnectionStatus.disconnected);

// Cloud sync status  
final cloudSyncStatus = signal<CloudSyncStatus>(CloudSyncStatus.disabled);

// Last sync timestamp
final lastSyncTime = signal<DateTime?>(null);

// Real-time updates counter
final realtimeUpdates = signal<int>(0);
```

## 🎯 Key Advantages of InstantDB

### Real-time Database
Unlike traditional databases, InstantDB provides **real-time synchronization**:
- ❌ No manual polling for updates
- ❌ No complex sync logic to implement
- ❌ No schema migrations to manage
- ✅ Automatic real-time updates across all clients
- ✅ Offline-first with automatic sync when reconnected
- ✅ Built-in authentication and permissions

### Document Structure
```dart
// InstantDB approach (schemaless, no setup required)
final doc = await db.create('todos', {
  'title': 'My Todo',
  'completed': false,
  'tags': ['work', 'urgent'],
  'metadata': {
    'priority': 'high',
    'assignee': 'user123'
  }
});

// Query in real-time
db.watchByType('todos').listen((docs) {
  // UI automatically updates when data changes
  // on any connected client!
});
```

## 🔗 Related Documentation

- **[Services Overview](README.md)** - Overview of all services
- **[Architecture](../architecture.md)** - How Database Service fits in the overall architecture
- **[Migration Guide](../migration-guide.md)** - Migrating to InstantDB

The Database Service provides a powerful, flexible foundation for your app's data needs. Start with simple local storage and gradually add cloud sync and advanced features as your app grows! 🗄️