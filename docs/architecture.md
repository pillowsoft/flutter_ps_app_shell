# Architecture Overview

Flutter App Shell is built with a clean, modular architecture that separates concerns and makes your app scalable, testable, and maintainable. This guide explains the core architectural principles and how everything fits together.

## 🏗️ Core Architecture Principles

### 1. Service-Oriented Architecture (SOA)
All business logic lives in services that are:
- **Singleton instances** managed by GetIt dependency injection
- **Loosely coupled** with clear interfaces
- **Independently testable** with mock implementations
- **Reactive** using Signals for state updates

### 2. Adaptive UI System
The UI layer adapts to different design systems:
- **Abstract factory pattern** for platform-agnostic components
- **Runtime switching** between Material, Cupertino, and ForUI
- **Responsive layouts** that adapt to screen size
- **Consistent API** across all platforms

### 3. Reactive State Management
State flows through the app using:
- **Signals** as the primary reactive primitive
- **Watch widgets** for automatic UI updates
- **Immutable state** for predictable behavior
- **Granular reactivity** for optimal performance

### 4. Plugin System Architecture
Extensible framework through plugins:
- **Four plugin types** for different extension needs
- **Auto-discovery** from dependencies and directories
- **Dependency resolution** with automatic loading order
- **Type-safe contracts** for all plugin interactions
- **Health monitoring** and real-time status tracking

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Plugin Extension Layer                 │
├─────────────────────────────────────────────────────────────┤
│  Service Plugins     │  Widget Plugins      │  Theme/Work  │
│  ┌─────────────────┐  │  ┌─────────────────┐  │ ┌──────────┐ │
│  │ Analytics       │  │  │ Charts          │  │ │ Custom   │ │
│  │ Payment         │  │  │ Rich Editors    │  │ │ Themes   │ │
│  │ Custom APIs     │  │  │ Media Players   │  │ │ Workflows│ │
│  └─────────────────┘  │  └─────────────────┘  │ └──────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      Presentation Layer                     │
├─────────────────────────────────────────────────────────────┤
│  Adaptive UI System  │  Screens & Widgets  │  Navigation   │
│  ┌─────────────────┐  │  ┌─────────────────┐ │ ┌──────────┐  │
│  │ Material        │  │  │ Home Screen     │ │ │ GoRouter │  │
│  │ Cupertino       │  │  │ Settings Screen │ │ │ Responsive│  │
│  │ ForUI           │  │  │ Profile Screen  │ │ │ Layout   │  │
│  └─────────────────┘  │  └─────────────────┘ │ └──────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      Business Logic Layer                   │
├─────────────────────────────────────────────────────────────┤
│  State Management    │      Services         │  Plugin Mgr  │
│  ┌─────────────────┐  │  ┌─────────────────┐  │ ┌──────────┐ │
│  │ Signals         │  │  │ DatabaseService │  │ │ Manager  │ │
│  │ Watch Widgets   │  │  │ AuthService     │  │ │ Registry │ │
│  │ Settings Store  │  │  │ NetworkService  │  │ │ Discovery│ │
│  └─────────────────┘  │  │ PrefsService    │  │ └──────────┘ │
│                       │  │ NavigationSvc   │  │              │
│                       │  └─────────────────┘  │              │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                           │
├─────────────────────────────────────────────────────────────┤
│   Local Storage      │    Cloud Services     │   Models     │
│  ┌─────────────────┐  │  ┌─────────────────┐  │ ┌──────────┐ │
│  │ InstantDB NoSQL │  │  │ InstantDB       │  │ │ Data     │ │
│  │ SharedPrefs     │  │  │ Real-time Sync  │  │ │ Models   │ │
│  │ File System     │  │  │ WebSockets      │  │ │ DTOs     │ │
│  └─────────────────┘  │  └─────────────────┘  │ └──────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### Service Locator (GetIt)
The backbone of dependency injection:

