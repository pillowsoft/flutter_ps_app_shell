# Flutter App Shell - Quick Reference Guide

*A comprehensive overview of services, features, and adaptive UI capabilities for AI assistants*

## 🏗️ Core Architecture & Services

### Framework Overview
- **Zero-Configuration Setup**: Single function call creates complete app structure with service architecture
- **Service-Oriented Architecture**: GetIt dependency injection with 8+ core services and 30+ optional services  
- **Signals-First State Management**: Reactive programming with v6.0.2 (NO code generation required)
- **InstantDB Integration**: Real-time NoSQL database with authentication (NO code generation required)

### Core Services (Always Available)

#### NavigationService
```dart
final nav = getIt<NavigationService>();
nav.goTo('/dashboard');  // Navigate to routes
nav.goBack();           // Handle back navigation
```

#### AppShellSettingsStore (Reactive Settings)
```dart
final settings = getIt<AppShellSettingsStore>();
settings.uiSystem.value = 'cupertino';    // Switch UI system
settings.themeMode.value = ThemeMode.dark; // Change theme
// Settings automatically persist to SharedPreferences
```

#### DatabaseService (InstantDB-Powered)
```dart
final db = getIt<DatabaseService>();
// Create documents (generates proper OperationType.add)
final id = await db.create('conversations', {'title': 'New Chat'});
// Read with reactive queries
final docs = await db.findAll('conversations');
// Update existing documents  
await db.update('conversations', id, {'title': 'Updated'});
// Delete documents
await db.delete('conversations', id);
```

#### NetworkService (HTTP Client)
```dart
final network = getIt<NetworkService>();
final response = await network.get('/api/data');
// Automatic retry logic, offline queue, connectivity monitoring
```

#### AuthenticationService (JWT + Biometric)
```dart
final auth = getIt<AuthenticationService>();
await auth.signInWithEmailAndPassword(email, password);
final user = auth.currentUser.value;  // Reactive user state
await auth.enableBiometricAuth();    // Face ID, Touch ID, etc.
```

#### LoggingService (Hierarchical)
```dart
// Service-level logging (recommended)
final logger = createServiceLogger('MyService');
logger.info('Action completed');
logger.severe('Error occurred', error, stackTrace);

// Simple logging (backward compatible)
AppShellLogger.i('Info message');
```

### Desktop Services
#### WindowStateService
```dart
// Automatic window position, size, and monitor persistence
// Multi-monitor support with negative coordinates
// Configurable through Settings UI
```

### Quick App Setup
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final app = await AppShell.create(
    appTitle: 'My App',
    routes: [
      AppRoute(title: 'Home', path: '/', icon: Icons.home, 
               builder: (context, state) => HomeScreen()),
      AppRoute(title: 'Settings', path: '/settings', icon: Icons.settings,
               builder: (context, state) => SettingsScreen()),
      // Hidden routes (accessible via code, not in navigation)
      AppRoute(title: 'Camera', path: '/camera', icon: Icons.camera,
               builder: (context, state) => CameraScreen(), 
               showInNavigation: false),
    ],
  );
  
  runApp(app);
}
```

---

## 🎨 Adaptive UI System & Components

### Complete UI System Switching
The app dynamically switches between **three complete design systems**:
- **Material**: Google's Material Design 3
- **Cupertino**: Apple's iOS design language  
- **ForUI**: Clean, flat design system

```dart
// Access adaptive factory in any widget
final ui = getAdaptiveFactory(context);
// All components automatically adapt to current UI system
```

### Responsive Navigation (Automatic)
- **Mobile (<600px)**: Bottom navigation (≤5 routes) or drawer (>5 routes)
- **Tablet (600-1200px)**: Side navigation rail with collapsible labels
- **Desktop (>1200px)**: Full sidebar with collapse/expand functionality

### 30+ Adaptive Components

#### Essential UI Components
```dart
// Buttons (all variants adapt to UI system)
ui.button(label: 'Primary Action', onPressed: () {})
ui.buttonWithIcon(icon: Icon(Icons.add), label: 'Add Item', onPressed: () {})
ui.outlinedButton(label: 'Secondary', onPressed: () {})
ui.outlinedButtonWithIcon(icon: Icon(Icons.edit), label: 'Edit', onPressed: () {})

// Form Components
ui.textField(label: 'Name', controller: controller)
ui.switch(value: isEnabled, onChanged: (value) => setState(() => isEnabled = value))
ui.slider(value: progress, onChanged: (value) => setState(() => progress = value))

