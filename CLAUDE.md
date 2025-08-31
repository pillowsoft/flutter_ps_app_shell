# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Flutter PowerSchool App Shell Framework - a comprehensive application framework that provides a zero-configuration foundation for Flutter apps with advanced service architecture and adaptive UI systems.

## New Package Structure

The project has been reorganized into a proper Flutter package structure:
- `packages/flutter_app_shell/` - The main Flutter App Shell package
- `example/` - Example app demonstrating all package features
- `justfile` - Build automation with all common tasks

## Development Commands

### Quick Start
```bash
# Setup the project
just setup

# Run the example app
just run

# Run all tests
just test
```

### Flutter Development
```bash
# Install dependencies
flutter pub get

# Run development
flutter run

# Build for platforms
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
flutter build macos        # macOS
flutter build linux        # Linux

# Run tests
flutter test

# Static analysis
flutter analyze

# Format code
dart format .
```

### No Code Generation Required!
This project uses InstantDB for database and Signals for state management - both work without any code generation. No `build_runner` needed!

### Bun Usage (User Preference)
For any web-related or Node.js tooling in the project, use `bun` instead of `npm`.

## Architecture Overview

### Core Framework Structure
- **App Shell Pattern**: Zero-configuration Flutter app foundation in `possibly_useful_code/app_shell/`
- **Service Layer**: Dependency injection with GetIt, services configured at startup
- **State Management**: Primary use of Signals (v6.0.2), secondary MobX for specific components
- **Navigation**: GoRouter-based with responsive layout adaptation
- **Multi-UI System**: Complete adaptive system supporting Material, Cupertino, and ForUI with full app-level switching

### Key Directories
- `docs/`: Framework specification (flutter_app_shell_spec.md - comprehensive 1500+ line spec)
- `possibly_useful_code/`: Implementation prototypes
  - `adaptive/`: Multi-UI system implementations
  - `app_shell/`: Core framework implementation
  - `shadcn_app_shell/`: shadcn/ui variant with Rust bridge support
  - `core/`: Core services and architecture patterns
  - `settings/`: Settings screen implementations
  - `wizard/`: Wizard/onboarding flow examples

### Service Architecture
All services are registered through GetIt dependency injection:
- **NavigationService**: Manages GoRouter navigation
- **AppShellSettingsStore**: User preferences with signal-based reactivity
- **LoggingService**: Hierarchical logging with per-service control, runtime level adjustment, and automatic release mode optimization
- **30+ Optional Services**: As specified in the framework docs (auth, analytics, etc.)

### Responsive Layout Strategy
The framework automatically adapts based on screen size:
- **Mobile (<600px)**: Bottom tabs (≤5 items) or drawer (>5 items)
- **Tablet (600-900px)**: Side navigation rail
- **Desktop (>900px)**: Full sidebar with toggle functionality

### State Management Patterns
1. **Signals (Primary)**: Use for reactive state that needs UI updates - NO CODE GENERATION REQUIRED
2. **Service State**: Maintain service-level state in singleton services

## Development Patterns

### Adding New Features
1. Create service in `core/services/` if needed
2. Register service in GetIt container during app initialization
3. Use adaptive components from `adaptive/` for UI consistency
4. Follow existing patterns for state management (Signals-first)
5. Add hierarchical logging using `createServiceLogger('ServiceName')` for better debugging

### Screen Architecture Patterns
**IMPORTANT**: Screens should NOT use `ui.scaffold()` unless they need special scaffold behavior:

- **✅ Correct**: Return content directly (ListView, Column, etc.) - AppShell provides the scaffold wrapper
- **❌ Incorrect**: Wrap content in `ui.scaffold()` - creates nested scaffolds and breaks navigation

```dart
// ✅ CORRECT - Screen returns content directly
class MyScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    return ListView(
      children: [
        ui.pageTitle('My Screen'),  // Works correctly in all UI systems
        // ... content
      ],
    );
  }
}

// ❌ INCORRECT - Creates nested scaffold
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
    return ui.sliverScaffold(  // OK - needs special sliver layout
      largeTitle: const Text('Title'),
      slivers: [/* slivers */],
    );
  }
}
```

