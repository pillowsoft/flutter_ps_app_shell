# Best Practices & Guidelines

This guide provides recommendations, best practices, and common pitfalls to avoid when building applications with Flutter App Shell. Following these guidelines will help you build maintainable, performant, and user-friendly applications.

## 🎯 Core Principles

### 1. Service-First Architecture
Always think in terms of services and separation of concerns:

```dart
// ✅ Good - Business logic in service
class TodoService {
  final DatabaseService _db = getIt<DatabaseService>();
  
  Future<List<Todo>> getTodos() async {
    final documents = await _db.findByType('todos');
    return documents.map((doc) => Todo.fromDocument(doc)).toList();
  }
  
  Future<void> createTodo(String title) async {
    await _db.create('todos', {
      'title': title,
      'completed': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

// ❌ Bad - Business logic in widget
class TodoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = getIt<DatabaseService>();
    
    return FutureBuilder(
      future: db.findByType('todos').then((documents) {
        // Business logic mixed with UI
        return documents
            .where((doc) => !doc.isDeleted)
            .map((doc) => Todo.fromDocument(doc))
            .toList();
      }),
      builder: (context, snapshot) { /* ... */ },
    );
  }
}
```

### 2. Reactive State Management
Use Signals consistently for reactive state:

```dart
// ✅ Good - Reactive with Signals
class CounterService {
  final _count = signal(0);
  Signal<int> get count => _count;
  
  void increment() => _count.value++;
  void decrement() => _count.value--;
}

// UI automatically updates
Watch((context) => Text('Count: ${counterService.count.value}'))

// ❌ Bad - Manual state management
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;
  
  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count'); // Won't update from other widgets
  }
}
```

### 3. Adaptive UI First
Always use the adaptive widget factory:

```dart
// ✅ Good - Adaptive UI
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      body: ui.button(
        label: 'Adaptive Button',
        onPressed: () {},
      ),
    );
  }
}

// ❌ Bad - Platform-specific UI
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton( // Won't adapt to UI system changes
        onPressed: () {},
        child: Text('Platform Button'),
      ),
    );
  }
}
```

## 🏗️ Architecture Best Practices

### Service Organization
```dart
// ✅ Good - Clear service boundaries
class UserService {
  // Only user-related operations
  Future<User> getCurrentUser() async { /* */ }
  Future<void> updateProfile(UserProfile profile) async { /* */ }
  Future<void> uploadAvatar(File image) async { /* */ }
}

class TodoService {
  // Only todo-related operations
  Future<List<Todo>> getTodos() async { /* */ }
  Future<void> createTodo(Todo todo) async { /* */ }
  Future<void> updateTodo(String id, Todo todo) async { /* */ }
}

// ❌ Bad - Mixed responsibilities
class DataService {
  // Too many responsibilities in one service
  Future<User> getCurrentUser() async { /* */ }
  Future<List<Todo>> getTodos() async { /* */ }
  Future<void> sendEmail(String to, String subject) async { /* */ }
  Future<void> uploadFile(File file) async { /* */ }
}
```

### Service Dependencies
```dart
// ✅ Good - Clear dependencies through constructor or getter
class UserService {
  final DatabaseService _db = getIt<DatabaseService>();
  final AuthenticationService _auth = getIt<AuthenticationService>();
  
  Future<User?> getCurrentUser() async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null) return null;
    
    final doc = await _db.findById('users', userId);
    return doc != null ? User.fromDocument(doc) : null;
  }
}

// ❌ Bad - Hidden dependencies
class UserService {
  Future<User?> getCurrentUser() async {
    // Hidden dependency on getIt
    final auth = getIt<AuthenticationService>();
    final db = getIt<DatabaseService>();
    // This makes testing harder and dependencies unclear
  }
}
```

### Error Handling
```dart
// ✅ Good - Consistent error handling with proper logging
class TodoService {
  static final Logger _logger = createServiceLogger('TodoService');
  
  Future<List<Todo>> getTodos() async {
    try {
      _logger.fine('Fetching todos');
      final documents = await _db.findByType('todos');
      _logger.info('Fetched ${documents.length} todos');
      return documents.map((doc) => Todo.fromDocument(doc)).toList();
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch todos', e, stackTrace);
      throw TodoServiceException('Unable to load todos', e);
    }
  }
}

// Custom exception types
class TodoServiceException implements Exception {
  final String message;
  final dynamic cause;
  
  TodoServiceException(this.message, [this.cause]);
  
  @override
  String toString() => 'TodoServiceException: $message';
}

// ❌ Bad - Silent failures or generic exceptions
class TodoService {
  Future<List<Todo>> getTodos() async {
    try {
      final documents = await _db.findByType('todos');
      return documents.map((doc) => Todo.fromDocument(doc)).toList();
    } catch (e) {
      print('Error: $e'); // Poor logging - use proper logger instead
      return []; // Silent failure
    }
  }
}
```

