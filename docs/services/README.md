# Services Documentation

Flutter App Shell provides a comprehensive suite of services that handle common app functionality out-of-the-box. All services use dependency injection, reactive state management, and are fully testable. Additional services can be added through the plugin system.

## 🔧 Core Architecture

### Service Locator Pattern
All services are registered and accessed through GetIt:

```dart
// Registration (automatic in runShellApp)
getIt.registerSingleton<DatabaseService>(DatabaseService.instance);
getIt.registerSingleton<AuthenticationService>(AuthenticationService.instance);

// Access anywhere in your app
final db = getIt<DatabaseService>();
final auth = getIt<AuthenticationService>();
```

### Reactive State
Services use Signals for reactive state management:

```dart
// Service exposes reactive state
class AuthenticationService {
  final _isAuthenticated = signal(false);
  Signal<bool> get isAuthenticated => _isAuthenticated;
  
  final _currentUser = signal<User?>(null);
  Signal<User?> get currentUser => _currentUser;
}

// UI reacts automatically  
Watch((context) => Text(
  auth.isAuthenticated.value ? 'Logged In' : 'Logged Out'
))
```

### Service Health Monitoring
All services provide health status for debugging:

```dart
abstract class BaseService {
  ServiceHealth get health;
  String get statusMessage;
  Map<String, dynamic> get debugInfo;
}

enum ServiceHealth { healthy, initializing, error, disabled }
```

## 📦 Available Services

### Core Services
| Service | Description | Key Features |
|---------|-------------|--------------|
| [NavigationService](navigation.md) | Centralized navigation | GoRouter integration, deep linking |
| [PreferencesService](preferences.md) | Settings storage | Type-safe, reactive, automatic persistence |
| [LoggingService](logging.md) | Structured logging | Multiple levels, file output, filtering |

### Data Services  
| Service | Description | Key Features |
|---------|-------------|--------------|
| [DatabaseService](database.md) | Real-time NoSQL storage | InstantDB-based, reactive queries, real-time sync, zero code generation |
| [NetworkService](networking.md) | HTTP client | Dio-based, offline queue, retry logic |
| [FileStorageService](file-storage.md) | File management | Local + cloud storage, progress tracking |

### User Services
| Service | Description | Key Features |
|---------|-------------|--------------|
| [AuthenticationService](authentication.md) | User authentication | JWT tokens, biometrics, session management |
| [UserProfileService](user-profile.md) | User profiles | Avatar upload, preferences, social features |
| [NotificationService](notifications.md) | Push notifications | Local + remote, scheduling, badges |

### Cloud Services
| Service | Description | Key Features |
|---------|-------------|--------------|
| DatabaseService | InstantDB integration | Real-time, auth, storage, database |
| [AnalyticsService](analytics.md) | Usage analytics | Event tracking, user journeys, crash reporting |
| [CrashReportingService](crash-reporting.md) | Error monitoring | Automatic reporting, stack traces, user context |

### Device Services
| Service | Description | Key Features |
|---------|-------------|--------------|
| [DeviceInfoService](device-info.md) | Device information | Platform details, capabilities, permissions |
| [ConnectivityService](connectivity.md) | Network monitoring | Online/offline status, connection type |
| [LocationService](location.md) | GPS/location | Background tracking, geofencing, maps |
| [CameraService](camera.md) | Camera/photos | Capture, gallery, image processing |

### Debug Services
| Service | Description | Key Features |
|---------|-------------|--------------|
| [ServiceInspector](inspector.md) | Service debugging | Real-time monitoring, health status, testing |
| [PerformanceService](performance.md) | Performance monitoring | FPS tracking, memory usage, profiling |

## 🚀 Getting Started with Services

### Basic Service Usage
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get services from service locator
    final db = getIt<DatabaseService>();
    final auth = getIt<AuthenticationService>();
    final ui = getAdaptiveFactory(context);
    
    return Watch((context) {
      // React to authentication state
      final isLoggedIn = auth.isAuthenticated.value;
      
      if (!isLoggedIn) {
        return LoginScreen();
      }
      
      return ui.scaffold(
        body: FutureBuilder(
          future: db.findByType('todos'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return TodoList(todos: snapshot.data!);
            }
            return CircularProgressIndicator();
          },
        ),
      );
    });
  }
}
```

### Service Initialization
Services are automatically initialized in the correct order:

```dart
void main() {
  runShellApp(() async {
    // Services are initialized automatically:
    // 1. Logging Service (for debugging initialization)
    // 2. Preferences Service (for loading settings) 
    // 3. Settings Store (for user preferences)
    // 4. Navigation Service (for routing)
    // 5. Database Service (for local storage)
    // 6. Network Service (for API calls)
    // 7. Authentication Service (for user management)
    // 8. Your custom services
    
    return AppConfig(
      title: 'My App',
      routes: [...],
    );
  });
}
```

## 🔗 Service Integration Patterns

### Cross-Service Communication
Services communicate through reactive signals:

```dart
class AuthenticationService {
  final _currentUser = signal<User?>(null);
  