This ensures `ui.pageTitle()` works correctly - returning empty content in Cupertino mode and styled headers in Material/ForUI modes.

### Testing Approach
- Unit tests for services and business logic
- Widget tests for UI components with adaptive behavior
- Integration tests for complete user flows

### Logging Patterns
The framework uses hierarchical logging for better organization and control:

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

**Benefits:**
- Per-service log filtering and level control
- Automatic service name prefixing in log output
- Runtime level adjustment through settings UI
- Performance optimization in release builds

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
Use conditional imports for web-specific features:
```dart
import 'stub.dart' if (dart.library.html) 'web_specific.dart';
```

## Framework Capabilities

The framework aims to provide:
- **5-minute app creation**: Single function call to create fully-featured app
- **30+ built-in services**: Authentication, analytics, storage, etc.
- **Offline-first architecture**: Local database with cloud sync
- **InstantDB integration**: Built-in real-time backend with authentication
- **Wizard navigation**: Step-by-step onboarding flows
- **Service inspector**: Debug panel for runtime service inspection

## Current Implementation Status

### Phase 1: Core Foundation ✅ COMPLETED
- Core app shell structure with zero-configuration setup
- Service-oriented architecture with GetIt dependency injection  
- NavigationService, LoggingService, AppShellSettingsStore
- Responsive navigation (bottom tabs → rail → sidebar)
- Signals-based reactive state management

### Phase 2: Adaptive UI System ✅ COMPLETED  
- **Complete UI System Switching**: Entire app dynamically switches between Material, Cupertino, and ForUI
- **Material/Cupertino Integration**: CupertinoApp.router for iOS mode, MaterialApp.router for others
- **Adaptive Component Library**: Abstract factory pattern with platform-specific implementations
- **Navigation Adaptation**: App bars, navigation rails, sidebars all adapt to chosen UI system
- **Localization Support**: Proper Material/Cupertino localization delegates for mixed widget usage
- **Context-Safe Dialogs**: Fixed navigation errors when switching UI systems mid-interaction

### Phase 3: Advanced Services ✅ COMPLETED
- **DatabaseService**: NoSQL document database with InstantDB (no code generation!), reactive queries, real-time sync
- **NetworkService**: HTTP client with Dio, offline queueing, retry logic, connectivity monitoring
- **AuthenticationService**: Complete auth flow with JWT-style tokens, biometric support
- **PreferencesService**: Enhanced SharedPreferences with reactive signals, type-safe access

### Phase 4: Extended Adaptive Components ✅ COMPLETED
- **30+ Adaptive Widgets**: Complete component library across all three UI systems
- **High-Priority Button Components**: All requested button methods fully implemented
  - **buttonWithIcon()**: Primary action buttons with icon + text (FilledButton.icon in Material, CupertinoButton with Row in Cupertino, FButton with Icon in ForUI)
  - **outlinedButton()**: Secondary action buttons with less emphasis (OutlinedButton in Material, custom bordered CupertinoButton in Cupertino, FButton.outline in ForUI)
  - **outlinedButtonWithIcon()**: Secondary buttons with icon context (OutlinedButton.icon in Material, custom implementation in Cupertino, FButton.outline with Icon in ForUI)
- **Essential UI Components**: All core components with platform-specific implementations
  - **divider()**: Platform-appropriate dividers (Divider in Material, custom Container in Cupertino, Divider with ForUI styling)
  - **circularProgressIndicator()**: Loading spinners (CircularProgressIndicator in Material, CupertinoActivityIndicator in Cupertino, custom implementation in ForUI)
  - **linearProgressIndicator()**: Progress bars (LinearProgressIndicator in Material, custom implementation in Cupertino, progress bars in ForUI)
  - **chip()**: Tag/category widgets (Chip in Material, custom rounded container in Cupertino, custom chip implementation in ForUI)
  - **badge()**: Notification indicators (Badge in Material, custom positioned widget in Cupertino, custom badge in ForUI)
