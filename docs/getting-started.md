# Getting Started with Flutter App Shell

Welcome! This guide will help you create your first Flutter App Shell application in just a few minutes. Flutter App Shell is designed to get you from zero to a fully-featured app with minimal boilerplate.

## 🎯 What You'll Build

By the end of this guide, you'll have a complete Flutter app with:
- ✅ Adaptive UI that works on mobile, tablet, and desktop
- ✅ Navigation system that automatically adjusts to screen size
- ✅ Settings persistence and theme switching
- ✅ Multiple services ready for your business logic
- ✅ Service inspector for debugging
- ✅ Plugin system for extending capabilities

**Estimated time: 5-10 minutes**

## 📋 Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart 3.0 or higher
- Your favorite code editor (VS Code, Android Studio, etc.)

## 🚀 Step 1: Create Your Project

### Option A: Clone the Framework
```bash
git clone https://github.com/your-org/flutter_ps_app_shell.git my_app
cd my_app
flutter pub get
```

### Option B: Add as Dependency
```bash
flutter create my_app
cd my_app
```

Add to your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_app_shell:
    git:
      url: https://github.com/your-org/flutter_ps_app_shell.git
      path: packages/flutter_app_shell
```

```bash
flutter pub get
```

## 🏗️ Step 2: Basic App Setup

Replace your `lib/main.dart` with this minimal setup:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My First App Shell App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => const HomeScreen(),
        ),
        AppRoute(
          title: 'Profile',
          path: '/profile',
          icon: Icons.person,
          builder: (context, state) => const ProfileScreen(),
        ),
        AppRoute(
          title: 'Settings',
          path: '/settings',
          icon: Icons.settings,
          builder: (context, state) => const AppShellSettingsScreen(),
        ),
      ],
    );
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch,
            size: 64,
            color: styles.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Flutter App Shell!',
            style: styles.headlineStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your app is ready to go with adaptive UI,\nservices, and navigation.',
            style: styles.bodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ui.button(
            label: 'Get Started',
            onPressed: () {
              getIt<NavigationService>().goToPath('/profile');
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Profile',
            style: styles.headlineStyle,
          ),
          const SizedBox(height: 24),
          ui.listSection(
            header: const Text('Personal Information'),
            children: [
              ui.listTile(
                title: const Text('Name'),
                subtitle: const Text('John Doe'),
                leading: const Icon(Icons.person),
              ),
              ui.listTile(
                title: const Text('Email'),
                subtitle: const Text('john.doe@example.com'),
                leading: const Icon(Icons.email),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ui.button(
            label: 'Edit Profile',
            onPressed: () {
              ui.showSnackBar(
                context: context,
                content: const Text('Edit functionality coming soon!'),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## 🎨 Step 3: Run Your App

```bash
flutter run
```

🎉 **Congratulations!** You now have a working Flutter App Shell application with:

- **Adaptive navigation** that automatically switches between bottom tabs, navigation rail, and sidebar based on screen size
- **Three different screens** demonstrating various UI components
- **Settings screen** with theme switching and UI system selection
- **Responsive design** that works on mobile, tablet, and desktop

## 🧪 Step 4: Explore the Features

### Try Different UI Systems
1. Go to the Settings tab
2. Switch between Material, Cupertino, and ForUI
3. Notice how the entire app adapts its visual style

### Test Responsive Behavior
1. Resize your app window (on desktop)
2. Watch the navigation automatically adapt:
   - **Small**: Bottom tabs
   - **Medium**: Navigation rail
   - **Large**: Full sidebar

### Check Settings Persistence
1. Change theme mode (Light/Dark/System)
2. Switch UI systems
3. Restart your app - settings are automatically saved!

## 🔧 Step 5: Add Your First Service

Let's add a simple data service to demonstrate the service architecture:

```dart
// lib/services/todo_service.dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

class TodoService {
  static TodoService? _instance;
  static TodoService get instance => _instance ??= TodoService._();
  TodoService._();

  final List<Todo> _todos = [];
  final _todosSignal = ListSignal<Todo>([]);

  List<Todo> get todos => _todosSignal.value;
  ListSignal<Todo> get todosSignal => _todosSignal;