```dart
// Registration (happens in runShellApp)
getIt.registerSingleton<DatabaseService>(DatabaseService.instance);
getIt.registerSingleton<AuthenticationService>(AuthenticationService.instance);

// Access anywhere in your app
final db = getIt<DatabaseService>();
final auth = getIt<AuthenticationService>();
```

**Benefits:**
- ✅ Testable (easy to mock services)
- ✅ Loosely coupled components
- ✅ Clear dependency management
- ✅ Singleton lifecycle management

### Adaptive Widget Factory
Abstracts UI implementation across platforms:

```dart
abstract class AdaptiveWidgetFactory {
  Widget button({required String label, required VoidCallback onPressed});
  Widget textField({String? label, ValueChanged<String>? onChanged});
  // ... 30+ adaptive widgets
}

// Implementations
class MaterialWidgetFactory extends AdaptiveWidgetFactory { /* ... */ }
class CupertinoWidgetFactory extends AdaptiveWidgetFactory { /* ... */ }
class ForUIWidgetFactory extends AdaptiveWidgetFactory { /* ... */ }
```

**Benefits:**
- ✅ Platform-agnostic UI code
- ✅ Runtime UI system switching
- ✅ Consistent component API
- ✅ Easy to extend with new systems

### Reactive State with Signals
Granular, efficient state management:

```dart
// Create reactive state
final counter = signal(0);
final user = signal<User?>(null);

// Computed values
final doubledCounter = computed(() => counter.value * 2);

// Watch for changes in UI
Watch((context) => Text('Count: ${counter.value}'))

// Effect for side effects
effect(() {
  print('Counter changed to: ${counter.value}');
});
```

**Benefits:**
- ✅ Granular reactivity (only affected widgets rebuild)
- ✅ No boilerplate (no setState, notifiers, etc.)
- ✅ Computed values and effects
- ✅ Excellent debugging story

## 🗂️ Project Structure

```
lib/
├── src/
│   ├── core/                   # Core framework components
│   │   ├── app_config.dart     # App configuration
│   │   ├── app_route.dart      # Route definitions
│   │   └── service_locator.dart # DI setup
│   │
│   ├── plugins/                # Plugin system
│   │   ├── core/               # Plugin infrastructure
│   │   │   ├── plugin_manager.dart    # Plugin lifecycle
│   │   │   ├── plugin_registry.dart   # Plugin tracking
│   │   │   └── plugin_discovery.dart  # Auto-discovery
│   │   ├── interfaces/         # Plugin contracts
│   │   │   ├── base_plugin.dart       # Base interface
│   │   │   ├── service_plugin.dart    # Service plugins
│   │   │   ├── widget_plugin.dart     # Widget plugins
│   │   │   ├── theme_plugin.dart      # Theme plugins
│   │   │   └── workflow_plugin.dart   # Workflow plugins
│   │   └── examples/           # Example plugins
│   │       ├── analytics_plugin.dart
│   │       └── chart_widget_plugin.dart
│   │
│   ├── services/               # Business logic services
│   │   ├── database_service.dart
│   │   ├── auth_service.dart
│   │   ├── network_service.dart
│   │   ├── preferences_service.dart
│   │   └── navigation_service.dart
│   │
│   ├── ui/                     # UI layer components
│   │   ├── adaptive/           # Adaptive widget system
│   │   │   ├── adaptive_widget_factory.dart
│   │   │   ├── material_widget_factory.dart
│   │   │   ├── cupertino_widget_factory.dart
│   │   │   └── forui_widget_factory.dart
│   │   ├── screens/            # Common screens
│   │   │   ├── settings_screen.dart
│   │   │   └── service_inspector_screen.dart
│   │   └── themes/             # Theme definitions
│   │
│   ├── state/                  # State management
│   │   ├── app_shell_settings_store.dart
│   │   └── signals_extensions.dart
│   │
│   ├── models/                 # Data models
│   │   ├── user.dart
│   │   ├── document.dart
│   │   └── app_config_models.dart
│   │
│   └── utils/                  # Utilities
│       ├── logging.dart
│       ├── validators.dart
│       └── constants.dart
│
└── flutter_app_shell.dart     # Main export file
```