## 🎨 UI Best Practices

### Responsive Design
```dart
// ✅ Good - Responsive design with adaptive breakpoints
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _MobileLayout();
        } else if (constraints.maxWidth < 1200) {
          return _TabletLayout();
        } else {
          return _DesktopLayout();
        }
      },
    );
  }
}

// ❌ Bad - Fixed layout that doesn't adapt
class FixedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row( // Always horizontal, even on small screens
      children: [
        Container(width: 300, child: Sidebar()),
        Expanded(child: Content()),
      ],
    );
  }
}
```

### State Management in UI
```dart
// ✅ Good - Separate presentation from business logic
class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todoService = getIt<TodoService>();
    final ui = getAdaptiveFactory(context);
    
    return Watch((context) {
      final todos = todoService.todos.value;
      final isLoading = todoService.isLoading.value;
      
      if (isLoading) {
        return ui.scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      return ui.scaffold(
        body: ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) => TodoTile(todo: todos[index]),
        ),
      );
    });
  }
}

// ❌ Bad - Mixed state and business logic in widget
class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadTodos(); // Business logic in widget
  }
  
  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final db = getIt<DatabaseService>();
    final documents = await db.findByType('todos');
    setState(() {
      _todos = documents.map((doc) => Todo.fromDocument(doc)).toList();
      _isLoading = false;
    });
  }
}
```

### Widget Composition
```dart
// ✅ Good - Small, focused, reusable widgets
class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  
  const TodoTile({
    Key? key,
    required this.todo,
    this.onToggle,
    this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.listTile(
      title: Text(todo.title),
      leading: ui.checkbox(
        value: todo.completed,
        onChanged: onToggle != null ? (_) => onToggle!() : null,
      ),
      trailing: onDelete != null
          ? ui.iconButton(
              icon: Icon(Icons.delete),
              onPressed: onDelete,
            )
          : null,
    );
  }
}

// ❌ Bad - Large, monolithic widgets
class TodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(/* complex app bar logic */),
      body: Column(
        children: [
          Container(/* complex header */),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                // All todo tile logic inline
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(/* inline logic */),
                      Expanded(child: Text(/* complex text logic */)),
                      IconButton(/* inline delete logic */),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(/* complex footer */),
        ],
      ),
    );
  }
}
```

## 📊 Data Management Best Practices

### Local-First with Cloud Sync
```dart
// ✅ Good - Local-first approach
class ArticleService {
  final DatabaseService _db = getIt<DatabaseService>();
  final NetworkService _network = getIt<NetworkService>();
  
  Future<List<Article>> getArticles({bool forceRefresh = false}) async {
    // 1. Always return local data first
    final localArticles = await _db.findByType('articles');
    
    if (localArticles.isNotEmpty && !forceRefresh) {
      // Return local data immediately, sync in background
      _syncInBackground();
      return localArticles.map((doc) => Article.fromDocument(doc)).toList();
    }
    
    // 2. If no local data or force refresh, try network
    try {
      return await _fetchFromNetwork();
    } catch (e) {
      // 3. Network failed, return local data as fallback
      return localArticles.map((doc) => Article.fromDocument(doc)).toList();
    }
  }
  
  Future<void> _syncInBackground() async {
    try {
      await _fetchFromNetwork();
    } catch (e) {
      // Background sync failed, but that's OK
      print('Background sync failed: $e');
    }
  }
}

// ❌ Bad - Network-first approach
class ArticleService {
  Future<List<Article>> getArticles() async {
    try {
      // Always hits network first, slow and unreliable
      final response = await _network.get('/articles');
      return (response.data as List)
          .map((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      // No fallback to local data
      throw Exception('Failed to load articles');
    }
  }
}
```

