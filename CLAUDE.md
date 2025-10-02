# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter PowerSchool App Shell Framework - A comprehensive application framework providing zero-configuration foundation for Flutter apps with advanced service architecture, adaptive UI systems, and cloud synchronization.

**⚠️ EXPERIMENTAL SOFTWARE - NOT PRODUCTION READY**

## Project Structure

```
flutter_ps_app_shell/
├── packages/flutter_app_shell/    # Core framework package
│   ├── lib/
│   │   ├── src/
│   │   │   ├── core/              # App shell, routing, config
│   │   │   ├── services/          # Core services (9 services)
│   │   │   ├── plugins/           # Plugin system (4 types)
│   │   │   ├── ui/adaptive/       # Adaptive UI factories
│   │   │   ├── wizard/            # Wizard/onboarding system
│   │   │   ├── state/             # Settings store
│   │   │   └── utils/             # Logging, utilities
│   │   └── flutter_app_shell.dart # Main export
│   └── pubspec.yaml
├── example/                        # Example app demonstrating features
│   ├── lib/features/              # Feature demonstrations
│   └── pubspec.yaml
├── docs/                          # Comprehensive documentation
├── workers/                       # Cloudflare Workers (Dart/TypeScript)
├── justfile                       # Build automation
└── .env.example                   # Environment configuration template
```

## Quick Start Commands

### Essential Commands (Just)
```bash
# Project setup
just setup              # Install dependencies for package + example
just run                # Run example app
just test               # Run all tests (package + example)
just analyze            # Run static analysis on all code
just format             # Format all code
just clean              # Clean all build artifacts

# Platform-specific runs
just run-web            # Run on Chrome
just run-ios            # Run on iOS simulator
just run-android        # Run on Android
just run-macos          # Run on macOS

# Testing
just test-package       # Test package only
just test-example       # Test example only

# Building
just build-android      # Build Android APK
just build-ios          # Build iOS app
just build-web          # Build web app
just build-macos        # Build macOS app
just build-windows      # Build Windows app
just build-linux        # Build Linux app

# Documentation
just generate-llms      # Generate llms.txt for AI assistants

# Quality checks
just pre-commit         # Run format, analyze, test before commit
just ci                 # Full CI pipeline simulation
```

### Release Management
```bash
just version            # Show current version and tags
just release-patch      # Bump patch version (0.7.22 → 0.7.23)
just release-minor      # Bump minor version (0.7.22 → 0.8.0)
just release-major      # Bump major version (0.7.22 → 1.0.0)
just publish-release VERSION  # Push and create GitHub release
```

### Cloudflare Workers Development
```bash
just setup-cloudflare        # Setup workers (login, install deps)
just secrets-cloudflare      # Set basic worker secrets
just secrets-ai-gateway      # Set AI Gateway secrets
just dev-dart-worker         # Run Dart worker locally
just dev-ts-shim             # Run TypeScript auth shim locally
just deploy-cloudflare       # Deploy both workers
just tail-dart-worker        # View Dart worker logs
```

### Direct Flutter Commands
```bash
# When working in package or example directory
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter test                 # Run tests
flutter test path/to/test    # Run specific test
flutter analyze              # Static analysis
dart format .                # Format code
```

## Environment Configuration

### Required Setup for Cloud Features

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Configure InstantDB** (for authentication & real-time sync):
   - Sign up at https://www.instantdb.com
   - Create a new app in dashboard
   - Copy App ID to `.env`:
     ```bash
     INSTANTDB_APP_ID=your-app-id-here
     INSTANTDB_ENABLE_SYNC=true
     INSTANTDB_VERBOSE_LOGGING=false  # Enable for debugging
     ```

3. **Add .env to pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - .env
   ```

4. **Local-only mode**: Leave `INSTANTDB_APP_ID` empty to run without authentication/cloud sync.

## Architecture Overview

### Core Principles

1. **Service-Oriented Architecture**: All business logic in singleton services managed by GetIt
2. **Adaptive UI System**: Runtime switching between Material, Cupertino, and ForUI design systems
3. **Reactive State**: Signals-first approach for granular, efficient state updates
4. **Zero Code Generation**: No `build_runner`, no `.g.dart` files, instant hot reload
5. **Plugin System**: Extensible architecture for services, widgets, themes, and workflows

### Core Services (9 Services)

All registered through GetIt dependency injection:

```dart
// Access anywhere in app
final db = getIt<DatabaseService>();
final auth = getIt<AuthenticationService>();
final prefs = getIt<PreferencesService>();
```

**Available Services**:
- `NavigationService` - GoRouter navigation management
- `DatabaseService` - InstantDB NoSQL with real-time sync (zero code generation!)
- `AuthenticationService` - JWT tokens, biometric support, magic links
- `PreferencesService` - Reactive SharedPreferences with Signals
- `NetworkService` - Dio HTTP client with offline queue and retry
- `FileStorageService` - Local and cloud file management
- `LoggingService` - Hierarchical logging with per-service control
- `CloudflareService` - Cloudflare Workers integration (R2, AI Gateway)
- `WindowStateService` - Desktop window state persistence (multi-monitor)
- `AppShellSettingsStore` - User preferences with automatic persistence

### Adaptive UI System

**Three UI Systems**:
- **Material**: Google Material Design 3
- **Cupertino**: Native iOS components and styling
- **ForUI**: Modern, minimal design system

**30+ Adaptive Components** via abstract factory pattern:
```dart
final ui = getAdaptiveFactory(context);