- **Critical Gesture & Menu Components**: Essential components that prevent runtime exceptions
  - **popupMenuButton<T>()**: Platform-adaptive popup menus (Material PopupMenuButton, Cupertino ActionSheet, ForUI styled popup)
  - **inkWell()**: Platform-adaptive gesture wrapper that prevents "No Material widget found" errors
  - **AdaptivePopupMenuItem<T>**: Model class for popup menu items with support for icons, destructive styling, and disabled states
- **Enhanced Date/Time Pickers**: Distinct visual styling across all UI systems
  - **Material**: Blue theme with heavy elevation (24px) and rounded corners (16px)
  - **ForUI**: Flat design with sharp corners (4px), light gray backgrounds, zinc color palette
  - **Cupertino**: Native iOS modal pickers with proper fallbacks for unsupported components
- **Extended Components**: Range sliders, chips, tab bars, segmented controls, progress indicators
- **Platform-Specific Styling**: Each UI system has distinct visual characteristics and proper theming
- **iOS Settings Style**: Proper grouped lists with system gray backgrounds for Cupertino mode
- **Fixed Stack Overflow**: Resolved recursive call issue in Cupertino date range picker
- **Large Title Support**: Native iOS large title behavior with adaptive fallbacks
  - **appBar(largeTitle: true)**: Enables iOS CupertinoSliverNavigationBar with collapsing large titles
  - **pageTitle()**: Platform-appropriate page headers (SizedBox.shrink() in Cupertino, prominent headers in Material/ForUI)
  - **sliverScaffold()**: Complete sliver-based scaffold with automatic large title integration

### Phase 5: Plugin System ✅ COMPLETED
- **Plugin Architecture**: Extensible framework with 4 plugin types (Service, Widget, Theme, Workflow)
- **Plugin Manager**: Lifecycle management, dependency resolution, health monitoring
- **Auto-Discovery**: Automatic plugin discovery from package dependencies
- **Example Plugins**: AnalyticsPlugin (service), ChartWidgetPlugin (widgets)
- **Service Inspector Integration**: Real-time monitoring and debugging of all plugins
- **Cross-Platform Support**: Plugins work across all UI systems (Material, Cupertino, ForUI)
- **Zero Configuration**: Plugins can be auto-discovered or manually registered

### Not Yet Implemented
- Enhanced InstantDB features (advanced queries, presence, etc.)
- Additional optional services from specification (30+ services planned)
- Performance monitoring and analytics services
- Push notification service

## Flutter Configuration

- **SDK**: ^3.6.0
- **Min Flutter**: >=3.16.0
- **Material Design**: Version 3 enabled
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Key Dependencies

Core framework dependencies that should not be changed without careful consideration:
- `flutter_hooks: ^0.20.5` - Hook-based state management
- `go_router: ^14.2.3` - Navigation
- `get_it: ^8.0.0` - Dependency injection
- `signals: ^6.0.2` - Primary state management (NO CODE GENERATION!)
- `instantdb_flutter: ^0.1.1` - Real-time database with authentication (NO CODE GENERATION!)
- `shared_preferences: ^2.3.1` - Local storage

## 🎯 Currently Working Features (All Verified and Tested)

### ✅ App Shell Core
- **Zero-configuration setup**: Single function call creates complete app structure
- **Responsive navigation**: Automatically adapts between bottom tabs, navigation rail, and sidebar
- **Service architecture**: GetIt-based dependency injection with core services
- **Desktop-aware layouts**: Proper handling of macOS/Windows/Linux window chrome

### ✅ Desktop Platform Support
- **Window State Persistence**: Automatic saving and restoration of window position, size, and monitor
  - Multi-monitor aware with support for negative coordinates
  - Intelligent display detection using window center point
  - Configurable through user settings
- **Platform-specific window management**: Works seamlessly on macOS, Windows, and Linux
- **Responsive to display changes**: Validates window visibility when displays change