// Lists & Cards
ui.listTile(title: Text('Item'), subtitle: Text('Description'))
ui.card(child: Padding(padding: EdgeInsets.all(16), child: Text('Content')))

// Grouped Lists (iOS-style settings groups in Cupertino)
ui.listSection(
  header: Text('Appearance'),  // Section title
  children: [
    ui.listTile(
      title: Text('Theme Mode'),
      subtitle: Text('Dark'),
      trailing: Icon(Icons.chevron_right),
    ),
    ui.listTile(
      title: Text('Text Scale'),
      trailing: ui.switch_(value: true, onChanged: (v) {}),
    ),
  ],
)
// In Cupertino: Creates CupertinoListSection.insetGrouped
// In Material: Creates Card with header
// In ForUI: Creates custom grouped section

// Progress & Feedback
ui.circularProgressIndicator()
ui.linearProgressIndicator(value: 0.7)
ui.chip(label: 'Tag', backgroundColor: Colors.blue.shade100)
ui.badge(label: '5', child: Icon(Icons.notifications))
```

#### Navigation & Layout
```dart
// App bars adapt to each UI system
ui.appBar(
  title: Text('My Screen'),
  largeTitle: true,  // iOS large title behavior
  actions: [ui.iconButton(icon: Icon(Icons.more_vert), onPressed: () {})]
)

// Page structure (DON'T wrap in ui.scaffold - AppShell provides it)
Widget build(BuildContext context) {
  final ui = getAdaptiveFactory(context);
  return ListView(
    children: [
      ui.pageTitle('My Screen'),  // Adaptive page header
      // ... your content
    ],
  );
}
```

#### Interactive Components
```dart
// Gestures & Menus
ui.inkWell(onTap: () {}, child: Text('Touchable'))
ui.popupMenuButton<String>(
  items: [
    AdaptivePopupMenuItem(value: 'edit', label: 'Edit', icon: Icons.edit),
    AdaptivePopupMenuItem(value: 'delete', label: 'Delete', 
                         icon: Icons.delete, isDestructive: true),
  ],
  onSelected: (value) => handleAction(value),
)

// Date & Time Pickers (distinct styling per UI system)
await ui.showDatePicker(context: context, initialDate: DateTime.now())
await ui.showTimePicker(context: context, initialTime: TimeOfDay.now())
```

#### Advanced Components
```dart
// Tab Navigation
ui.tabBar(tabs: [Tab(text: 'Tab 1'), Tab(text: 'Tab 2')])
ui.segmentedControl<String>(
  children: {'option1': Text('Option 1'), 'option2': Text('Option 2')},
  onSelectionChanged: (selection) => handleSelection(selection.first),
)

// Special Layouts
ui.sliverScaffold(
  largeTitle: Text('Large Title'),
  slivers: [
    SliverList(/* your content */)
  ],
)
```

### Screen Architecture Pattern
```dart
class MyScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    // ✅ CORRECT: Return content directly (AppShell provides scaffold)
    return ListView(
      children: [
        ui.pageTitle('My Screen'),  // Works in all UI systems
        ui.card(child: /* content */),
        // ... more content
      ],
    );
  }
}

// ❌ INCORRECT: Don't wrap in ui.scaffold() unless you need special behavior
```

### Reactive UI Updates
```dart
// Use Watch() for reactive UI based on settings
Watch((context) {
  final currentTheme = settingsStore.themeMode.value;
  final uiSystem = settingsStore.uiSystem.value;
  return Text('Current: $uiSystem theme in $currentTheme mode');
});
```

### Development Best Practices
- **Import Organization**: Dart → Flutter → Packages (alphabetical) → Project imports
- **File Naming**: `*_service.dart`, `*_store.dart`, `adaptive_*.dart`, `*_screen.dart`
- **Service Registration**: Register all services through GetIt during app initialization
- **Testing**: Unit tests for services, widget tests for adaptive components, integration tests for flows
- **Debugging**: Use Service Inspector screen for real-time service monitoring and testing

### Available Example Screens
The framework includes 10+ example screens demonstrating all features:
- **Adaptive UI**: Live UI system switching demo
- **Services Demo**: Interactive testing of all services  
- **Components**: Comprehensive adaptive component showcase
- **Service Inspector**: Real-time debugging and monitoring
- **Navigation Demo**: Platform-aware transitions and back button behavior
- **Settings**: Complete settings management with persistence

All settings automatically persist across app restarts using SharedPreferences with reactive effects.