  Future<void> login(String email, String password) async {
    final user = await _performLogin(email, password);
    _currentUser.value = user;
    
    // Other services can react to this change
  }
}

class DatabaseService {
  AuthenticationService? _auth;
  
  void initialize() {
    _auth = getIt<AuthenticationService>();
    
    // React to authentication changes
    effect(() {
      final user = _auth!.currentUser.value;
      if (user != null) {
        _switchToUserDatabase(user.id);
      } else {
        _clearDatabase();
      }
    });
  }
}
```

### Service Composition
Build complex functionality by combining services:

```dart
class UserDataManager {
  final DatabaseService _db = getIt<DatabaseService>();
  final FileStorageService _storage = getIt<FileStorageService>();
  final AuthenticationService _auth = getIt<AuthenticationService>();
  
  Future<UserProfile> loadUserProfile() async {
    final userId = _auth.currentUser.value?.id;
    if (userId == null) throw Exception('Not authenticated');
    
    // Load profile data from database
    final profileDoc = await _db.findById('user_profiles', userId);
    
    // Load profile image from storage
    final imageUrl = await _storage.getPublicUrl(
      fileName: 'profile_$userId.jpg',
      folder: 'avatars',
    );
    
    return UserProfile(
      data: profileDoc?.data,
      imageUrl: imageUrl,
    );
  }
}
```

## 🧪 Testing Services

### Unit Testing
```dart
void main() {
  late DatabaseService databaseService;
  
  setUp(() {
    // Use test implementation
    databaseService = DatabaseService.forTesting();
  });
  
  test('should save and retrieve documents', () async {
    // Test service functionality
    final doc = {'title': 'Test Document', 'content': 'Test content'};
    final id = await databaseService.create('documents', doc);
    
    final retrieved = await databaseService.findById('documents', id);
    expect(retrieved?.data, equals(doc));
  });
  
  tearDown(() {
    databaseService.dispose();
  });
}
```

### Integration Testing
```dart
void main() {
  group('Authentication Flow', () {
    testWidgets('should login and sync data', (tester) async {
      // Setup test app with services
      await tester.pumpWidget(TestApp());
      
      // Perform login
      await tester.enterText(find.byKey(Key('email')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password');
      await tester.tap(find.byKey(Key('login')));
      await tester.pumpAndSettle();
      
      // Verify services responded correctly
      final auth = getIt<AuthenticationService>();
      final db = getIt<DatabaseService>();
      
      expect(auth.isAuthenticated.value, isTrue);
      expect(db.currentUserId, equals('test-user-id'));
    });
  });
}
```

### Mock Services
```dart
class MockDatabaseService extends DatabaseService {
  final Map<String, Map<String, dynamic>> _mockData = {};
  
  @override
  Future<String> create(String type, Map<String, dynamic> data) async {
    final id = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    _mockData[id] = {...data, 'type': type};
    return id;
  }
  
  @override
  Future<Document?> findById(String type, String id) async {
    final data = _mockData[id];
    if (data == null || data['type'] != type) return null;
    
    return Document(id: id, type: type, data: data);
  }
}

// Use in tests
setUp(() {
  getIt.registerSingleton<DatabaseService>(MockDatabaseService());
});
```

## 🔧 Configuration

### Service Configuration
Many services can be configured during initialization:

```dart
void main() {
  runShellApp(() async {
    // Configure logging
    await LoggingService.initialize(
      level: LogLevel.debug,
      writeToFile: true,
      maxFileSize: 10 * 1024 * 1024, // 10MB
    );
    
    // Configure database
    await DatabaseService.initialize(
      enableCloudSync: true,
      syncInterval: Duration(minutes: 5),
      conflictResolution: ConflictResolutionStrategy.lastWriteWins,
    );
    
    // Configure networking
    await NetworkService.initialize(
      baseUrl: 'https://api.myapp.com',
      timeout: Duration(seconds: 30),
      retryPolicy: RetryPolicy.exponentialBackoff(),
    );
    
    return AppConfig(...);
  });
}
```

### Environment-Based Configuration
```dart
// Use different configurations for different environments
final config = Environment.isDevelopment 
    ? DevelopmentConfig()
    : ProductionConfig();

await DatabaseService.initialize(config.databaseConfig);
await NetworkService.initialize(config.networkConfig);
```

## 📊 Service Inspector

The Service Inspector provides real-time monitoring and debugging:

```dart
// Access via settings screen or add as route
AppRoute(
  title: 'Inspector',
  path: '/inspector',
  icon: Icons.bug_report,
  builder: (context, state) => const ServiceInspectorScreen(),
),
```

**Features:**
- **Health Status** - Green/yellow/red indicators for each service
- **Live Metrics** - Real-time performance and usage statistics  
- **Interactive Testing** - Test service operations with one click
- **Debug Information** - Detailed service state and configuration
- **Error Reporting** - Recent errors and stack traces

## 🔍 Debugging Services

### Logging Integration
All services integrate with the logging system:

```dart
class MyService {
  static final _logger = Logger('MyService');
  
  Future<void> performOperation() async {
    _logger.info('Starting operation');
    
    try {
      await _doSomething();
      _logger.debug('Operation completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Operation failed', e, stackTrace);
      rethrow;
    }
  }
}
```

### Health Monitoring
Monitor service health in real-time:

```dart
class DatabaseService extends BaseService {
  @override
  ServiceHealth get health {
    if (!_isInitialized) return ServiceHealth.initializing;
    if (_hasErrors) return ServiceHealth.error;
    return ServiceHealth.healthy;
  }
  
  @override
  String get statusMessage {
    switch (health) {
      case ServiceHealth.healthy:
        return 'Connected and operational';
      case ServiceHealth.initializing:
        return 'Initializing database connection';
      case ServiceHealth.error:
        return 'Database connection failed: $_lastError';
      default:
        return 'Unknown status';
    }
  }
  
  @override
  Map<String, dynamic> get debugInfo => {
    'documents_count': _documentCount,
    'last_sync': _lastSyncTime?.toIso8601String(),
    'cache_size': _cacheSize,
    'pending_operations': _pendingOperations.length,
  };
}
```

## 🔌 Plugin-Provided Services

Flutter App Shell supports extending services through the plugin system:

### Using Service Plugins
```dart
// Install and use analytics plugin
final analyticsPlugin = AnalyticsPlugin();

runShellApp(
  () async => AppConfig(...),
  enablePlugins: true,
  pluginConfiguration: {
    'manualPlugins': [analyticsPlugin],
  },
);

// Access plugin services via GetIt
final analytics = getIt<AnalyticsService>();
await analytics.trackEvent('user_action');
```

### Common Plugin Services
- **Analytics Services** - Track user behavior and app usage
- **Payment Services** - Process payments and subscriptions
- **Communication Services** - Chat, video calls, notifications
- **Integration Services** - CRM, ERP, third-party APIs
- **AI/ML Services** - Machine learning models and predictions

### Creating Service Plugins
```dart
class MyServicePlugin extends BaseServicePlugin {
  @override
  String get id => 'com.mycompany.myservice';
  
  @override
  List<Type> get serviceTypes => [MyService];
  
  @override
  Future<void> registerServices(GetIt getIt) async {
    getIt.registerSingleton<MyService>(MyService());
  }
}
```

Learn more in the [Plugin System documentation](../plugin-system.md).

## 🔗 Service-Specific Guides

### Essential Services
- **[Database Service](database.md)** - Local storage with cloud sync
- **[Authentication Service](authentication.md)** - User authentication and management  
- **[Network Service](networking.md)** - HTTP client with offline support
- **[Navigation Service](navigation.md)** - Centralized navigation management

### Advanced Services
- **[File Storage Service](file-storage.md)** - Local and cloud file management
- **[Database Service](database.md)** - Complete InstantDB integration
- **[Service Inspector](inspector.md)** - Real-time debugging and monitoring

### Extending Services
- **[Custom Services](../advanced/custom-services.md)** - Create your own services
- **[Plugin System](../plugin-system.md)** - Extend with service plugins
- **[Service Testing](../advanced/testing.md)** - Advanced testing strategies

The service architecture is designed to be modular, testable, and easy to extend. Start with the core services and gradually add more advanced functionality as your app grows! 🚀