# Adaptive UI Systems Guide

Flutter App Shell's adaptive UI system is one of its most powerful features, allowing your entire app to switch between different design systems at runtime while maintaining consistent functionality and behavior.

## 🎨 Supported UI Systems

### Material Design 3
Google's latest design system featuring:
- **Vibrant colors** with blue primary palette
- **Heavy elevation** (24px shadows) for depth
- **Rounded corners** (16px radius) for modern feel
- **Material You** theming capabilities
- **Ripple effects** and animations

### Cupertino (iOS)
Apple's native iOS design language:
- **Native iOS controls** and styling
- **System gray backgrounds** and colors
- **Modal presentations** for pickers and dialogs
- **iOS-style navigation** patterns
- **Grouped list sections** for settings

### ForUI (Minimal Modern)
A clean, modern design system:
- **Flat design** with no shadows or elevation
- **Sharp corners** (4px radius) for crisp appearance
- **Zinc color palette** (grays and light colors)
- **High contrast** for accessibility
- **Minimalist aesthetic**

## 🔄 How It Works

### Runtime Switching
The entire app can switch between UI systems instantly:

```dart
final settingsStore = getIt<AppShellSettingsStore>();

// Switch to Cupertino UI
settingsStore.uiSystem.value = 'cupertino';

// Switch to Material UI  
settingsStore.uiSystem.value = 'material';

// Switch to ForUI
settingsStore.uiSystem.value = 'forui';
```

### Automatic Persistence
UI system preference is automatically saved and restored:
- Settings persist across app restarts
- User's choice is remembered
- No manual save/load required

## 🏭 Factory Pattern Implementation

### Abstract Factory
All UI components are created through an abstract factory:

```dart
abstract class AdaptiveWidgetFactory {
  // Core UI components
  Widget button({required String label, required VoidCallback onPressed});
  Widget textField({
    String? labelText, 
    ValueChanged<String>? onChanged,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsets? prefixIconPadding,
    EdgeInsets? suffixIconPadding,
  });
  Widget scaffold({required Widget body, Widget? appBar});
  
  // Extended components  
  Future<DateTime?> showDatePicker({required BuildContext context, ...});
  Future<TimeOfDay?> showTimePicker({required BuildContext context, ...});
  Widget rangeSlider({required RangeValues values, ...});
  
  // Navigation helpers
  Widget navigationRail({required List<AppRoute> routes, ...});
  bool shouldAddDrawerButton();
  bool needsDesktopPadding();
}
```

### Concrete Implementations
Each UI system has its own factory implementation:

```dart
// Material implementation
class MaterialWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget button({required String label, required VoidCallback onPressed}) {
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
  
  @override
  Future<DateTime?> showDatePicker({...}) {
    return material.showDatePicker(
      context: context,
      // Material-specific theming with blue colors and elevation
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            elevation: 24, // Heavy Material elevation
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
            // Blue color scheme...
          ),
        ),
        child: child!,
      ),
    );
  }
}

// Cupertino implementation  
class CupertinoWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget button({required String label, required VoidCallback onPressed}) {
    return CupertinoButton.filled(
      onPressed: onPressed,
      child: Text(label),
    );
  }
  
  @override
  Future<DateTime?> showDatePicker({...}) {
    // Native iOS modal date picker
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 216,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (date) => selectedDate = date,
        ),
      ),
    );
  }
}

// ForUI implementation
class ForUIWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget button({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0, // Flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Sharp corners
        ),
      ),
      child: Text(label),
    );
  }
  
  @override
  Future<DateTime?> showDatePicker({...}) {
    return material.showDatePicker(
      context: context,
      // ForUI-specific theming with flat design and zinc colors
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          dialogTheme: DialogThemeData(
            elevation: 0, // No shadows
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4), // Sharp corners
              side: BorderSide(color: Color(0xFFD4D4D8), width: 2), // Border
            ),
          ),
          // Zinc color palette...
        ),
        child: child!,
      ),
    );
  }
}
```

## 📱 Usage in Your App