### Data Validation
```dart
// ✅ Good - Validate data at service boundaries
class UserService {
  Future<void> createUser(User user) async {
    // Validate before saving
    _validateUser(user);
    
    await _db.create('users', user.toJson());
  }
  
  void _validateUser(User user) {
    if (user.email.isEmpty) {
      throw ValidationException('Email is required');
    }
    
    if (!user.email.contains('@')) {
      throw ValidationException('Invalid email format');
    }
    
    if (user.name.length < 2) {
      throw ValidationException('Name must be at least 2 characters');
    }
  }
}

// ❌ Bad - No validation or validation in wrong place
class UserService {
  Future<void> createUser(User user) async {
    // No validation - invalid data reaches database
    await _db.create('users', user.toJson());
  }
}

// UI should not be the only validation layer
class UserForm extends StatelessWidget {
  Widget build(BuildContext context) {
    return TextFormField(
      validator: (value) {
        // Validation only in UI - can be bypassed
        if (value?.isEmpty ?? true) return 'Email required';
        return null;
      },
    );
  }
}
```

### Optimistic Updates
```dart
// ✅ Good - Optimistic updates with rollback
class TodoService {
  final _todos = signal<List<Todo>>([]);
  
  Future<void> toggleTodo(String todoId) async {
    final todos = _todos.value;
    final todoIndex = todos.indexWhere((t) => t.id == todoId);
    if (todoIndex == -1) return;
    
    final originalTodo = todos[todoIndex];
    final updatedTodo = originalTodo.copyWith(completed: !originalTodo.completed);
    
    // Optimistic update - update UI immediately
    final updatedTodos = List<Todo>.from(todos);
    updatedTodos[todoIndex] = updatedTodo;
    _todos.value = updatedTodos;
    
    try {
      // Persist to storage
      await _db.update('todos', todoId, updatedTodo.toJson());
      
      // Sync to cloud if available
      await _syncToCloud(updatedTodo);
    } catch (e) {
      // Rollback on failure
      _todos.value = todos;
      throw TodoUpdateException('Failed to update todo');
    }
  }
}

// ❌ Bad - No optimistic updates, slow UX
class TodoService {
  Future<void> toggleTodo(String todoId) async {
    try {
      // Update storage first - UI waits
      await _db.update('todos', todoId, {'completed': true});
      
      // Sync to cloud - UI still waiting
      await _network.put('/todos/$todoId', {'completed': true});
      
      // Finally update UI
      _loadTodos();
    } catch (e) {
      // Error - no visual feedback until this point
      throw Exception('Update failed');
    }
  }
}
```

## 🚀 Performance Best Practices

### Efficient List Rendering
```dart
// ✅ Good - Efficient list with keys and minimal rebuilds
class TodoList extends StatelessWidget {
  final List<Todo> todos;
  
  const TodoList({Key? key, required this.todos}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoTile(
          key: ValueKey(todo.id), // Stable key for animations
          todo: todo,
        );
      },
    );
  }
}

class TodoTile extends StatelessWidget {
  final Todo todo;
  
  const TodoTile({Key? key, required this.todo}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Minimal, focused widget that only rebuilds when todo changes
    return ListTile(
      title: Text(todo.title),
      leading: Checkbox(
        value: todo.completed,
        onChanged: (_) => _toggleTodo(todo.id),
      ),
    );
  }
}

// ❌ Bad - Inefficient list rendering
class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  @override
  Widget build(BuildContext context) {
    final todoService = getIt<TodoService>();
    
    return Watch((context) {
      final todos = todoService.todos.value;
      
      return Column(
        children: todos.map((todo) {
          // No keys - poor animation performance
          // New widget instance on every rebuild
          return ListTile(
            title: Text(todo.title),
            leading: Checkbox(
              value: todo.completed,
              onChanged: (_) {
                // Inline logic causes entire list to rebuild
                todoService.toggleTodo(todo.id);
              },
            ),
          );
        }).toList(),
      );
    });
  }
}
```

### Memory Management
```dart
// ✅ Good - Proper disposal of resources
class ImageGalleryService {
  final List<ImageProvider> _imageCache = [];
  StreamSubscription? _subscription;
  
  void initialize() {
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }
  
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    
    // Clear image cache
    for (final provider in _imageCache) {
      provider.evict();
    }
    _imageCache.clear();
  }
}

// ❌ Bad - Memory leaks
class ImageGalleryService {
  final List<ImageProvider> _imageCache = [];
  StreamSubscription? _subscription;
  
  void initialize() {
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }
  
  // No dispose method - memory leak
}
```

