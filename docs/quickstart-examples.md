# Quick Start Examples

Practical examples to get you started quickly.

## Minimal App

The absolute minimum code to create a working app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runShellApp(
    appConfig: AppConfig(
      title: 'Minimal App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => Center(child: Text('Hello World!')),
        ),
      ],
    ),
  );
}
```

## Multi-Screen App

App with navigation between screens:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runShellApp(
    appConfig: AppConfig(
      title: 'My App',
      routes: [
        AppRoute(
          title: 'Dashboard',
          path: '/',
          icon: Icons.dashboard,
          builder: (context, state) => const DashboardScreen(),
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
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ui.pageTitle('Dashboard'),
        const SizedBox(height: 16),
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Welcome to your dashboard!'),
          ),
        ),
      ],
    );
  }
}
```

## Adaptive UI

Switch between Material, Cupertino, and ForUI at runtime:

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ListView(
      children: [
        ui.pageTitle('Adaptive Components'),
        ui.button(label: 'Click Me', onPressed: () {}),
        ui.textField(labelText: 'Name'),
        ui.card(child: Text('Card content')),
      ],
    );
  }
}
```

UI automatically adapts based on user preference in Settings.

## With Authentication

Add user authentication:

```dart
class AuthDemoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthenticationService>();

    return Watch((context) {
      if (auth.isAuthenticated.value) {
        final user = auth.currentUser.value!;
        return Column(
          children: [
            Text('Welcome, ${user.name}!'),
            ElevatedButton(
              onPressed: () => auth.signOut(),
              child: Text('Sign Out'),
            ),
          ],
        );
      }

      return ElevatedButton(
        onPressed: () async {
          await auth.signInWithMagicLink('user@example.com');
        },
        child: Text('Sign In'),
      );
    });
  }
}
```

## With Database

Real-time database operations:

```dart
class TasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = getIt<DatabaseService>();
    final ui = getAdaptiveFactory(context);

    return Watch((context) {
      // Real-time query that auto-updates
      final tasksSignal = db.watchCollection('tasks');
      final tasks = tasksSignal.value;

      if (!tasks.hasData) {
        return CircularProgressIndicator();
      }

      return ListView.builder(
        itemCount: tasks.data!.length,
        itemBuilder: (context, index) {
          final task = tasks.data![index];
          return ui.listTile(
            title: Text(task['title']),
            subtitle: Text(task['status']),
            onTap: () => context.push('/task/${task['id']}'),
          );
        },
      );
    });
  }

  Future<void> _addTask() async {
    final db = getIt<DatabaseService>();
    await db.create('tasks', {
      'title': 'New Task',
      'status': 'todo',
      'created': DateTime.now().toIso8601String(),
    });
    // UI updates automatically!
  }
}
```

## Programmatic Navigation

Navigate without showing UI navigation:

```dart
void main() async {
  await runShellApp(
    appConfig: AppConfig(
      title: 'Wizard App',
      hideNavigation: true,  // Hide all nav UI
      routes: [
        AppRoute(
          title: 'Step 1',
          path: '/',
          icon: Icons.looks_one,
          builder: (context, state) => Step1Screen(),
        ),
        AppRoute(
          title: 'Step 2',
          path: '/step2',
          icon: Icons.looks_two,
          builder: (context, state) => Step2Screen(),
        ),
      ],
    ),
  );
}

class Step1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Welcome to Step 1'),
        ElevatedButton(
          onPressed: () => context.push('/step2'),
          child: Text('Next'),
        ),
      ],
    );
  }
}
```

## Custom Service

Create and register a custom service:

```dart
// 1. Define service
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  void trackEvent(String event) {
    print('Event tracked: $event');
  }
}

// 2. Register in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register custom service
  getIt.registerSingleton<AnalyticsService>(AnalyticsService.instance);

  await runShellApp(/* ... */);
}

// 3. Use anywhere
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final analytics = getIt<AnalyticsService>();

    return ElevatedButton(
      onPressed: () {
        analytics.trackEvent('button_clicked');
      },
      child: Text('Track Event'),
    );
  }
}
```

## Next Steps

- 📖 [State Management Guide](state-management.md)
- 🎨 [UI Systems Documentation](ui-systems/README.md)
- 🔧 [Services Documentation](services/README.md)
- 🧭 [Navigation Guide](navigation.md)
