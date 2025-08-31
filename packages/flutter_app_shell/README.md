# Flutter App Shell

A comprehensive Flutter application shell framework that eliminates boilerplate code and accelerates app development with adaptive UI, service architecture, and state management.

## Features

- 🚀 **Zero-Config Development** - One function call creates a fully functional app
- 🎨 **Multi-UI System Support** - Seamlessly switch between Material, Cupertino, and ForUI
- 🔧 **Comprehensive Service Layer** - Dependency injection with GetIt and reactive state with Signals
- 📱 **Intelligent Layout Engine** - Adaptive navigation that responds to screen size
- ⚙️ **Developer Experience** - Hot reload support, type safety, and extensible settings
- ☁️ **Cloud Integration Ready** - Built-in support for authentication and offline-first data

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => const HomeScreen(),
        ),
        AppRoute(
          title: 'Settings',
          path: '/settings',
          icon: Icons.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  });
}
```

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_app_shell: ^0.1.0
```

## Key Features

### Logging System

The Flutter App Shell includes a comprehensive logging system with hierarchical support:

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:logging/logging.dart';

// Simple logging (backward compatible)
AppShellLogger.i('Application started');
AppShellLogger.w('Warning message');
AppShellLogger.e('Error occurred');

// Advanced hierarchical logging
class MyService {
  static final Logger _logger = createServiceLogger('MyService');
  
  void performAction() {
    _logger.fine('Debug details');
    _logger.info('Action completed');
    _logger.warning('Potential issue detected');
  }
}
```

**Benefits:**
- **Hierarchical Control**: Each service gets its own logger with individual filtering
- **Runtime Configuration**: Adjust log levels through the settings UI
- **Performance Optimized**: Automatic reduction to warnings-only in release builds
- **Better Organization**: Service names in log output for easier debugging

### Responsive Navigation

Automatically adapts based on screen size:
- **Mobile**: Bottom tabs (≤5 routes) or drawer navigation (>5 routes)
- **Tablet**: Side navigation rail with collapsible labels
- **Desktop**: Full sidebar with expand/collapse functionality

### Service Architecture

Built-in services with dependency injection:
- `DatabaseService` - NoSQL document storage with reactive queries
- `NetworkService` - HTTP client with offline queue and retry logic  
- `AuthenticationService` - Complete auth flow with biometric support
- `PreferencesService` - Type-safe reactive preferences
- `LoggingService` - Hierarchical logging with runtime control

## Documentation

For detailed documentation, please visit our [documentation site](https://example.com/docs).

## License

MIT License - see LICENSE file for details.