// Same API across all UI systems
ui.button(label: 'Click Me', onPressed: () {});
ui.textField(label: 'Name', onChanged: (v) {});
ui.scaffold(appBar: ui.appBar(title: const Text('Title')));
```

Components automatically adapt to current UI system (Material/Cupertino/ForUI).

### Responsive Navigation

Automatically adapts based on screen size and route count:

- **Mobile (<600px)**:
  - ≤5 visible routes: Bottom navigation tabs
  - >5 visible routes: Drawer with hamburger menu
- **Tablet (600-1200px)**: Side navigation rail
- **Desktop (>1200px)**: Full sidebar with collapse/expand

**Hidden Routes**: Use `showInNavigation: false` to create routes accessible via code but not shown in navigation UI (great for workflows, camera screens, checkout flows).

### Plugin System

Four plugin types for extensibility:
- **Service Plugins**: Add business logic and data access
- **Widget Plugins**: Provide custom UI components
- **Theme Plugins**: Create complete custom UI systems
- **Workflow Plugins**: Implement automation and processing

Plugins can be auto-discovered from dependencies or manually registered.

## Development Patterns

### Screen Architecture

**IMPORTANT**: Screens should NOT use `ui.scaffold()` unless they need special scaffold behavior.

```dart
// ✅ CORRECT - Screen returns content directly
class MyScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return ListView(
      children: [
        ui.pageTitle('My Screen'),  // Auto-adapts across UI systems
        // ... content
      ],
    );
  }
}

// ❌ INCORRECT - Creates nested scaffolds
class BadScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return ui.scaffold(  // Don't do this!
      body: ListView(/* content */),
    );
  }
}

// ✅ EXCEPTION - sliverScaffold for special layouts
class SpecialScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return ui.sliverScaffold(  // OK for sliver layouts
      largeTitle: const Text('Title'),
      slivers: [/* slivers */],
    );
  }
}
```

AppShell provides the scaffold wrapper automatically. Screens return content only.

### State Management with Signals

**Zero code generation required!**

```dart
// Create reactive state
final counter = signal(0);
final user = signal<User?>(null);

// Computed values
final doubledCounter = computed(() => counter.value * 2);

// Watch for changes in UI (auto-rebuild)
Watch((context) => Text('Count: ${counter.value}'))

// Effects for side effects
effect(() {
  print('Counter changed to: ${counter.value}');
});
```

### Service Registration

```dart
// 1. Create service
class MyService {
  static MyService? _instance;
  static MyService get instance => _instance ??= MyService._();
  MyService._();

  void doSomething() { /* ... */ }
}

// 2. Register in GetIt (during app initialization)
getIt.registerSingleton<MyService>(MyService.instance);

// 3. Use anywhere
getIt<MyService>().doSomething();
```

### Logging Patterns

Hierarchical logging with per-service control:

```dart
// Service-level logging (recommended)
class MyService {
  static final Logger _logger = createServiceLogger('MyService');

  Future<void> performAction() async {
    _logger.fine('Starting action...');
    try {
      // Business logic
      _logger.info('Action completed successfully');
    } catch (e, stackTrace) {
      _logger.severe('Action failed', e, stackTrace);
      rethrow;
    }
  }
}