### Efficient Signals Usage
```dart
// ✅ Good - Granular signals
class UserService {
  final _name = signal('');
  final _email = signal('');
  final _avatar = signal<String?>(null);
  
  Signal<String> get name => _name;
  Signal<String> get email => _email;
  Signal<String?> get avatar => _avatar;
  
  // Each property can be watched independently
}

// UI only rebuilds when specific property changes
Watch((context) => Text(userService.name.value)) // Only rebuilds when name changes
Watch((context) => Text(userService.email.value)) // Only rebuilds when email changes

// ❌ Bad - Coarse-grained signals
class UserService {
  final _user = signal<User?>(null);
  Signal<User?> get user => _user;
  
  void updateName(String newName) {
    final currentUser = _user.value;
    if (currentUser != null) {
      // Entire user object changes - all watchers rebuild
      _user.value = currentUser.copyWith(name: newName);
    }
  }
}

// All UI watching user rebuilds even for small changes
Watch((context) {
  final user = userService.user.value;
  return Column(
    children: [
      Text(user?.name ?? ''), // Rebuilds when ANY user property changes
      Text(user?.email ?? ''), // Rebuilds when ANY user property changes
      UserAvatar(url: user?.avatar), // Rebuilds when ANY user property changes
    ],
  );
})
```

## 🧪 Testing Best Practices

### Service Testing
```dart
// ✅ Good - Isolated service testing with mocks
void main() {
  group('TodoService', () {
    late TodoService todoService;
    late MockDatabaseService mockDb;
    late MockNetworkService mockNetwork;
    
    setUp(() {
      mockDb = MockDatabaseService();
      mockNetwork = MockNetworkService();
      
      // Register mocks
      getIt.registerSingleton<DatabaseService>(mockDb);
      getIt.registerSingleton<NetworkService>(mockNetwork);
      
      todoService = TodoService();
    });
    
    tearDown(() {
      getIt.reset();
    });
    
    test('should create todo and save to database', () async {
      // Arrange
      when(mockDb.create(any, any)).thenAnswer((_) async => 'todo-id');
      
      // Act
      await todoService.createTodo('Test Todo');
      
      // Assert
      verify(mockDb.create('todos', {
        'title': 'Test Todo',
        'completed': false,
        'createdAt': any,
      })).called(1);
    });
  });
}

// ❌ Bad - Testing with real dependencies
void main() {
  test('should create todo', () async {
    final todoService = TodoService();
    
    // Uses real database and network - slow, unreliable, affects other tests
    await todoService.createTodo('Test Todo');
    
    // Hard to verify what actually happened
    expect(true, true); // Weak assertion
  });
}
```

### Widget Testing
```dart
// ✅ Good - Widget testing with service mocks
void main() {
  testWidgets('TodoList should display todos', (tester) async {
    // Arrange
    final mockTodoService = MockTodoService();
    when(mockTodoService.todos).thenReturn(signal([
      Todo(id: '1', title: 'Test Todo 1', completed: false),
      Todo(id: '2', title: 'Test Todo 2', completed: true),
    ]));
    
    await tester.pumpWidget(
      TestApp(
        services: {'TodoService': mockTodoService},
        child: TodoListScreen(),
      ),
    );
    
    // Assert
    expect(find.text('Test Todo 1'), findsOneWidget);
    expect(find.text('Test Todo 2'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });
}

// ❌ Bad - Widget testing without proper setup
void main() {
  testWidgets('TodoList test', (tester) async {
    await tester.pumpWidget(TodoListScreen()); // No service setup - will crash
    
    expect(find.byType(TodoListScreen), findsOneWidget); // Weak test
  });
}
```

## 🔒 Security Best Practices

### Input Validation
```dart
// ✅ Good - Server-side style validation
class UserService {
  Future<void> updateEmail(String email) async {
    // Always validate inputs
    if (!_isValidEmail(email)) {
      throw ValidationException('Invalid email format');
    }
    
    // Sanitize if needed
    final sanitizedEmail = email.trim().toLowerCase();
    
    await _db.update('users', _currentUserId, {
      'email': sanitizedEmail,
    });
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}

// ❌ Bad - Trusting client-side validation only
class UserService {
  Future<void> updateEmail(String email) async {
    // No validation - trusts input
    await _db.update('users', _currentUserId, {
      'email': email, // Could be malicious
    });
  }
}
```

