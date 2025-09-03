# Adaptive SnackBars

The Flutter App Shell provides platform-adaptive snackbar implementations that automatically adapt to different UI systems (Material, Cupertino, ForUI) while maintaining a consistent API.

## Table of Contents
- [Quick Start](#quick-start)
- [Platform Behavior](#platform-behavior)
- [API Reference](#api-reference)
- [Implementation Details](#implementation-details)
- [Examples](#examples)
- [Migration Guide](#migration-guide)

## Quick Start

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

// Get the adaptive factory
final ui = getAdaptiveFactory(context);

// Show a simple snackbar
ui.showSnackBar(
  context: context,
  message: 'File uploaded successfully',
);

// Show with action button
ui.showSnackBar(
  context: context,
  message: 'Item deleted',
  action: SnackBarAction(
    label: 'UNDO',
    onPressed: () => restoreItem(),
  ),
);

// Show with custom duration and color
ui.showSnackBar(
  context: context,
  message: 'Network connection restored',
  duration: const Duration(seconds: 5),
  backgroundColor: Colors.green,
);
```

## Platform Behavior

### Material Design
- **Position**: Bottom of screen
- **Animation**: Slides up from bottom
- **Style**: Material Design 3 elevated card
- **Implementation**: Uses ScaffoldMessenger.showSnackBar()

### Cupertino (iOS)
- **Position**: Top of screen (iOS notification style)
- **Animation**: Slides down from top with blur effect
- **Style**: iOS-style notification with rounded corners and blur background
- **Implementation**: Custom overlay-based notification system
- **Dismissal**: Swipe up to dismiss or auto-dismiss after duration
- **✅ Fixed**: No longer requires ScaffoldMessenger (works with CupertinoApp)

### ForUI
- **Position**: Bottom of screen
- **Animation**: Fade and slide combination
- **Style**: Clean, flat design with ForUI's zinc color palette
- **Implementation**: Uses ScaffoldMessenger.showSnackBar() with ForUI styling

## API Reference

### showSnackBar Method

```dart
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar({
  required BuildContext context,
  required String message,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
  Color? backgroundColor,
})
```

**Parameters:**
- `context`: BuildContext (required)
- `message`: The text to display (required)
- `action`: Optional action button
- `duration`: How long to show the snackbar (default: 4 seconds)
- `backgroundColor`: Custom background color

**Returns:** ScaffoldFeatureController that can be used to programmatically dismiss the snackbar

## Implementation Details

### Cupertino iOS-Style Notifications

The Cupertino implementation uses a custom overlay-based approach to provide authentic iOS-style notifications:

1. **Overlay Entry**: Creates an overlay entry positioned at the top of the screen
2. **Blur Effect**: Applies iOS-style blur background using BackdropFilter
3. **Animation**: SlideTransition with CurvedAnimation for smooth iOS feel
4. **Gesture Detection**: GestureDetector for swipe-to-dismiss
5. **Auto-dismiss**: Timer-based dismissal after specified duration

Key classes:
- `_CupertinoNotificationController`: Manages overlay lifecycle
- `_CupertinoSnackBarController`: Implements ScaffoldFeatureController interface
- `_CupertinoNotificationWidget`: The actual iOS-style notification UI

### Material/ForUI Implementation

Both Material and ForUI use the standard ScaffoldMessenger approach with platform-specific styling:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor ?? theme.snackBarTheme.backgroundColor,
    action: action,
    duration: duration,
  ),
)
```

## Examples

### Success Notification
```dart
ui.showSnackBar(
  context: context,
  message: '✅ Changes saved successfully',
  backgroundColor: Colors.green.shade600,
);
```

### Error with Retry
```dart
ui.showSnackBar(
  context: context,
  message: 'Failed to load data',
  backgroundColor: Colors.red.shade600,
  action: SnackBarAction(
    label: 'RETRY',
    textColor: Colors.white,
    onPressed: () => retryOperation(),
  ),
);
```

### Info with Long Duration
```dart
ui.showSnackBar(
  context: context,
  message: 'New update available. Tap to install.',
  duration: const Duration(seconds: 10),
  action: SnackBarAction(
    label: 'UPDATE',
    onPressed: () => startUpdate(),
  ),
);
```

### Programmatic Dismissal
```dart
final controller = ui.showSnackBar(
  context: context,
  message: 'Processing...',
  duration: const Duration(minutes: 1),
);

// Later, dismiss it
controller.close();

// Or wait for it to be closed
await controller.closed;
```

## Migration Guide

### From Direct ScaffoldMessenger Usage

**Before:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Message'),
    action: SnackBarAction(
      label: 'ACTION',
      onPressed: () {},
    ),
  ),
);
```

**After:**
```dart
final ui = getAdaptiveFactory(context);
ui.showSnackBar(
  context: context,
  message: 'Message',
  action: SnackBarAction(
    label: 'ACTION',
    onPressed: () {},
  ),
);
```

### Handling CupertinoApp Contexts

Previously, using snackbars in Cupertino mode would fail with "ScaffoldMessenger not found" errors. This is now fixed:

```dart
// This now works correctly in CupertinoApp contexts
ui.showSnackBar(
  context: context,
  message: 'Works in Cupertino mode!',
);
```

## Best Practices

1. **Keep messages concise**: Snackbars should display brief, actionable messages
2. **Use appropriate colors**: Green for success, red for errors, default for neutral
3. **Provide actions when relevant**: Allow users to undo, retry, or take action
4. **Consider duration**: Longer messages need more time to read
5. **Test across platforms**: Ensure your snackbars work well in all UI systems

## Troubleshooting

### ✅ FIXED: "ScaffoldMessenger not found" in Cupertino Mode
This issue has been resolved. The Cupertino implementation now uses a custom overlay-based approach that doesn't require ScaffoldMessenger.

### Snackbar not appearing
Ensure you're calling showSnackBar from a context that has access to the MaterialApp/CupertinoApp root.

### Custom styling not applied
Some platforms have limited styling options. The backgroundColor parameter works across all platforms, but other customizations may be platform-specific.