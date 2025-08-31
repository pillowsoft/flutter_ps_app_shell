# Migration Guide: From Existing Flutter Apps

This guide helps you migrate existing Flutter applications to use Flutter App Shell. The migration can be done incrementally, allowing you to adopt App Shell features gradually without rewriting your entire app.

## 🆕 InstantDB Migration (v0.3.0+)

**Breaking Change**: Flutter App Shell has migrated from ReaxDB to InstantDB for database operations. This provides real-time synchronization and built-in authentication.

### Key Changes:
- ✅ **Zero code generation** - No more `build_runner` commands needed
- ✅ **Faster development** - No waiting for generated files
- ✅ **Better performance** - 21,000+ writes/sec, 333,333 reads/sec
- ✅ **Built-in encryption** - AES-256 support included
- ✅ **Simpler setup** - Pure Dart implementation

### Migrating to InstantDB:
```dart
// Old Isar approach (with code generation)
@collection
class Document {
  Id id = Isar.autoIncrement;
  @Index()
  late String type;
  late String data;
}

// New InstantDB approach (schemaless)
class Document {
  int? id;
  String type;
  String data;
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'data': data,
  };
  
  factory Document.fromMap(Map<String, dynamic> map) => Document()
    ..id = map['id']
    ..type = map['type']
    ..data = map['data'];
}
```

### No More MobX or Code Generation:
- **Removed**: `mobx`, `flutter_mobx`, `mobx_codegen`, `build_runner`
- **Added**: `instantdb_flutter` (real-time database with auth)
- **State Management**: Use Signals exclusively (no code generation needed)

## 🎯 Migration Strategies

### Strategy 1: Incremental Adoption (Recommended)
- Add App Shell as a dependency
- Migrate one feature at a time
- Keep existing code working alongside new App Shell code
- Gradually replace existing implementations

### Strategy 2: Complete Migration
- Restructure the entire app to use App Shell patterns
- Best for smaller apps or major refactors
- Requires more upfront work but results in cleaner architecture

### Strategy 3: Hybrid Approach
- Use App Shell for new features only
- Keep existing features as-is
- Good for large, established apps with limited refactor time

### Strategy 4: Plugin-Based Migration
- Convert existing services to App Shell plugins
- Maintain backward compatibility through plugin interfaces
- Gradually migrate while keeping existing architecture
- Perfect for gradual modernization

## 📋 Pre-Migration Assessment

Before starting, evaluate your current app:

### Architecture Assessment
```dart
// Current app structure assessment checklist:

// ✅ State Management
// - What are you currently using? (Provider, Bloc, Riverpod, setState)
// - How complex is your state management?
// - Are you ready to migrate to Signals?

// ✅ Navigation
// - Using GoRouter, Navigator 1.0, or other solutions?
// - How many routes do you have?
// - Do you need responsive navigation?

// ✅ Services/Business Logic
// - Where is your business logic located?
// - Do you use dependency injection?
// - How are services structured?

// ✅ UI Components
// - Mostly Material, Cupertino, or custom widgets?
// - Do you need adaptive UI?
// - How much UI customization do you have?

// ✅ Data Management
// - What database/storage solutions are you using?
// - Do you need offline support?
// - Any cloud sync requirements?
```

## 🚀 Step-by-Step Migration

### Step 1: Add Flutter App Shell Dependency

Add App Shell to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Your existing dependencies...
  flutter_app_shell:
    git:
      url: https://github.com/your-org/flutter_ps_app_shell.git
      path: packages/flutter_app_shell
```

Run `flutter pub get` to install the dependency.

### Step 2: Initialize App Shell (Minimal Setup)

Create a minimal App Shell setup alongside your existing app:

```dart
// lib/app_shell_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'existing_app.dart'; // Your current app

class AppShellWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeAppShell(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        // Return your existing app wrapped with App Shell context
        return AppShellProvider(
          child: ExistingApp(), // Your current app
        );
      },
    );
  }
  
  Future<void> _initializeAppShell() async {
    // Initialize only basic services
    await AppShellCore.initialize(
      enableLogging: true,
      enablePreferences: true,
      // Don't enable other services yet
    );
  }
}

// Update main.dart
void main() {
  runApp(AppShellWrapper());
}
```

### Step 3: Migrate State Management Gradually

#### Option A: Coexist with Existing State Management

```dart
// Keep your existing state management working
class ExistingCounterProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Add new App Shell signal-based state alongside
class AppShellCounterService {
  final _count = signal(0);
  Signal<int> get count => _count;
  
