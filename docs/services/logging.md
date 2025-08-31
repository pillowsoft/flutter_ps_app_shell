# Logging Service

The Flutter App Shell includes a comprehensive logging system built on Dart's standard `logging` package, providing hierarchical logging with per-service control and runtime configuration.

## Features

- **Hierarchical Logging**: Each service gets its own named logger with individual filtering
- **Runtime Control**: Adjust log levels through the settings UI without app restart
- **Performance Optimized**: Automatic reduction to warnings-only in release builds
- **Better Organization**: Service names in log output for easier debugging and filtering
- **Stream-Based Architecture**: Flexible log handling with custom listeners
- **Backward Compatible**: Existing `AppShellLogger` API remains unchanged

## Basic Usage

### Simple Logging (Backward Compatible)

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

// Use the simple AppShellLogger for basic logging needs
AppShellLogger.d('Debug message');
AppShellLogger.i('Info message'); 
AppShellLogger.w('Warning message');
AppShellLogger.e('Error message');
```

### Advanced Hierarchical Logging

For services and complex components, use hierarchical loggers:

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:logging/logging.dart';

class UserService {
  // Create a service-specific logger
  static final Logger _logger = createServiceLogger('UserService');
  
  Future<User> fetchUser(String userId) async {
    _logger.fine('Fetching user: $userId');
    
    try {
      // Your service logic here
      final user = await api.getUser(userId);
      _logger.info('Successfully fetched user: ${user.name}');
      return user;
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch user: $userId', e, stackTrace);
      rethrow;
    }
  }
  
  void updateUserPreferences(User user, Map<String, dynamic> prefs) {
    _logger.config('Updating preferences for user: ${user.id}');
    
    // Validation with detailed logging
    if (prefs.isEmpty) {
      _logger.warning('Empty preferences provided for user: ${user.id}');
      return;
    }
    
    // Update logic
    _logger.fine('Preferences updated: ${prefs.keys}');
  }
}
```

## Log Levels

The logging system supports standard log levels in order of severity:

| Level | Method | Use Case | Example |
|-------|--------|----------|---------|
| `FINE` | `_logger.fine()` | Debug details, internal state | `"Processing 5 items"` |
| `INFO` | `_logger.info()` | General information | `"User logged in successfully"` |
| `CONFIG` | `_logger.config()` | Configuration changes | `"Theme changed to dark mode"` |
| `WARNING` | `_logger.warning()` | Potential issues | `"Slow network detected"` |
| `SEVERE` | `_logger.severe()` | Errors, exceptions | `"Failed to save data"` |

### Automatic Release Mode Behavior

- **Debug Mode**: All log levels are enabled (configurable via settings)
- **Release Mode**: Automatically limited to `WARNING` and above for performance
- **File Logging**: Disabled in release mode for security and performance

## Runtime Configuration

Users can adjust log levels through the settings UI during app runtime:

1. Navigate to **Settings > Developer > Log Level**
2. Choose from: Debug, Info, Warning, Error
3. Changes apply immediately to all loggers
4. Settings persist across app restarts

### Programmatic Configuration

Access the LoggingService directly for advanced configuration:

```dart
import 'package:get_it/get_it.dart';

// Get the logging service
final loggingService = GetIt.instance<LoggingService>();

// Set global log level
loggingService.setGlobalLevel(Level.FINE);

// Set level from string (useful for settings)
loggingService.setLevelFromString('info');

// Set level for specific logger
loggingService.setLoggerLevel('UserService', Level.WARNING);
```

## Best Practices

### Service Logging Pattern

Follow this pattern for consistent service logging:

```dart
class MyService {
  // Static logger per service class
  static final Logger _logger = createServiceLogger('MyService');
  
  Future<Result> performOperation() async {
    _logger.fine('Starting operation');
    
    try {
      // Business logic
      final result = await doWork();
      _logger.info('Operation completed successfully');
      return result;
    } catch (e, stackTrace) {
      _logger.severe('Operation failed', e, stackTrace);
      rethrow;
    }
  }
}
```

### Performance Considerations

1. **Use appropriate log levels**: Reserve `FINE` for debug details only
2. **Lazy evaluation**: Pass functions for expensive message construction:
   ```dart
   _logger.fine(() => 'Complex calculation: ${expensiveOperation()}');
   ```
3. **Avoid logging in tight loops**: Consider sampling or batching
4. **Don't log sensitive data**: Never log passwords, tokens, or personal information

### Error Handling

Always include context and stack traces for errors:

```dart
try {
  // Risky operation
} catch (e, stackTrace) {
  _logger.severe('Operation failed with context', e, stackTrace);
  // Handle the error appropriately
}
```

## Integration Examples

### Custom Service Integration

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:logging/logging.dart';

class ApiService {
  static final Logger _logger = createServiceLogger('ApiService');
  
  Future<void> initialize() async {
    _logger.config('Initializing API service');
    
    // Setup logic
    _logger.info('API service initialized successfully');
  }
  
  Future<ApiResponse> request(String endpoint) async {
    _logger.fine('Making request to: $endpoint');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(Uri.parse(endpoint));
      final duration = stopwatch.elapsedMilliseconds;
      
      _logger.info('Request completed in ${duration}ms: $endpoint');
      return ApiResponse.fromJson(response.body);
      
    } catch (e, stackTrace) {
      _logger.severe('Request failed: $endpoint', e, stackTrace);
      throw ApiException('Failed to fetch data', e);
    }
  }
}
```

### State Management Integration

```dart
class UserStore {
  static final Logger _logger = createServiceLogger('UserStore');
  
  late final Signal<User?> currentUser = signal(null);
  
  void setUser(User user) {
    _logger.info('Setting current user: ${user.id}');
    currentUser.value = user;
    _logger.fine('User state updated in store');
  }
  
  void clearUser() {
    final userId = currentUser.value?.id;
    _logger.info('Clearing current user: $userId');
    currentUser.value = null;
  }
}
```

## Troubleshooting

### Common Issues

1. **No log output in release mode**: This is intentional for performance. Use debug builds for development.

2. **Too much debug output**: Adjust the log level in settings or programmatically:
   ```dart
   LoggingService.instance.setLevelFromString('info');
   ```

3. **Missing service names in output**: Ensure you're using `createServiceLogger()`:
   ```dart
   // ❌ Generic logger
   static final Logger _logger = Logger('MyService');
   
   // ✅ Service logger with proper formatting
   static final Logger _logger = createServiceLogger('MyService');
   ```

### Performance Debugging

Monitor logging performance in your service inspector:

```dart
// Check logging service status
final loggingService = GetIt.instance<LoggingService>();
final stats = loggingService.getStats();
print('Active loggers: ${stats.activeLoggers}');
print('Current global level: ${stats.globalLevel}');
```

## Migration from Logger Package

If you were using the old `logger` package directly:

### Before (logger package)
```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');
logger.i('Info message'); 
logger.w('Warning message');
logger.e('Error message');
```

### After (logging package)
```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:logging/logging.dart';

// Simple migration
AppShellLogger.d('Debug message');
AppShellLogger.i('Info message');
AppShellLogger.w('Warning message'); 
AppShellLogger.e('Error message');

// Or better - use hierarchical logging
static final Logger _logger = createServiceLogger('MyService');

_logger.fine('Debug message');
_logger.info('Info message');
_logger.warning('Warning message');
_logger.severe('Error message');
```

The new system provides better organization, performance, and control while maintaining full backward compatibility.