## 🔄 Data Flow

### 1. User Interaction Flow
```
User Action → Widget → Service → State Update → UI Rebuild
     ↓           ↓        ↓           ↓            ↓
  Tap Button → onPressed → updateData → signal.value = newData → Watch rebuilds
```

### 2. Service Communication Flow
```
Service A → Signal Update → Effect/Watch → Service B Action
    ↓           ↓              ↓             ↓
AuthService → user.value = newUser → effect(() => {}) → DatabaseService.sync()
```

### 3. Cloud Sync Flow
```
Local Change → Service → Local Storage → Background Sync → Cloud Storage
      ↓          ↓           ↓               ↓              ↓
  User Edit → DatabaseService → InstantDB → Real-time Sync → Cloud DB
                                 ↓
Cloud Change → WebSocket → Service Update → Signal → UI Update
```

## 🎯 Key Design Patterns

### 1. Factory Pattern (Adaptive UI)
```dart
// Abstract factory
abstract class AdaptiveWidgetFactory {
  Widget createButton();
  Widget createTextField();
}

// Concrete factories
class MaterialWidgetFactory implements AdaptiveWidgetFactory { /* ... */ }
class CupertinoWidgetFactory implements AdaptiveWidgetFactory { /* ... */ }

// Factory selection
AdaptiveWidgetFactory getFactory(String uiSystem) {
  switch (uiSystem) {
    case 'material': return MaterialWidgetFactory();
    case 'cupertino': return CupertinoWidgetFactory();
    default: return MaterialWidgetFactory();
  }
}
```

### 2. Singleton Pattern (Services)
```dart
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._(); // Private constructor

  // Service implementation...
}
```

### 3. Observer Pattern (Reactive State)
```dart
// Signal is the subject
final signal = Signal<String>('initial');

// Watch widgets are observers
Watch((context) => Text(signal.value)) // Rebuilds when signal changes

// Effects are also observers
effect(() => print('Signal changed: ${signal.value}'));
```

### 4. Repository Pattern (Data Access)
```dart
abstract class UserRepository {
  Future<User?> getUser(String id);
  Future<void> saveUser(User user);
  Stream<List<User>> watchUsers();
}

class LocalUserRepository implements UserRepository {
  final DatabaseService _db;
  // Implementation using local database
}

class CloudUserRepository implements UserRepository {
  final InstantDBService _instantdb;
  // Implementation using cloud service
}
```

## 🧪 Testing Architecture

### Service Testing
```dart
void main() {
  late DatabaseService databaseService;
  
  setUp(() {
    // Use in-memory database for testing
    databaseService = DatabaseService.forTesting();
  });
  
  test('should save and retrieve user', () async {
    final user = User(id: '1', name: 'Test User');
    await databaseService.saveUser(user);
    
    final retrieved = await databaseService.getUser('1');
    expect(retrieved, equals(user));
  });
}
```

### Widget Testing with Adaptive UI
```dart
void main() {
  testWidgets('should render material button in material mode', (tester) async {
    await tester.pumpWidget(
      TestApp(
        uiSystem: 'material',
        child: MyWidget(),
      ),
    );
    
    expect(find.byType(MaterialButton), findsOneWidget);
    expect(find.byType(CupertinoButton), findsNothing);
  });
}
```

## 🔧 Configuration & Initialization

### App Initialization Flow
```dart
void main() {
  runShellApp(() async {
    // 1. Setup logging
    setupLogging();
    
    // 2. Initialize core services
    await initializeCoreServices();
    
    // 3. Register custom services
    registerCustomServices();
    
    // 4. Load user preferences
    await loadUserPreferences();
    
    // 5. Return app configuration
    return AppConfig(
      title: 'My App',
      routes: getAppRoutes(),
      theme: getAppTheme(),
    );
  });
}
```

