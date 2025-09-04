# AppShell Action Navigation Guide

The Flutter App Shell provides powerful navigation capabilities through the `AppShellAction` class, enabling clean, declarative navigation without requiring service locators or global state management.

## Overview

AppShellAction supports three different navigation patterns:

1. **Declarative Route Navigation** - Simple, clean route-based navigation
2. **Context-Aware Navigation** - Full control with BuildContext access
3. **Traditional Callbacks** - Backward compatible VoidCallback pattern

## Navigation Patterns

### 1. Declarative Route Navigation

The simplest way to navigate to a route. Perfect for straightforward navigation scenarios.

```dart
AppShellAction.route(
  icon: Icons.settings,
  tooltip: 'Settings',
  route: '/settings',
)
```

**Features:**
- Automatic navigation handling
- Clean, declarative syntax
- Supports both `go` and `replace` navigation
- No boilerplate code required

**Advanced Usage:**
```dart
AppShellAction.route(
  icon: Icons.home,
  tooltip: 'Home',
  route: '/',
  useReplace: true, // Use replace instead of go
)
```

### 2. Context-Aware Navigation

Provides full control with access to BuildContext. Ideal for conditional navigation or complex routing scenarios.

```dart
AppShellAction.navigate(
  icon: Icons.profile,
  tooltip: 'Profile',
  onNavigate: (context) {
    // Full context access for conditional navigation
    if (userLoggedIn) {
      context.go('/profile');
    } else {
      context.go('/login');
    }
  },
)
```

**Use Cases:**
- Conditional navigation based on app state
- Navigation with parameters or query strings
- Custom navigation logic
- Push vs Go decisions based on context

**Examples:**
```dart
// Push navigation (stacks screens)
AppShellAction.navigate(
  icon: Icons.info,
  tooltip: 'Details',
  onNavigate: (context) => context.push('/details'),
)

// Navigation with parameters
AppShellAction.navigate(
  icon: Icons.user,
  tooltip: 'User Profile',
  onNavigate: (context) => context.go('/user/profile?id=123'),
)

// Conditional navigation
AppShellAction.navigate(
  icon: Icons.admin_panel_settings,
  tooltip: 'Admin Panel',
  onNavigate: (context) {
    final user = context.read<UserProvider>().user;
    if (user.isAdmin) {
      context.push('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin access required')),
      );
    }
  },
)
```

### 3. Traditional Callbacks (Backward Compatible)

Maintains compatibility with existing code that uses VoidCallback for non-navigation actions.

```dart
AppShellAction.callback(
  icon: Icons.notifications,
  tooltip: 'Notifications',
  onPressed: () {
    // Non-navigation action
    NotificationService.showNotifications();
  },
)
```

## Migration Guide

### Before (Required Service Locator)

```dart
AppShellAction(
  icon: Icons.settings,
  tooltip: 'Settings',
  onPressed: () {
    final navigationService = GetIt.I<NavigationService>();
    navigationService.go('/settings');
  },
)
```

### After (Clean & Direct)

```dart
// Option 1: Declarative route
AppShellAction.route(
  icon: Icons.settings,
  tooltip: 'Settings',
  route: '/settings',
)

// Option 2: Context-aware
AppShellAction.navigate(
  icon: Icons.settings,
  tooltip: 'Settings',
  onNavigate: (context) => context.go('/settings'),
)
```

## Best Practices

### When to Use Each Pattern

**Use Declarative Route Navigation when:**
- Simple route navigation without conditions
- You want the cleanest, most readable code
- Navigation doesn't require context or state checking

**Use Context-Aware Navigation when:**
- Navigation depends on app state or user conditions
- You need to pass parameters or query strings
- You want to choose between push/go based on context
- You need to show dialogs or snackbars alongside navigation

**Use Traditional Callbacks when:**
- The action doesn't involve navigation
- You need backward compatibility with existing code
- The action involves complex non-navigation logic

### Code Organization