### ✅ Adaptive UI System  
- **Complete UI switching**: Entire app switches between Material, Cupertino, and ForUI design systems
- **30+ Adaptive components**: Complete widget library with extended components
- **Context-safe interactions**: Dialogs and navigation work seamlessly during UI system changes
- **Platform consistency**: Each UI system uses appropriate platform conventions
- **iOS Settings Style**: Proper grouped lists with CupertinoListSection for authentic iOS appearance
- **Desktop SafeArea handling**: Cupertino UI properly handles macOS title bar positioning
- **Mobile drawer navigation**: Automatic drawer with hamburger menu for >5 routes on mobile
- **Extended Components**: Date/time pickers, range sliders, chips, progress indicators, tab bars
- **Reactive UI System Switching**: Fixed race conditions with immediate, synchronous state updates - UI consistently updates when switching between Material, Cupertino, and ForUI
- **Theme Toggle Button**: App bar theme toggle properly switches between light and dark modes, respecting system preferences

### ✅ Advanced Services
- **DatabaseService**: InstantDB-powered NoSQL with reactive queries and real-time synchronization (zero code generation!)
- **NetworkService**: Dio HTTP client with offline queue and automatic retry
- **AuthenticationService**: JWT tokens, biometric auth, complete user management
- **PreferencesService**: Type-safe reactive preferences with Signals integration
- **WindowStateService**: Desktop window position, size, and monitor persistence with multi-monitor support
  - Automatically saves and restores window geometry across app restarts
  - Handles multi-monitor setups including negative coordinates (left monitors)
  - Uses window center for accurate display detection
  - Configurable through Settings with "Remember window state" option
- **Settings Persistence**: All user preferences automatically persist across app restarts using SharedPreferences with reactive effects
- **Service Inspector**: Real-time debugging UI showing all service and plugin health, status, and interactive testing capabilities

### ✅ Example App Demonstrations
- **Home**: Welcome screen with framework overview
- **Dashboard**: Responsive layout with adaptive widgets  
- **Settings**: Complete settings management with theme/UI switching
- **Profile**: User profile screen demonstrating adaptive forms
- **Adaptive UI**: Live UI system switching demo with component showcase (Material, Cupertino, ForUI)
- **Services Demo**: Interactive testing of all Phase 3 services (database, network, auth)
- **Plugin Demo**: Showcase of plugin capabilities with analytics tracking and chart widgets
- **Service Inspector**: Real-time debugging and monitoring of all registered services and plugins with health status
- **Components**: Comprehensive demo of extended adaptive components including date pickers, file uploads, charts
- **Buttons**: Dedicated demo of high-priority button components (buttonWithIcon, outlinedButton, outlinedButtonWithIcon) with interactive examples and usage code
- **Popup & InkWell**: Interactive demonstration of popup menus and gesture wrappers across all UI systems with real-time feedback
- **10 Total Routes**: Demonstrates automatic switch from bottom tabs to drawer navigation on mobile

### ✅ Responsive Behavior
- **Mobile (<600px)**: Bottom navigation (≤5 routes) or drawer navigation (>5 routes) with hamburger menu
- **Tablet (600-1200px)**: Side navigation rail with collapsible labels  
- **Desktop (>1200px)**: Full sidebar with collapse/expand functionality
- **Cross-UI compatibility**: All navigation modes work consistently across Material, Cupertino, and ForUI

## Settings Persistence

The Flutter App Shell provides automatic settings persistence out of the box:

### ✅ Automatic Persistence
All settings are automatically saved to SharedPreferences using reactive effects:
- **Theme Mode**: Light/Dark/System theme preferences
- **UI System**: Material/Cupertino/ForUI selection  
- **Navigation**: Sidebar collapsed state, navigation labels visibility
- **Developer**: Debug mode, log level settings
- **Appearance**: Text scale factor and other UI preferences