### Getting the Factory
Always use the adaptive factory in your widgets:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;
    
    return ui.scaffold(
      body: Column(
        children: [
          ui.button(
            label: 'Adaptive Button',
            onPressed: () {},
          ),
          ui.textField(
            labelText: 'Adaptive Input',
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
```

### Reactive Updates
Use Watch widgets to automatically rebuild when UI system changes:

```dart
class AdaptiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();
    
    return Watch((context) {
      // Automatically rebuilds when UI system changes
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);
      
      return ui.scaffold(
        key: ValueKey('scaffold_$uiSystem'), // Force rebuild
        body: ui.button(
          label: 'Current UI: $uiSystem',
          onPressed: () {},
        ),
      );
    });
  }
}
```

## 🎨 Visual Differences

### Button Styles
| UI System | Style | Colors | Shape |
|-----------|--------|---------|--------|
| Material | FilledButton | Blue primary | Rounded (16px) |
| Cupertino | CupertinoButton.filled | iOS Blue | Rounded (8px) |
| ForUI | ElevatedButton (flat) | Zinc/Gray | Sharp (4px) |

### Date/Time Pickers
| UI System | Presentation | Colors | Styling |
|-----------|-------------|---------|----------|
| Material | Dialog | Blue theme, heavy elevation (24px) | Rounded corners |
| Cupertino | Modal popup | iOS system colors | Native wheel picker |
| ForUI | Dialog | Zinc palette, flat design (0px elevation) | Sharp borders |

### List Sections  
| UI System | Style | Background | Spacing |
|-----------|--------|------------|----------|
| Material | Card with elevation | White with blue tint | 8px margin |
| Cupertino | Grouped sections | System gray | Inset grouped style |
| ForUI | Bordered container | Light gray | Flat with borders |

## 🔧 Component Library

### Core Components (30+ Widgets)
- **Layout**: scaffold, appBar, drawer, navigationRail
- **Buttons**: button, iconButton, textButton, outlinedButton
- **Inputs**: textField, checkbox, radio, switch, slider
- **Lists**: listTile, listSection, divider
- **Display**: card, avatar, badge, chip
- **Feedback**: progressIndicator, snackBar, dialog
- **Navigation**: tabBar, segmentedControl, stepper

### Extended Components
- **Date/Time**: datePicker, timePicker, dateRangePicker
- **Controls**: rangeSlider, toggleButtons, expansionTile
- **Data**: chip variations (action, choice, filter)
- **Layout**: tooltip, badge with advanced positioning

### Navigation Helpers
- **Responsive**: Automatic navigation adaptation
- **Platform-specific**: Drawer button handling
- **Desktop**: Safe area and padding management

## 🔎 TextField with Icons

The `textField` component supports prefix and suffix icons with customizable padding:

### Basic Usage

```dart
ui.textField(
  labelText: 'Search',
  hintText: 'Search for something...',
  prefixIcon: const Icon(Icons.search),
  suffixIcon: IconButton(
    icon: const Icon(Icons.clear),
    onPressed: () => controller.clear(),
  ),
)
```

### Advanced Icon Configuration

```dart
ui.textField(
  labelText: 'Email',
  hintText: 'user@example.com',
  prefixIcon: const Icon(Icons.email_outlined),
  suffixIcon: const Icon(Icons.check_circle, color: Colors.green),
  prefixIconPadding: const EdgeInsets.only(left: 12, right: 8),
  suffixIconPadding: const EdgeInsets.only(left: 8, right: 12),
  keyboardType: TextInputType.emailAddress,
)
```

### Platform-Specific Behavior

| UI System | Implementation | Icon Styling | Padding Defaults |
|-----------|----------------|--------------|------------------|
| Material | `InputDecoration.prefixIcon/suffixIcon` | Inherits theme colors | Material design spacing |
| Cupertino | `CupertinoTextField.prefix/suffix` | Wrapped in Padding | iOS-style spacing (8px/4px) |
| ForUI | `InputDecoration` with `IconTheme` | Muted foreground color, 16px size | Minimal spacing (8px/4px) |

### Interactive Icons

```dart
ui.textField(
  labelText: 'Password',
  obscureText: !_passwordVisible,
  prefixIcon: const Icon(Icons.lock_outline),
  suffixIcon: IconButton(
    icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
  ),
)
```

## 📐 Responsive Behavior

### Automatic Layout Adaptation
The navigation system automatically adapts based on screen size:

```dart
// Mobile (<600px)
if (routes.length <= 5) {
  // Bottom navigation tabs
  return BottomNavigationBar(...);
} else {
  // Drawer with hamburger menu
  return Drawer(...);
}

// Tablet (600-1200px)  
return NavigationRail(
  extended: showLabels,
  destinations: [...],
);

// Desktop (>1200px)
return NavigationSidebar(
  collapsed: sidebarCollapsed,
  destinations: [...],
);
```

### Platform-Specific Behavior
Each UI system handles responsive behavior differently:

```dart
// Material - automatic drawer handling
class MaterialWidgetFactory {
  @override
  bool shouldAddDrawerButton() => false; // Scaffold handles it
  
  @override  
  bool needsDesktopPadding() => true; // Manual padding needed
}

// Cupertino - manual drawer button needed
class CupertinoWidgetFactory {
  @override
  bool shouldAddDrawerButton() => true; // Manual button required
  
  @override
  bool needsDesktopPadding() => false; // Handles own padding
}
```

## 🎛️ Customization

### Adding New UI Systems
You can extend the framework with custom UI systems:

```dart
// 1. Create your factory
class MyCustomWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget button({required String label, required VoidCallback onPressed}) {
    return MyCustomButton(
      label: label,
      onPressed: onPressed,
      style: MyCustomStyle(),
    );
  }
  
  // Implement all required methods...
}