  void addTodo(String title) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      completed: false,
    );
    _todos.add(todo);
    _todosSignal.value = List.from(_todos);
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(completed: !_todos[index].completed);
      _todosSignal.value = List.from(_todos);
    }
  }
}

class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, required this.completed});

  Todo copyWith({String? title, bool? completed}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
```

Register the service in your `main.dart`:

```dart
void main() {
  runShellApp(() async {
    // Register your custom service
    getIt.registerSingleton<TodoService>(TodoService.instance);
    
    return AppConfig(
      // ... rest of your config
    );
  });
}
```

## 🎯 What's Next?

Now that you have a basic app running, here are some next steps:

### 📚 Learn More
- [Architecture Overview](architecture.md) - Understand how everything works together
- [UI Systems Guide](ui-systems/README.md) - Deep dive into adaptive UI
- [Services Documentation](services/README.md) - Explore all available services

### 🔧 Add Features
- [Database Service](services/database.md) - Add local storage with cloud sync
- [Authentication](services/authentication.md) - Add user authentication
- [File Storage](services/file-storage.md) - Handle file uploads and downloads

### 🌟 Advanced Topics
- [Custom Services](advanced/custom-services.md) - Create your own services
- [Cloud Integration](cloud/instantdb.md) - Add InstantDB for real-time features
- [Performance](advanced/performance.md) - Optimize your app

## 💡 Tips for Success

### 1. Use the Service Inspector
The Service Inspector is your best friend for debugging. Access it through the settings screen or add it as a route:

```dart
AppRoute(
  title: 'Inspector',
  path: '/inspector',
  icon: Icons.bug_report,
  builder: (context, state) => const ServiceInspectorScreen(),
),
```

### 2. Follow the Adaptive Pattern
Always use the adaptive factory for UI components:

```dart
// ✅ Good - Adaptive
final ui = getAdaptiveFactory(context);
ui.button(label: 'Click me', onPressed: () {});

// ❌ Bad - Platform-specific
ElevatedButton(onPressed: () {}, child: Text('Click me'));
```

### 3. Use Signals for State
Leverage the reactive state management:

```dart
final counter = signal(0);

// In your widget
Watch((context) => Text('Count: ${counter.value}'))

// Update anywhere
counter.value++;
```

### 4. Leverage Settings Persistence
User preferences are automatically saved:

```dart
final settings = getIt<AppShellSettingsStore>();
settings.uiSystem.value = 'cupertino'; // Automatically persisted
```

## 🔌 Step 7: Using Plugins (Optional)

Flutter App Shell supports plugins to extend functionality:

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  // Create or import plugins
  final analyticsPlugin = AnalyticsPlugin();
  final chartPlugin = ChartWidgetPlugin();
  
  runShellApp(
    () async => AppConfig(
      title: 'My App with Plugins',
      routes: [...],
    ),
    enablePlugins: true,
    pluginConfiguration: {
      'manualPlugins': [analyticsPlugin, chartPlugin],
    },
  );
}

// Use plugin services
final analytics = getIt<AnalyticsService>();
await analytics.trackEvent('app_started');
```

### Plugin Types Available:
- **Service Plugins**: Add business logic services (analytics, payment, etc.)
- **Widget Plugins**: Custom UI components that adapt to all UI systems
- **Theme Plugins**: Create completely custom UI systems
- **Workflow Plugins**: Automation and background processing

Learn more about plugins in the [Plugin System documentation](plugin-system.md).

## 🆘 Getting Help

- **Documentation**: Browse the [full documentation](README.md)
- **Plugin System**: Learn about [extending with plugins](plugin-system.md)
- **Examples**: Check out the [example app](../example/) for more complex usage
- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-org/flutter_ps_app_shell/issues)
- **Troubleshooting**: See the [troubleshooting guide](reference/troubleshooting.md)

## 🎉 You're Ready!

You now have a solid foundation with Flutter App Shell. The framework handles the boilerplate so you can focus on building your app's unique features. Happy coding! 🚀

---

**Next:** [Architecture Overview](architecture.md) to understand how everything works together.