  void increment() => _count.value++;
}

// Register both in your app
void main() {
  // Existing registration
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExistingCounterProvider(),
      child: AppShellWrapper(),
    ),
  );
  
  // Also register App Shell service
  getIt.registerSingleton<AppShellCounterService>(AppShellCounterService());
}
```

#### Option B: Migrate Existing State to Signals

```dart
// Before: Provider-based state
class CounterProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// After: Signal-based state
class CounterService {
  final _count = signal(0);
  Signal<int> get count => _count;
  
  void increment() => _count.value++;
}

// Migration helper to preserve existing widgets
class CounterProviderCompat extends ChangeNotifier {
  final CounterService _service = getIt<CounterService>();
  late final StreamSubscription _subscription;
  
  CounterProviderCompat() {
    _subscription = _service.count.watch().listen((_) {
      notifyListeners(); // Bridge signals to ChangeNotifier
    });
  }
  
  int get count => _service.count.value;
  void increment() => _service.increment();
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### Step 4: Migrate Navigation

#### From Navigator 1.0 to App Shell Navigation

```dart
// Before: Navigator 1.0
class ExistingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

// After: App Shell Navigation
class MigratedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppShellApp(
      config: AppConfig(
        title: 'My App',
        routes: [
          AppRoute(
            title: 'Home',
            path: '/',
            icon: Icons.home,
            builder: (context, state) => HomeScreen(),
          ),
          AppRoute(
            title: 'Profile', 
            path: '/profile',
            icon: Icons.person,
            builder: (context, state) => ProfileScreen(),
          ),
          AppRoute(
            title: 'Settings',
            path: '/settings',
            icon: Icons.settings,
            builder: (context, state) => SettingsScreen(),
          ),
        ],
      ),
    );
  }
}
```

#### From GoRouter to App Shell Navigation

```dart
// Before: GoRouter setup
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
  ],
);

class ExistingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

// After: App Shell (GoRouter is used internally)
class MigratedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppShellApp(
      config: AppConfig(
        title: 'My App',
        routes: [
          AppRoute(
            title: 'Home',
            path: '/',
            icon: Icons.home,
            builder: (context, state) => HomeScreen(),
          ),
          AppRoute(
            title: 'Profile',
            path: '/profile', 
            icon: Icons.person,
            builder: (context, state) => ProfileScreen(),
          ),
        ],
      ),
    );
  }
}

// Update navigation calls
// Before:
context.go('/profile');

// After:
getIt<NavigationService>().goToPath('/profile');
```

### Step 5: Migrate UI Components to Adaptive Widgets

#### Gradual Widget Migration

```dart
// Before: Platform-specific widgets
class ExistingForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Form')),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Name'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// After: Adaptive widgets
class MigratedForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      appBar: ui.appBar(title: Text('Form')),
      body: Column(
        children: [
          ui.textField(labelText: 'Name'),
          ui.button(
            label: 'Submit',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// Transition strategy: Create adaptive versions alongside existing
class FormV2 extends StatelessWidget {
  final bool useAdaptive;
  
  const FormV2({this.useAdaptive = false});
  
  @override
  Widget build(BuildContext context) {
    if (useAdaptive) {
      return _buildAdaptiveForm(context);
    } else {
      return _buildTraditionalForm(context);
    }
  }
  
  Widget _buildAdaptiveForm(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return ui.scaffold(/* adaptive implementation */);
  }
  
  Widget _buildTraditionalForm(BuildContext context) {
    return Scaffold(/* existing implementation */);
  }
}
```

### Step 6: Migrate Data Layer

#### From SharedPreferences to PreferencesService

```dart
// Before: Direct SharedPreferences usage
class SettingsManager {
  static const _keyThemeMode = 'theme_mode';
  
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.toString());
  }
  
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    // Manual parsing logic...
  }
}

// After: PreferencesService
class SettingsService {
  final PreferencesService _prefs = getIt<PreferencesService>();
  
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setEnum('theme_mode', mode);
  }
  
  Future<ThemeMode> getThemeMode() async {
    return await _prefs.getEnum('theme_mode', ThemeMode.system);
  }
  
  // Even better: Reactive preferences
  Signal<ThemeMode> get themeModeSignal => _prefs.getEnumSignal('theme_mode', ThemeMode.system);
}
```

#### From SQLite/Custom DB to DatabaseService

```dart
// Before: sqflite or custom database
class TodoDatabase {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  
  Future<List<Todo>> getTodos() async {
    final db = await database;
    final maps = await db.query('todos');
    return maps.map((map) => Todo.fromMap(map)).toList();
  }
  
  Future<void> insertTodo(Todo todo) async {
    final db = await database;
    await db.insert('todos', todo.toMap());
  }
}

// After: DatabaseService
class TodoService {
  final DatabaseService _db = getIt<DatabaseService>();
  
  Future<List<Todo>> getTodos() async {
    final documents = await _db.findByType('todos');
    return documents.map((doc) => Todo.fromDocument(doc)).toList();
  }
  
  Future<void> createTodo(Todo todo) async {
    await _db.create('todos', todo.toJson());
  }
  
  // Reactive queries
  Stream<List<Todo>> watchTodos() {
    return _db.watchByType('todos').map((documents) =>
        documents.map((doc) => Todo.fromDocument(doc)).toList());
  }
}
```

### Step 7: Migrate to Plugin Architecture (Optional)

Convert your existing services to plugins for better modularity:

```dart
// Before: Direct service registration
class MyAnalyticsService {
  static final instance = MyAnalyticsService._();
  MyAnalyticsService._();
  
  void track(String event) { /* ... */ }
}

// Register directly
getIt.registerSingleton<MyAnalyticsService>(MyAnalyticsService.instance);

// After: Plugin-based service
class AnalyticsPlugin extends BaseServicePlugin {
  @override
  String get id => 'com.myapp.analytics';
  
  @override
  String get name => 'Analytics Service';
  
  @override
  List<Type> get serviceTypes => [MyAnalyticsService];
  
  @override
  Future<void> registerServices(GetIt getIt) async {
    getIt.registerSingleton<MyAnalyticsService>(MyAnalyticsService.instance);
  }
}

// Register via plugin system
runShellApp(
  () async => AppConfig(...),
  enablePlugins: true,
  pluginConfiguration: {
    'manualPlugins': [AnalyticsPlugin()],
  },
);
```

**Benefits of Plugin Migration:**
- Better organization and modularity
- Health monitoring and status tracking
- Auto-discovery and dependency resolution
- Consistent initialization patterns
- Real-time debugging in Service Inspector

### Step 8: Add Cloud Sync (Optional)

If you want to add cloud sync capabilities:

```dart
// Initialize InstantDB service
final db = DatabaseService.instance;
// Automatically configured from environment variables
// Real-time sync enabled by default

// Your existing local data will automatically sync to cloud
// No changes needed to your service calls
final todos = await todoService.getTodos(); // Automatically syncs
```

## 🔧 Migration Helpers and Tools

### Compatibility Layers

Create compatibility layers to ease migration:

```dart
// Provider -> Signal compatibility
class SignalChangeNotifier<T> extends ChangeNotifier {
  final Signal<T> _signal;
  late final StreamSubscription _subscription;
  
  SignalChangeNotifier(this._signal) {
    _subscription = _signal.watch().listen((_) {
      notifyListeners();
    });
  }
  
  T get value => _signal.value;
  set value(T newValue) => _signal.value = newValue;
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Usage
final counterSignal = signal(0);
final counterNotifier = SignalChangeNotifier(counterSignal);

// Existing Provider widgets still work
ChangeNotifierProvider.value(
  value: counterNotifier,
  child: ExistingWidget(),
)
```

### Data Migration Utilities

```dart
// Migrate existing data to new format
class DataMigrationService {
  final DatabaseService _db = getIt<DatabaseService>();
  
  Future<void> migrateFromSQLite() async {
    // Read existing SQLite data
    final oldDatabase = await openDatabase('old_app.db');
    final oldTodos = await oldDatabase.query('todos');
    
    // Migrate to new format
    for (final todoMap in oldTodos) {
      await _db.create('todos', {
        'title': todoMap['title'],
        'completed': todoMap['completed'] == 1,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
          todoMap['created_at'] as int
        ).toIso8601String(),
      });
    }
    
    await oldDatabase.close();
  }
  
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsService = getIt<PreferencesService>();
    
    // Migrate settings
    final themeMode = prefs.getString('theme_mode');
    if (themeMode != null) {
      await prefsService.setString('theme_mode', themeMode);
      await prefs.remove('theme_mode');
    }
    
    // Migrate other preferences...
  }
}
```

## 📊 Migration Checklist

### Phase 1: Foundation
- [ ] Add Flutter App Shell dependency
- [ ] Initialize basic App Shell services
- [ ] Verify existing app still works
- [ ] Add basic logging and preferences

### Phase 2: Services
- [ ] Identify business logic in widgets
- [ ] Create App Shell services for core functionality
- [ ] Migrate state management to Signals
- [ ] Add service registration to main.dart

### Phase 3: Navigation
- [ ] Map existing routes to App Route format
- [ ] Update navigation calls to use NavigationService
- [ ] Test responsive navigation behavior
- [ ] Migrate deep linking if applicable

### Phase 4: UI Components
- [ ] Identify widgets that benefit from adaptive behavior
- [ ] Create adaptive versions of key components
- [ ] Test on different platforms (Material/Cupertino/ForUI)
- [ ] Update widget composition patterns

### Phase 5: Data Layer
- [ ] Migrate preferences to PreferencesService
- [ ] Migrate database to DatabaseService
- [ ] Add reactive data queries
- [ ] Test offline-first behavior

### Phase 6: Advanced Features
- [ ] Add cloud sync if needed
- [ ] Implement service inspector for debugging
- [ ] Add performance monitoring
- [ ] Set up comprehensive testing

### Phase 7: Cleanup
- [ ] Remove old dependencies
- [ ] Delete unused compatibility layers
- [ ] Update documentation
- [ ] Train team on new patterns

## 🚨 Common Migration Pitfalls

### 1. Trying to Migrate Everything at Once
```dart
// ❌ Bad - Big bang migration
void main() {
  // Trying to change everything at once
  runApp(CompletelyNewAppShellApp());
}

// ✅ Good - Gradual migration
void main() {
  runApp(
    AppShellWrapper(
      child: ExistingAppWithSomeNewFeatures(),
    ),
  );
}
```

### 2. Not Planning for Coexistence
```dart
// ❌ Bad - Assuming old and new can't coexist
class MyService {
  // Can only use new OR old, not both
}

// ✅ Good - Plan for transition period
class MyService {
  final bool _useAppShellPatterns;
  final OldStateManager? _oldState;
  final Signal<State>? _newState;
  
  MyService({bool useAppShell = false}) : _useAppShellPatterns = useAppShell {
    if (useAppShell) {
      _newState = signal(initialState);
    } else {
      _oldState = OldStateManager();
    }
  }
}
```

### 3. Ignoring Performance During Migration
```dart
// ❌ Bad - Creating wrapper layers that hurt performance
class PerformanceKillerWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Watch((context) { // Unnecessary reactive wrapper
      return Consumer<OldProvider>( // Old provider
        builder: (context, provider, child) {
          return ExpensiveWidget(); // Rebuilds too often
        },
      );
    });
  }
}

// ✅ Good - Efficient migration
class EfficientMigration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Choose one pattern, don't wrap both
    final useNewPattern = shouldUseNewPattern();
    
    if (useNewPattern) {
      return Watch((context) => NewWidget());
    } else {
      return Consumer<OldProvider>(
        builder: (context, provider, child) => OldWidget(),
      );
    }
  }
}
```

## 📈 Measuring Migration Success

### Metrics to Track
```dart
// Performance metrics
- App startup time
- Memory usage
- Widget rebuild frequency
- Navigation performance

// Code quality metrics
- Lines of code reduced
- Test coverage improvement
- Number of services created
- Dependency graph simplification

// User experience metrics
- Crash reduction
- Feature adoption
- User satisfaction
- Support ticket reduction
```

### Migration Progress Tracking
```dart
class MigrationTracker {
  static final metrics = {
    'total_widgets': 150,
    'adaptive_widgets': 45,     // 30% migrated
    'total_screens': 20,
    'app_shell_screens': 8,     // 40% migrated
    'old_state_management': 12,
    'new_state_management': 8,  // 40% migrated
  };
  
  static double get adaptiveUIProgress => 
      metrics['adaptive_widgets']! / metrics['total_widgets']!;
      
  static double get stateManagementProgress =>
      metrics['new_state_management']! / 
      (metrics['old_state_management']! + metrics['new_state_management']!);
}
```

## 🔗 Additional Resources

- **[Getting Started Guide](getting-started.md)** - Basic App Shell setup
- **[Architecture Overview](architecture.md)** - Understanding App Shell patterns
- **[Common Patterns](examples/patterns.md)** - Implementation examples
- **[Best Practices](reference/best-practices.md)** - Recommended approaches
- **[Troubleshooting](reference/troubleshooting.md)** - Common issues and solutions

Remember: migration is a journey, not a destination. Take it one step at a time, and don't be afraid to keep what works while gradually adopting what's better! 🚀