// 2. Register the factory
void registerCustomUISystem() {
  registerAdaptiveFactory('my_custom', () => MyCustomWidgetFactory());
}

// 3. Use in your app
settingsStore.uiSystem.value = 'my_custom';
```

### Theming Individual Systems
Each system can be customized with themes:

```dart
// Material theming
MaterialApp(
  theme: ThemeData.from(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
    useMaterial3: true,
  ),
)

// Cupertino theming  
CupertinoApp(
  theme: CupertinoThemeData(
    primaryColor: CupertinoColors.systemPurple,
    brightness: Brightness.light,
  ),
)

// ForUI theming (custom)
ThemeData.light().copyWith(
  colorScheme: ColorScheme.light(
    primary: Color(0xFF6366F1), // Custom purple
    surface: Color(0xFFF8FAFC), // Custom background
  ),
)
```

## 🧪 Testing Adaptive UI

### Testing Different UI Systems
```dart
void main() {
  group('Adaptive Button Tests', () {
    testWidgets('renders Material button in material mode', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          uiSystem: 'material',
          child: MyWidget(),
        ),
      );
      
      expect(find.byType(FilledButton), findsOneWidget);
    });
    
    testWidgets('renders Cupertino button in cupertino mode', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          uiSystem: 'cupertino', 
          child: MyWidget(),
        ),
      );
      
      expect(find.byType(CupertinoButton), findsOneWidget);
    });
  });
}
```

### Testing Responsive Behavior
```dart
testWidgets('shows bottom nav on mobile', (tester) async {
  tester.binding.window.physicalSizeTestValue = Size(400, 800); // Mobile size
  
  await tester.pumpWidget(MyApp());
  
  expect(find.byType(BottomNavigationBar), findsOneWidget);
  expect(find.byType(NavigationRail), findsNothing);
});

testWidgets('shows navigation rail on tablet', (tester) async {
  tester.binding.window.physicalSizeTestValue = Size(800, 600); // Tablet size
  
  await tester.pumpWidget(MyApp());
  
  expect(find.byType(NavigationRail), findsOneWidget);
  expect(find.byType(BottomNavigationBar), findsNothing);
});
```

## 💡 Best Practices

### 1. Always Use Adaptive Factory
```dart
// ✅ Good - Adaptive
final ui = getAdaptiveFactory(context);
ui.button(label: 'Click me', onPressed: () {});

// ❌ Bad - Platform-specific  
FilledButton(onPressed: () {}, child: Text('Click me'));
```

### 2. Use Watch for Reactive Updates
```dart
// ✅ Good - Reactive to UI system changes
Watch((context) {
  final ui = getAdaptiveFactory(context);
  return ui.button(label: 'Adaptive', onPressed: () {});
})

// ❌ Bad - Won't update when UI system changes
Widget build(BuildContext context) {
  final ui = getAdaptiveFactory(context);
  return ui.button(label: 'Static', onPressed: () {});
}
```

### 3. Provide Unique Keys for System Changes
```dart
// ✅ Good - Forces rebuild on UI system change
return Watch((context) {
  final uiSystem = settingsStore.uiSystem.value;
  return ui.scaffold(
    key: ValueKey('scaffold_$uiSystem'),
    body: myContent,
  );
});
```

### 4. Handle Platform Differences Gracefully
```dart
// Some UI systems may not have certain components
if (ui is CupertinoWidgetFactory) {
  // Cupertino doesn't have native range slider
  // Factory will provide Material fallback
}

final dateTime = await ui.showDatePicker(...);
// Handle the case where user cancels (returns null)
if (dateTime != null) {
  // Use the selected date
}
```

## 🔗 Related Guides

- **[Getting Started](../getting-started.md)** - Basic setup with adaptive UI
- **[Material Design](material.md)** - Deep dive into Material implementation  
- **[Cupertino](cupertino.md)** - iOS-specific features and behavior
- **[ForUI](forui.md)** - Modern minimal design system
- **[Component Reference](components.md)** - Complete component documentation
- **[Architecture](../architecture.md)** - How adaptive UI fits in the overall architecture

The adaptive UI system is designed to give you maximum flexibility while maintaining consistency and a great user experience across all platforms. Start with the basics and gradually explore the advanced customization options! 🎨