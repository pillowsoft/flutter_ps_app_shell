# Flutter App Shell

> ⚠️ **EXPERIMENTAL SOFTWARE - NOT PRODUCTION READY** ⚠️
> 
> This framework is in early experimental stages and contains:
> - **Numerous bugs and incomplete features**
> - **Breaking changes without notice**
> - **Untested edge cases**
> - **Performance issues**
> 
> **USE AT YOUR OWN RISK** - This code is provided for educational purposes and inspiration only. It is NOT suitable for production applications. Consider this a reference implementation or starting point for your own framework.

A comprehensive Flutter application framework for rapid development with adaptive UI, service architecture, state management, and cloud synchronization capabilities.

## 🚀 Features

### Core Framework
- **Adaptive UI System** - Seamlessly switch between Material, Cupertino, and ForUI design systems
  - Complete component library with 30+ adaptive widgets
  - Extended components: date/time pickers, range sliders, chips, tab bars, and more
  - Platform-specific styling and behavior
- **Plugin System** - Extensible architecture for custom functionality
  - Service Plugins: Add new services (analytics, payments, etc.)
  - Widget Plugins: Provide reusable UI components (charts, maps, etc.)
  - Theme Plugins: Create custom design systems beyond Material/Cupertino/ForUI
  - Workflow Plugins: Implement multi-step processes (onboarding, wizards, etc.)
  - Auto-discovery from dependencies with health monitoring
- **Service-Oriented Architecture** - Modular services with dependency injection via GetIt
- **Reactive State Management** - Built on Signals for efficient, granular updates
- **Responsive Navigation** - Adaptive layout system with platform-aware transitions:
  - Mobile (<600px): Bottom tabs (≤5 routes) or drawer (>5 routes)
  - Tablet (600-1200px): Navigation rail with collapsible labels
  - Desktop (>1200px): Full sidebar with expand/collapse
  - **Platform Transitions**: iOS sliding in Cupertino, Material transitions in Material/ForUI
  - **Smart Back Button Detection**: Reliable back button appearance on nested routes
  - **Authentic iOS Feel**: Proper sliding animations and back button behavior
- **Wizard Navigation** - Step-by-step flows with progress tracking and persistence
- **Settings Persistence** - Automatic saving/loading of all preferences with reactive effects

### Cloud Integration (InstantDB)
- **Real-time Database** - Local-first with automatic cloud sync and live updates
- **Built-in Authentication** - Magic link auth with biometric support
- **WebSocket Synchronization** - Real-time updates across devices
- **Offline-First Architecture** - Works seamlessly offline with sync when connected
- **Zero Configuration** - No schema setup or migrations required
- **Reactive Queries** - Live query updates without polling

### Services
- **NavigationService** - Centralized navigation management with GoRouter
- **DatabaseService** - NoSQL document storage with InstantDB (no code generation) and real-time sync
- **PreferencesService** - Type-safe key-value storage with reactive signals
- **NetworkService** - Dio HTTP client with offline queue and retry logic
- **AuthenticationService** - JWT tokens, biometric support, session management
- **FileStorageService** - Local and cloud file management
- **Service Inspector** - Real-time debugging UI for all services and plugins with health monitoring

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_shell:
    path: packages/flutter_app_shell
```

## 🏗️ Project Structure

```
flutter_ps_app_shell/
├── packages/
│   └── flutter_app_shell/        # Core framework package
│       ├── lib/
│       │   ├── src/
│       │   │   ├── core/         # Core framework components
│       │   │   ├── services/     # Service implementations
│       │   │   ├── plugins/      # Plugin system
│       │   │   │   ├── interfaces/  # Plugin interfaces
│       │   │   │   ├── core/        # Plugin manager & registry
│       │   │   │   └── examples/    # Example plugins
│       │   │   ├── ui/           # UI components and adaptive system
│       │   │   ├── wizard/       # Wizard navigation system
│       │   │   ├── models/       # Data models
│       │   │   ├── state/        # State management
│       │   │   └── utils/        # Utilities
│       │   └── flutter_app_shell.dart
│       └── pubspec.yaml
├── example/                       # Example application
│   ├── lib/
│   │   ├── features/             # Feature modules
│   │   │   ├── cloud_sync/      # Cloud sync demo
│   │   │   ├── wizard_demo/     # Wizard navigation demo
│   │   │   ├── plugin_demo/     # Plugin system demo
│   │   │   └── ...
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## 🚀 Zero Code Generation Required!

Flutter App Shell eliminates all code generation from your development workflow:

- ✅ **No build_runner** - No more waiting for generated files
- ✅ **No .g.dart files** - Clean, simple Dart code only  
- ✅ **Faster development** - Instant hot reload without generation delays
- ✅ **InstantDB database** - Real-time NoSQL with authentication without code generation
- ✅ **Signals state management** - Reactive state without any setup or generation