### ✅ Implementation Details
The `AppShellSettingsStore` uses a three-phase initialization:
1. **Initialize signals** with default values (no effects yet)
2. **Load saved values** from SharedPreferences (overwrites defaults)
3. **Setup reactive effects** to persist future changes

This ensures settings persist correctly across app restarts and hot reloads.

### ✅ Usage Example
```dart
final settingsStore = getIt<AppShellSettingsStore>();

// Settings automatically persist when changed
settingsStore.uiSystem.value = 'cupertino';  // Saves immediately
settingsStore.themeMode.value = ThemeMode.dark;  // Saves immediately

// UI reactively updates using Watch()
Watch((context) {
  final theme = settingsStore.themeMode.value;
  return Text('Current theme: $theme');
});
```

## Service Inspector

The Flutter App Shell includes a powerful **Service Inspector** for debugging and monitoring:

### ✅ Real-time Service Monitoring
Visual dashboard showing all registered services with live status indicators:
- **Navigation Service**: Current route, navigation testing
- **Settings Store**: Live settings values with interactive viewer
- **Preferences Service**: Storage statistics and test operations  
- **Database Service**: CRUD testing, connection status, document browser
- **Network Service**: HTTP testing, connection status, queue monitoring
- **Authentication Service**: Auth state, login testing, token details

### ✅ Interactive Testing Capabilities
Each service card provides action buttons for testing:
- **One-click service testing** with automatic logging
- **Live status updates** using reactive signals
- **Detailed service information** in modal dialogs
- **Error handling and reporting** for failed operations

### ✅ Developer-Friendly Features
- **Responsive grid layout** adapts to screen size (1-4 columns)
- **Adaptive UI integration** - works in Material, Cupertino, and ForUI modes
- **Real-time refresh** capability to update all service statuses
- **Color-coded status indicators** (green=healthy, orange=initializing, red=error)

### ✅ Access the Service Inspector
Navigate to the "Inspector" tab in the example app to explore all service capabilities. Perfect for:
- Development and debugging
- Understanding service architecture
- Testing service integrations
- Monitoring app health in real-time

## Development Tips

1. Always check the comprehensive specification in `docs/flutter_app_shell_spec.md` for framework design decisions
2. Use the adaptive component pattern for any new UI elements (30+ components available)
3. Register all services through GetIt for proper dependency management
4. Follow the Signal-first approach for state management
5. Test on multiple screen sizes to ensure responsive behavior works correctly
6. Use the "Adaptive UI" screen in the example app to test UI system switching
7. **Settings persist automatically** - no manual save/load code needed
8. Use the Service Inspector for real-time debugging of all services
9. Test UI switching between Material, Cupertino, and ForUI to ensure all components adapt properly
10. **Test navigation across all UI systems** to verify platform-appropriate transitions
11. **Use the Navigation Demo screen** to verify back button behavior and transition animations
12. **Verify iOS sliding transitions** work properly in Cupertino mode
13. **Check tab switching has no animations** (correct behavior for main navigation)
- Never launch the app yourself. Ask the user to do it. And if we want to hot reload, ask the user to do that as well.

## Navigation System & Transitions

The Flutter App Shell features a sophisticated navigation system with platform-aware transitions that provide authentic user experiences across all UI systems.

### ✅ Platform-Aware Transitions

The framework automatically provides appropriate transitions based on the current UI system:

- **🍎 Cupertino Mode**: iOS-style sliding transitions (slide in from right, slide out to left)
- **🤖 Material Mode**: Material Design transitions (fade/scale animations)
- **🎨 ForUI Mode**: Clean Material-style transitions for consistency

### ✅ Smart Transition Strategy

**Tab Navigation** (No Animations):
- Switching between main routes uses `NoTransitionPage`
- Instant transitions between Home, Dashboard, Settings, etc.
- Follows standard mobile UX patterns (iOS/Android)

**Nested Navigation** (Platform Transitions):
- Detail screens, pushed routes use platform-appropriate animations
- Cupertino mode provides authentic iOS sliding experience
- Material/ForUI modes use their respective transition styles

### ✅ Advanced Back Button Detection