// Simple logging (backward compatible)
AppShellLogger.i('Application event');
AppShellLogger.w('Warning message');
AppShellLogger.e('Error occurred');
```

**Benefits**: Per-service filtering, automatic prefixing, runtime level adjustment, release mode optimization.

## Important Conventions

### Import Organization
1. Dart imports first
2. Flutter imports second
3. Package imports third (alphabetical)
4. Project imports last (grouped by feature)

### File Naming
- Services: `*_service.dart`
- Stores: `*_store.dart`
- Adaptive components: `adaptive_*.dart`
- Screens: `*_screen.dart`

### Platform-Specific Code
```dart
import 'stub.dart' if (dart.library.html) 'web_specific.dart';
```

## Key Features

### ✅ Implemented Features

**Core Framework**:
- Zero-configuration app setup with `runShellApp()`
- Service-oriented architecture with GetIt DI
- Responsive navigation (bottom tabs → rail → sidebar)
- Hidden routes support (`showInNavigation: false`)
- Automatic settings persistence via SharedPreferences

**Adaptive UI**:
- Complete Material/Cupertino/ForUI switching at runtime
- 30+ adaptive components with consistent API
- Platform-aware transitions (iOS sliding, Material fades)
- Large title support (iOS collapsing headers)
- Context-safe dialogs and navigation

**Services**:
- DatabaseService: InstantDB real-time NoSQL (zero code generation!)
- AuthenticationService: Magic links, biometric, JWT tokens
- NetworkService: Dio with offline queue and retry
- WindowStateService: Desktop multi-monitor state persistence
- Service Inspector: Real-time debugging UI

**Plugin System**:
- 4 plugin types (Service, Widget, Theme, Workflow)
- Auto-discovery from dependencies
- Health monitoring and lifecycle management
- Example plugins included (Analytics, Charts)

**Desktop Support**:
- Window state persistence across restarts
- Multi-monitor awareness (including negative coordinates)
- Platform-specific window management

### 🚧 Not Yet Implemented

- Enhanced InstantDB features (advanced queries, presence)
- Additional optional services (30+ planned)
- Performance monitoring service
- Push notification service

## Critical Dependencies

**Do not change without careful consideration**:
```yaml
flutter_hooks: ^0.20.5        # Hook-based state management
go_router: ^14.2.3            # Navigation
get_it: ^8.0.0                # Dependency injection
signals: ^6.0.2               # Primary state (NO CODE GENERATION!)
instantdb_flutter: ^0.2.1     # Real-time DB (NO CODE GENERATION!)
shared_preferences: ^2.3.1    # Local storage
```

**Flutter Requirements**:
- SDK: ^3.6.0
- Min Flutter: >=3.16.0
- Material Design 3 enabled
- Platforms: Android, iOS, Web, Windows, macOS, Linux

## Navigation System

### Platform-Aware Transitions

- **Cupertino**: iOS-style sliding transitions
- **Material**: Material Design fade/scale animations
- **ForUI**: Clean Material-style transitions

**Tab navigation**: No animations (instant switching)
**Nested navigation**: Platform-appropriate animations

### Back Button Detection

Dual approach for reliability:
```dart
// Primary: GoRouter canPop
final canPop = GoRouter.of(context).canPop();

// Fallback: Path-based detection
final pathSegments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
final isNestedRoute = pathSegments.length > 1;

// Combined logic
final shouldShowBackButton = canPop || isNestedRoute;
```

**Why?** GoRouter's `canPop()` sometimes returns false in ShellRoute contexts. Path-based detection ensures back buttons appear on nested routes.

### Hidden Routes Example

```dart
AppRoute(
  title: 'Camera',
  path: '/camera',
  icon: Icons.camera,
  builder: (context, state) => const CameraScreen(),
  showInNavigation: false,  // Hidden from navigation UI
),

// Still accessible via code:
onPressed: () => context.push('/camera'),
```

**Use cases**: Camera screens, checkout flows, onboarding, modal workflows, detail screens.

## Testing

### Running Tests
```bash
just test                     # All tests
just test-package             # Package only
just test-example             # Example only
flutter test path/to/test     # Specific test file
```

### Test Patterns
```dart
// Service testing
void main() {
  late DatabaseService databaseService;

  setUp(() {
    databaseService = DatabaseService.forTesting();
  });

  test('should save and retrieve user', () async {
    final user = User(id: '1', name: 'Test');
    await databaseService.saveUser(user);

    final retrieved = await databaseService.getUser('1');
    expect(retrieved, equals(user));
  });
}