**Before (with code generation):**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
# Wait for generation...
flutter run
```

**Now (zero code generation):**
```bash
flutter run  # That's it! 🎉
```

## 🎯 Quick Start

### Basic Setup

```dart
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
      ],
    );
  });
}
```

### Enable Cloud Sync (InstantDB)

1. **Configure InstantDB Project**
   - Create a project at [instantdb.com](https://www.instantdb.com)
   - Get your app ID from the dashboard

2. **Setup Environment Configuration**

Create a `.env` file in your project root:

```bash
# InstantDB Configuration
INSTANTDB_APP_ID=your-app-id-here
INSTANTDB_ENABLE_SYNC=true
INSTANTDB_VERBOSE_LOGGING=false
```

Add the `.env` file as an asset in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

3. **Initialize Services**

```dart
// Services are automatically configured from environment
// No manual initialization required!

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My App',
      routes: [
        // Your routes here
      ],
    );
  });
}
```

4. **No Database Schema Required**

InstantDB is schemaless - just start using it! The database automatically:
- Creates collections as you use them
- Handles real-time synchronization
- Manages authentication and permissions
- Provides offline-first functionality

## 🎨 UI Systems

The framework supports three distinct UI systems with complete component libraries:

### Material Design
- Google's Material Design 3 components
- Vibrant colors, elevation, ripple effects
- Standard Material widgets and behaviors

### Cupertino (iOS)
- Native iOS components and styling
- iOS-specific grouped lists for settings
- Platform-appropriate navigation patterns
- System gray backgrounds and native controls

### ForUI
- Modern, minimal design system
- Zinc/slate color palette
- Flat design with subtle borders
- Focus on accessibility and readability

## 💡 Usage Examples

### Adaptive UI

```dart
Widget build(BuildContext context) {
  final ui = getAdaptiveFactory(context);
  
  return ui.scaffold(
    title: 'Adaptive UI',
    body: Column(
      children: [
        ui.button(
          label: 'Adaptive Button',
          onPressed: () {},
        ),
        ui.textField(
          label: 'Adaptive Input',
          onChanged: (value) {},
        ),
      ],
    ),
  );
}
```

### Database with Real-time Sync

```dart
final db = DatabaseService.instance;

// Create document (syncs automatically)
final doc = await db.create('todos', {
  'title': 'Buy groceries',
  'completed': false,
});

// Query documents
final todos = await db.findByType('todos');

// Watch for real-time changes
db.watchByType('todos').listen((documents) {
  print('Todos updated: ${documents.length}');
  // UI automatically updates!
});

// Update document
await db.update(doc.id, {
  'completed': true,
});

// Delete document
await db.delete(doc.id);
```

### File Storage

```dart
final storage = FileStorageService.instance;

// Save file (local + cloud)
final result = await storage.saveFile(
  fileName: 'document.pdf',
  data: fileBytes,
  folder: 'documents',
  syncToCloud: true,
);

// Load file (with fallback)
final data = await storage.loadFile(
  fileName: 'document.pdf',
  folder: 'documents',
  preferCloud: false, // Try local first
);

// Get public URL
final url = await storage.getPublicUrl(
  fileName: 'document.pdf',
  folder: 'documents',
  expiresIn: Duration(hours: 1),
);
```

### Wizard Navigation

```dart
final wizard = WizardController(
  wizardId: 'onboarding',
  steps: [
    WizardStep(
      id: 'welcome',
      title: 'Welcome',
      builder: (context, wizard) => WelcomeStep(),
    ),
    WizardStep(
      id: 'profile',
      title: 'Create Profile',
      validator: () async => profileValid,
      builder: (context, wizard) => ProfileStep(),
    ),
  ],
  onComplete: (data) async {
    print('Wizard completed with data: $data');
  },
);

// Navigate to wizard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => WizardScreen(controller: wizard),
  ),
);
```

## 🔧 Configuration

### Environment Variables

Configure InstantDB using environment variables in your `.env` file:

```bash
# Required - your InstantDB app ID
INSTANTDB_APP_ID=your-app-id-here

# Optional configuration
INSTANTDB_ENABLE_SYNC=true
INSTANTDB_VERBOSE_LOGGING=false

# Development options
DEBUG_LOGGING=false
LOG_LEVEL=info
```

### InstantDB Features

InstantDB automatically handles:
- **Real-time synchronization** across all connected clients
- **Optimistic updates** for immediate UI responsiveness  
- **Offline-first** architecture with automatic sync when reconnected
- **Built-in conflict resolution** using operational transforms
- **Schema flexibility** - no migrations required
- **Authentication integration** with magic links and social auth

## 📱 Example App

Run the example app to see all features in action:

```bash
cd example
flutter run
```

Navigate to different demos:
- `/` - Home screen with framework overview
- `/dashboard` - Responsive dashboard with adaptive widgets
- `/settings` - Platform-adaptive settings screen
  - Material: Card-based layout
  - Cupertino: iOS-style grouped lists
  - ForUI: Minimal modern design
- `/profile` - User profile with adaptive forms
- `/adaptive` - Live UI system switching demo
- `/services` - Interactive service testing
- `/inspector` - Real-time service monitoring and debugging

## 📚 Documentation

### Complete Documentation
- **[docs/README.md](docs/README.md)** - Comprehensive documentation hub
- **[Getting Started Guide](docs/getting-started.md)** - 5-minute tutorial
- **[Architecture Overview](docs/architecture.md)** - Framework design principles
- **[Common Patterns](docs/examples/patterns.md)** - Real-world examples
- **[Best Practices](docs/reference/best-practices.md)** - Guidelines and recommendations

### AI-Friendly Documentation
- **[llms.txt](llms.txt)** - Navigation index optimized for AI consumption ([llms.txt spec](https://llmstxt.org))
- **[llms-full.txt](llms-full.txt)** - Complete documentation for AI development

```bash
# Generate updated llms.txt files
just generate-llms
```

## 🛠️ Development

### Quick Commands

```bash
# Setup project
just setup

# Run example app
just run

# Run tests
just test

# Generate llms.txt files
just generate-llms

# Clean build
just clean
```

### Running Tests

```bash
flutter test
```

### Building

```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web

# Desktop
flutter build macos
flutter build windows
flutter build linux
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev)
- [InstantDB](https://www.instantdb.com)
- [Signals](https://pub.dev/packages/signals)
- [GoRouter](https://pub.dev/packages/go_router)
- [GetIt](https://pub.dev/packages/get_it)

## 📞 Support

For issues and questions, please use the GitHub issue tracker.