The framework uses a dual approach for reliable back button detection:

```dart
// Primary: GoRouter's canPop() detection
final canPop = GoRouter.of(context).canPop();

// Fallback: Path-based nested route detection
final pathSegments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
final isNestedRoute = pathSegments.length > 1;

// Combined logic for robust detection
final shouldShowBackButton = canPop || isNestedRoute;
```

**Why the dual approach?**
- `GoRouter.canPop()` sometimes returns false in ShellRoute contexts
- Path-based detection ensures back buttons appear on nested routes
- Works reliably across all UI systems and routing scenarios

### ✅ Cupertino-Specific Back Button Handling

For iOS authenticity, Cupertino mode uses explicit back button creation:

```dart
// Explicit iOS-style back button with proper navigation
leading = ui.iconButton(
  icon: const Icon(Icons.arrow_back_ios),
  onPressed: () {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      // Fallback: navigate to parent route
      final parentPath = '/${pathSegments.sublist(0, pathSegments.length - 1).join('/')}';
      GoRouter.of(context).go(parentPath);
    }
  },
);
```

### ✅ Navigation Demo

The example app includes a comprehensive **Navigation Demo** screen demonstrating:

- **Push Navigation**: Test iOS sliding transitions and back button behavior
- **Deep Navigation**: Multi-level navigation with consistent back button appearance  
- **Navigation State Analysis**: Real-time display of canPop(), path segments, and transition logic
- **Cross-Platform Testing**: Works across Material, Cupertino, and ForUI modes

### ✅ Implementation Details

**Route Configuration**:
```dart
// Main routes: No transitions (tab switching)
pageBuilder: (context, state) => _buildPlatformAwarePage(
  state: state,
  child: route.builder(context, state),
  isNestedRoute: false,
),

// Nested routes: Platform-aware transitions
pageBuilder: (context, state) => _buildPlatformAwarePage(
  state: state, 
  child: subRoute.builder(context, state),
  isNestedRoute: true,
),
```

**Platform Detection**:
```dart
switch (uiSystem) {
  case 'cupertino':
    return CupertinoPage(key: state.pageKey, child: child);
  case 'material':
    return MaterialPage(key: state.pageKey, child: child);
  case 'forui':
  default:
    return MaterialPage(key: state.pageKey, child: child);
}
```

## Large Title Features

The Flutter App Shell now includes comprehensive large title support that provides native iOS behavior while adapting gracefully to Material and ForUI design systems.

### Usage Examples

#### 1. Large Title AppBar
```dart
// Enable iOS large title behavior
ui.scaffold(
  appBar: ui.appBar(
    title: const Text('Settings'),
    largeTitle: true,  // Enable iOS large title
  ),
  body: // your content
)
```

#### 2. Page Title Helper
```dart
// Material/ForUI: Shows prominent header
// Cupertino: Returns SizedBox.shrink() (iOS uses nav bar titles)
ui.pageTitle('Settings')
```

#### 3. Sliver Scaffold with Large Title
```dart
ui.sliverScaffold(
  largeTitle: const Text('Settings'),
  actions: [
    ui.iconButton(
      icon: const Icon(Icons.info),
      onPressed: () => showInfo(),
    ),
  ],
  slivers: [
    SliverToBoxAdapter(
      child: ui.pageTitle('Settings'),  // For non-iOS platforms
    ),
    // Your content slivers here
  ],
)
```

### Platform Behavior

- **iOS (Cupertino)**: Uses `CupertinoSliverNavigationBar` for native large title experience with automatic collapsing
- **Material**: Uses `SliverAppBar` with `FlexibleSpaceBar` for equivalent collapsing header behavior
- **ForUI**: Similar to Material but with ForUI's clean, flat design aesthetic
- **pageTitle()**: Returns appropriate headers for Material/ForUI, empty widget for Cupertino (since iOS uses navigation bar titles)

### Demo Screen

See the "Large Title" screen in the example app for interactive demonstrations of all three features across different UI systems.