```dart
// Group related actions together
final List<AppShellAction> userActions = [
  AppShellAction.route(
    icon: Icons.person,
    tooltip: 'Profile',
    route: '/profile',
  ),
  AppShellAction.route(
    icon: Icons.settings,
    tooltip: 'Settings', 
    route: '/settings',
  ),
  AppShellAction.navigate(
    icon: Icons.logout,
    tooltip: 'Logout',
    onNavigate: (context) => _handleLogout(context),
  ),
];
```

### Error Handling

The AppShell ActionButton automatically handles navigation errors with fallback mechanisms:

1. Primary: GoRouter navigation
2. Fallback: Traditional Navigator navigation  
3. Logging: All errors are logged for debugging

```dart
// Error handling is automatic, but you can add custom handling
AppShellAction.navigate(
  icon: Icons.risky_action,
  tooltip: 'Risky Action',
  onNavigate: (context) {
    try {
      context.go('/risky-route');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $e')),
      );
    }
  },
)
```

## Toggle Actions with Navigation

Toggle actions can also include navigation:

```dart
AppShellAction(
  icon: Icons.favorite_border,
  toggledIcon: Icons.favorite,
  tooltip: 'Add to Favorites',
  toggledTooltip: 'Remove from Favorites',
  isToggleable: true,
  initialValue: false,
  onToggle: (isFavorited) {
    // Handle toggle state
    FavoriteService.setFavorite(itemId, isFavorited);
  },
  route: '/favorites', // Navigate after toggle
)
```

## Testing Navigation Actions

```dart
testWidgets('AppShellAction navigation works', (WidgetTester tester) async {
  // Mock GoRouter
  final mockRouter = MockGoRouter();
  
  await tester.pumpWidget(
    GoRouterProvider(
      goRouter: mockRouter,
      child: ActionButton(
        action: AppShellAction.route(
          icon: Icons.settings,
          tooltip: 'Settings',
          route: '/settings',
        ),
      ),
    ),
  );
  
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
  
  verify(mockRouter.go('/settings')).called(1);
});
```

## Advanced Examples

### Dynamic Route Generation

```dart
AppShellAction.navigate(
  icon: Icons.folder,
  tooltip: 'Open Project',
  onNavigate: (context) {
    final projectId = ProjectService.getCurrentProjectId();
    context.go('/project/$projectId/dashboard');
  },
)
```

### Navigation with State Management

```dart
AppShellAction.navigate(
  icon: Icons.shopping_cart,
  tooltip: 'Cart',
  onNavigate: (context) {
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.items.isEmpty) {
      context.go('/shop');
    } else {
      context.go('/cart');
    }
  },
)
```

### Confirmation Dialogs

```dart
AppShellAction.navigate(
  icon: Icons.delete_forever,
  tooltip: 'Delete All',
  onNavigate: (context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.go('/deleted-items');
    }
  },
)
```

## API Reference

### AppShellAction Properties

| Property | Type | Description |
|----------|------|-------------|
| `icon` | `IconData` | Action icon |
| `tooltip` | `String` | Tooltip text |
| `route` | `String?` | Route for declarative navigation |
| `onNavigate` | `Function(BuildContext)?` | Context-aware navigation callback |
| `onPressed` | `VoidCallback?` | Traditional callback |
| `useReplace` | `bool` | Use replace instead of go (default: false) |
| `showInDrawer` | `bool` | Show in mobile drawer (default: false) |
| `customWidget` | `Widget?` | Custom widget override |

### Factory Constructors

- `AppShellAction.route()` - Declarative route navigation
- `AppShellAction.navigate()` - Context-aware navigation  
- `AppShellAction.callback()` - Traditional callback

### Navigation Priority

When multiple navigation/action properties are specified, the priority is:

1. `route` (highest priority)
2. `onNavigate` 
3. `onPressed` (lowest priority)

This ensures predictable behavior and allows for gradual migration from callbacks to navigation-based actions.