// Widget testing with adaptive UI
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
```

## Debugging Tools

### Service Inspector

Navigate to `/inspector` in example app for real-time debugging:
- Visual dashboard with service health indicators
- One-click testing for all services
- Live status updates using Signals
- Interactive service information dialogs

### InstantDB Test Screen

Navigate to `/instantdb-test` (via science icon 🔬):
- Test findWhere, watchWhere queries
- Diagnose cache pollution issues
- Copy logs for debugging
- Real-time query monitoring

### Datalog Investigation

Navigate to `/datalog-investigation` for InstantDB debugging:
- Test datalog parsing
- Collection-specific attribute mapping
- See `DATALOG_PARSING_GUIDE.md` for details

## Recent Updates

### v0.7.27 (Latest) - Button Padding Consistency Fix
- ✅ Fixed padding inconsistency between filled and outlined buttons
- ✅ Added missing `padding: EdgeInsets.zero` to `outlinedButton()`
- ✅ All button types now have uniform visual padding (16px)
- ✅ Eliminates width differences caused by double-padding

### v0.7.26 - Cupertino Button Width Fix (Corrected)
- ✅ Fixed v0.7.25 incorrect implementation (SizedBox wrapper doesn't work)
- ✅ Applied correct pattern: Container as button's child, not wrapper
- ✅ CupertinoButton.filled now properly expands to fill available width
- ⚠️ Had padding inconsistency - fixed in v0.7.27

### v0.7.25 [DEPRECATED] - Incorrect Fix
- ⚠️ Used wrong approach (SizedBox wrapper)
- ❌ CupertinoButton doesn't respect parent SizedBox constraints
- 📌 Superseded by v0.7.26

### v0.7.24 - Outlined Button Width Fix
- ✅ Fixed outlined buttons not respecting parent width constraints
- ✅ Buttons now expand to fill available width consistently across all UI systems
- ✅ Resolved visual inconsistency when mixing filled and outlined buttons

### v0.7.23 - Complete Signals Fix & UI Improvements
- ✅ Fixed all reactive cycle issues (proper use of `untracked()`, `batch()`)
- ✅ Fixed ScaffoldMessenger error (uses adaptive UI system)
- ✅ Enhanced InstantDB test screen (Copy Logs button)

### v0.7.22 - InstantDB Validation Fix
- Fixed findWhere/watchWhere malformed queries
- Eliminated cache pollution and validation errors

### v0.7.19 - Enhanced Datalog Parsing
- Fixed DatabaseService datalog parsing
- Added `diagnoseDatalogParsing()` method
- Flexible attribute mapping support

### InstantDB Flutter v0.2.4 Integration
- Fixed entities cached under wrong collection name
- Proper entity type detection and cache key resolution
- See https://pub.dev/packages/instantdb_flutter/versions/0.2.4

## Development Tips

1. **Never launch the app yourself** - Ask the user to run it and hot reload
2. Check `docs/` for comprehensive framework documentation
3. Use adaptive component pattern for all UI (30+ components available)
4. Register services through GetIt for proper DI
5. Follow Signals-first for state management (zero code generation!)
6. Test on multiple screen sizes for responsive behavior
7. Settings persist automatically - no manual save/load needed
8. Use Service Inspector for real-time debugging
9. Use InstantDB Test Screen for database debugging
10. Test navigation across all three UI systems

## Documentation

- **Main README**: `README.md` - Quick start and overview
- **Documentation Hub**: `docs/README.md` - Complete documentation index
- **Architecture**: `docs/architecture.md` - Framework design principles
- **Plugin System**: `docs/plugin-system.md` - Extensibility guide
- **AI-Friendly Docs**: `llms.txt`, `llms-full.txt` - Generated via `just generate-llms`
- **Environment Guide**: `.env.example` - Configuration template
- **Datalog Guide**: `DATALOG_PARSING_GUIDE.md` - InstantDB debugging

## Cloudflare Workers

The project includes Cloudflare Workers for backend functionality:

**Structure**:
- `workers/dart-api-worker/` - Dart API worker (compile to JS)
- `workers/ts-auth-shim/` - TypeScript authentication shim

**Key Commands**:
```bash
just setup-cloudflare        # Initial setup
just secrets-cloudflare      # Configure basic secrets
just secrets-ai-gateway      # Configure AI Gateway
just dev-dart-worker         # Local Dart worker development
just dev-ts-shim             # Local TS shim development
just deploy-cloudflare       # Deploy both workers
```

**Required Secrets**:
- `SESSION_JWT_SECRET` - JWT signing secret
- `INSTANT_APP_ID` - InstantDB app ID
- `R2_*` - R2 storage credentials (account, keys, bucket)
- `CF_API_TOKEN` - Cloudflare API token
- Optional: `AI_GATEWAY_ID`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`

## User Preferences

**For web/Node.js tooling in this project**: Use `bun` instead of `npm`.

## Example App Routes

The example app demonstrates all features with 20+ routes:

**Main Routes** (visible in navigation):
- `/` - Home with framework overview
- `/dashboard` - Responsive layout demo
- `/settings` - Platform-adaptive settings
- `/profile` - Adaptive forms
- `/adaptive` - Live UI system switching
- `/services` - Interactive service testing
- `/inspector` - Real-time service debugging
- `/wizard` - Wizard navigation demo
- `/cloud-sync` - InstantDB real-time sync
- Plus more...

**Hidden Routes** (accessible via code only):
- `/onboarding` - Fullscreen onboarding flow
- `/responsive-navigation` - Navigation threshold demo
- `/datalog-investigation` - InstantDB debugging
- `/instantdb-test` - Query testing tool
- Plus navigation sub-routes...

Use hidden routes for workflows, modals, and screens that shouldn't appear in main navigation.