### Sensitive Data Handling
```dart
// ✅ Good - Proper sensitive data handling
class AuthenticationService {
  Future<void> storeAuthToken(String token) async {
    // Use secure storage for sensitive data
    await _secureStorage.write(key: 'auth_token', value: token);
    
    // Never log sensitive data
    _logger.info('Auth token stored successfully');
  }
  
  Future<void> signOut() async {
    // Clear sensitive data on sign out
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    
    // Clear any cached user data
    _currentUser.value = null;
  }
}

// ❌ Bad - Insecure data handling
class AuthenticationService {
  Future<void> storeAuthToken(String token) async {
    // Storing sensitive data in regular preferences
    await _prefs.setString('auth_token', token);
    
    // Logging sensitive data
    _logger.fine('Stored token: $token'); // NEVER DO THIS
  }
}
```

## 📋 Code Organization

### File Structure
```
lib/
├── services/           # Business logic services
│   ├── todo_service.dart
│   ├── user_service.dart
│   └── notification_service.dart
├── models/            # Data models
│   ├── todo.dart
│   ├── user.dart
│   └── notification.dart
├── screens/           # UI screens
│   ├── todo/
│   │   ├── todo_list_screen.dart
│   │   ├── todo_detail_screen.dart
│   │   └── widgets/
│   │       ├── todo_tile.dart
│   │       └── todo_form.dart
│   └── user/
│       ├── profile_screen.dart
│       └── settings_screen.dart
├── utils/             # Utilities and helpers
│   ├── validators.dart
│   ├── constants.dart
│   └── extensions.dart
└── main.dart
```

### Import Organization
```dart
// ✅ Good - Organized imports
// Dart imports
import 'dart:async';
import 'dart:io';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:get_it/get_it.dart';

// Project imports
import '../models/todo.dart';
import '../services/todo_service.dart';
import 'widgets/todo_tile.dart';

// ❌ Bad - Disorganized imports
import '../services/todo_service.dart';
import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'widgets/todo_tile.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
```

## 🚨 Common Pitfalls to Avoid

### 1. Mixing UI and Business Logic
```dart
// ❌ Bad
class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];
  
  @override
  void initState() {
    super.initState();
    _loadTodos(); // Business logic in widget
  }
  
  Future<void> _loadTodos() async {
    final db = getIt<DatabaseService>();
    final documents = await db.findByType('todos');
    
    // Business logic in widget
    final todos = documents
        .where((doc) => !doc.isDeleted)
        .map((doc) => Todo.fromDocument(doc))
        .where((todo) => todo.isActive)
        .toList();
    
    setState(() => _todos = todos);
  }
}
```

### 2. Not Using Adaptive UI
```dart
// ❌ Bad - Platform-specific widgets
return Scaffold(
  body: Column(
    children: [
      ElevatedButton(onPressed: () {}, child: Text('Submit')),
      TextField(decoration: InputDecoration(labelText: 'Name')),
    ],
  ),
);

// ✅ Good - Adaptive widgets
final ui = getAdaptiveFactory(context);
return ui.scaffold(
  body: Column(
    children: [
      ui.button(label: 'Submit', onPressed: () {}),
      ui.textField(labelText: 'Name'),
    ],
  ),
);
```

### 3. Forgetting Watch Widgets
```dart
// ❌ Bad - Won't update when signal changes
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = getIt<CounterService>();
    return Text('Count: ${counter.count.value}'); // Static value
  }
}

// ✅ Good - Reactive to signal changes
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = getIt<CounterService>();
    return Watch((context) => Text('Count: ${counter.count.value}'));
  }
}
```

### 4. Memory Leaks with Streams
```dart
// ❌ Bad - Stream subscription not cancelled
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    someStream.listen((data) {
      // Handle data
    }); // Subscription never cancelled - memory leak
  }
}

// ✅ Good - Proper subscription management
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## 🔗 Related Resources

- **[Getting Started](../getting-started.md)** - Basic setup and first app
- **[Architecture Overview](../architecture.md)** - Understanding the framework
- **[Common Patterns](../examples/patterns.md)** - Practical implementation examples
- **[Testing Guide](../advanced/testing.md)** - Comprehensive testing strategies
- **[Performance Guide](../advanced/performance.md)** - Optimization techniques

Following these best practices will help you build maintainable, performant, and reliable Flutter applications with App Shell. Remember: good architecture and patterns are more important than clever code! 🚀