### Service Initialization Order
1. **Logging Service** - For debugging all other initialization
2. **Preferences Service** - To load saved settings
3. **Settings Store** - To restore user preferences
4. **Navigation Service** - For routing setup
5. **Database Service** - For local data storage
6. **Network Service** - For API communication
7. **Authentication Service** - For user management
8. **Custom Services** - Your app-specific services

## 📊 Performance Considerations

### Lazy Loading
Services are only initialized when first accessed:
```dart
// Service registration (fast)
getIt.registerLazySingleton<ExpensiveService>(() => ExpensiveService());

// Service initialization (only when needed)
final service = getIt<ExpensiveService>(); // Created on first access
```

### Granular Reactivity
Signals provide fine-grained reactivity:
```dart
// Only widgets watching specific signals rebuild
final name = signal('John');
final age = signal(25);

// This only rebuilds when name changes
Watch((context) => Text(name.value))

// This only rebuilds when age changes  
Watch((context) => Text('Age: ${age.value}'))
```

### Efficient UI Updates
The adaptive system minimizes rebuilds:
```dart
// UI system change only rebuilds affected components
settingsStore.uiSystem.value = 'cupertino';
// Only Watch widgets using adaptive factories rebuild
```

## 🔄 Extension Points

### Plugin System
The framework provides a comprehensive plugin system for extensions:

```dart
// Service Plugin Example
class AnalyticsPlugin extends BaseServicePlugin {
  @override
  String get id => 'com.example.analytics';
  
  @override
  Future<void> registerServices(GetIt getIt) async {
    getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  }
}

// Widget Plugin Example
class ChartPlugin extends BaseWidgetExtensionPlugin {
  @override
  Map<String, AdaptiveWidgetBuilder> get widgets => {
    'line_chart': _buildLineChart,
    'bar_chart': _buildBarChart,
  };
}

// Register plugins
runShellApp(
  () async => AppConfig(...),
  enablePlugins: true,
  pluginConfiguration: {
    'manualPlugins': [AnalyticsPlugin(), ChartPlugin()],
  },
);
```

### Plugin Types
1. **Service Plugins** - Business logic and data access
2. **Widget Plugins** - Custom UI components
3. **Theme Plugins** - Complete UI systems
4. **Workflow Plugins** - Automation and processing

### Adding Custom Services (Without Plugins)
```dart
// 1. Create your service
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();
  
  void track(String event) { /* implementation */ }
}

// 2. Register in service locator
getIt.registerSingleton<AnalyticsService>(AnalyticsService.instance);

// 3. Use anywhere
getIt<AnalyticsService>().track('user_action');
```

### Adding Custom UI Systems
```dart
// 1. Create widget factory
class MyCustomWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget button({required String label, required VoidCallback onPressed}) {
    return MyCustomButton(label: label, onPressed: onPressed);
  }
  // ... implement other widgets
}

// 2. Register factory
registerAdaptiveFactory('my_custom', () => MyCustomWidgetFactory());

// 3. Use in settings
settingsStore.uiSystem.value = 'my_custom';
```

## 📚 Next Steps

Now that you understand the architecture, explore these areas:

- **[Plugin System](plugin-system.md)** - Learn about the extensible plugin architecture
- **[Service Documentation](services/README.md)** - Deep dive into all available services
- **[UI Systems Guide](ui-systems/README.md)** - Learn about adaptive UI implementation
- **[State Management](state-management.md)** - Master reactive state with Signals
- **[Cloud Integration](cloud/instantdb.md)** - Add cloud features with InstantDB
- **[Custom Services](advanced/custom-services.md)** - Build your own services

The architecture is designed to grow with your app while maintaining clean separation of concerns and excellent developer experience. Happy building! 🚀