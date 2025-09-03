# Adaptive Dialogs

The Flutter App Shell provides a comprehensive dialog system that automatically adapts to different platforms (Material, Cupertino, ForUI) and screen sizes. This ensures your dialogs look and feel native on every platform while maintaining a consistent API.

## Table of Contents
- [Quick Start](#quick-start)
- [Dialog Types](#dialog-types)
- [API Reference](#api-reference)
- [Platform Behavior](#platform-behavior)
- [Responsive Design](#responsive-design)
- [Examples](#examples)
- [Migration Guide](#migration-guide)
- [Best Practices](#best-practices)

## Quick Start

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

// Get the adaptive factory
final ui = getAdaptiveFactory(context);

// Show a simple confirmation dialog
final confirmed = await ui.showConfirmationDialog(
  context: context,
  title: 'Delete Item?',
  message: 'This action cannot be undone.',
  confirmText: 'Delete',
  isDestructive: true,
);

if (confirmed == true) {
  // User confirmed the action
}
```

## Dialog Types

### 1. Form Dialog
Complex forms with multiple inputs, custom width control, and scrollable content.

**Use Cases:**
- User registration forms
- Settings panels
- Data entry forms
- Multi-step wizards

### 2. Page Modal
Full-screen on mobile devices, centered dialog on desktop. Perfect for detailed content that needs more space.

**Use Cases:**
- Profile editing
- Detailed settings
- Content preview
- Multi-section forms

### 3. Action Sheet
Platform-specific option selection with support for icons and destructive actions.

**Use Cases:**
- Share options
- Export formats
- Action menus
- Quick selections

### 4. Confirmation Dialog
Simple yes/no confirmations with optional destructive styling.

**Use Cases:**
- Delete confirmations
- Permission requests
- Save confirmations
- Warning dialogs

## API Reference

### showFormDialog<T>

Shows a form dialog with custom width and layout support.

```dart
Future<T?> showFormDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget>? actions,
  double? width,              // Desktop width (default: 600-800px)
  double? maxHeight,          // Maximum height constraint
  EdgeInsets? contentPadding, // Custom padding
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  bool scrollable = true,     // Auto-wrap in ScrollView
})
```

**Example:**
```dart
final result = await ui.showFormDialog<bool>(
  context: context,
  title: Text('Create Workspace'),
  width: 700, // Fixed width on desktop
  content: Column(
    children: [
      ui.textField(label: 'Workspace Name'),
      ui.textField(label: 'Description', maxLines: 3),
      ui.switch_(
        value: enableFeature,
        onChanged: (value) => setState(() => enableFeature = value),
      ),
    ],
  ),
  actions: [
    ui.textButton(
      label: 'Cancel',
      onPressed: () => Navigator.pop(context, false),
    ),
    ui.button(
      label: 'Create',
      onPressed: () => Navigator.pop(context, true),
    ),
  ],
);
```

### showPageModal<T>

Shows a page-style modal that adapts to screen size.

```dart
Future<T?> showPageModal<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  List<Widget>? actions,
  Widget? leading,
  bool fullscreenOnMobile = true,
  double? desktopWidth,
  double? desktopMaxWidth = 900,
  bool showCloseButton = true,
})
```

**Example:**
```dart
final result = await ui.showPageModal<String>(
  context: context,
  title: 'Profile Settings',
  builder: (context) => ListView(
    children: [
      ui.listTile(
        title: Text('Personal Information'),
        onTap: () => editPersonalInfo(),
      ),
      ui.listTile(
        title: Text('Security'),
        onTap: () => editSecurity(),
      ),
    ],
  ),
);
```

### showActionSheet<T>

Shows an action sheet with multiple options.

```dart
Future<T?> showActionSheet<T>({
  required BuildContext context,
  required List<AdaptiveActionSheetItem<T>> actions,
  Widget? title,
  Widget? message,
  bool showCancelButton = true,
  String? cancelButtonText,
})
```

**Example:**
```dart
final action = await ui.showActionSheet<String>(
  context: context,
  title: Text('Share Document'),
  message: Text('Choose how to share'),
  actions: [
    AdaptiveActionSheetItem(
      value: 'email',
      label: 'Email',
      icon: Icons.email,
    ),
    AdaptiveActionSheetItem(
      value: 'link',
      label: 'Copy Link',
      icon: Icons.link,
      isDefault: true, // Bold on iOS
    ),
    AdaptiveActionSheetItem(
      value: 'delete',
      label: 'Delete',
      icon: Icons.delete,
      isDestructive: true, // Red color
    ),
  ],
);
```

### showConfirmationDialog

Shows a confirmation dialog with platform-appropriate styling.

```dart
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
  IconData? icon,
})
```

**Example:**
```dart
final confirmed = await ui.showConfirmationDialog(
  context: context,
  title: 'Delete Project?',
  message: 'All project data will be permanently deleted.',
  confirmText: 'Delete',
  isDestructive: true,
  icon: Icons.delete_forever,
);
```

## Platform Behavior

### Material Design (Android/Web)
- **Form Dialog**: Material Dialog with 28px border radius (Material 3)
- **Page Modal**: MaterialPageRoute with full-screen dialog flag
- **Action Sheet**: Modal bottom sheet with rounded top corners
- **Confirmation**: AlertDialog with Material theming

### Cupertino (iOS/macOS)
- **Form Dialog**: 
  - iPhone: CupertinoPageRoute (full-screen)
  - iPad/Mac: Custom dialog with proper width support (respects width parameter)
- **Page Modal**: CupertinoPageScaffold with navigation bar
- **Action Sheet**: CupertinoActionSheet
- **Confirmation**: CupertinoAlertDialog (narrow width for simple alerts)

### ForUI (Custom Design System)
- **Form Dialog**: Flat design with 4px border radius
- **Page Modal**: Similar to Material but with ForUI theming
- **Action Sheet**: Custom bottom sheet with zinc color palette
- **Confirmation**: ForUI alert with minimal styling

## Responsive Design

The dialog system automatically adapts based on screen size:

### Breakpoints
- **Mobile**: < 600px width
- **Tablet**: 600px - 1200px width
- **Desktop**: > 1200px width

### Width Behavior

| Screen Size | Form Dialog Width | Page Modal |
|------------|-------------------|------------|
| Mobile (<600px) | 90% of screen | Full-screen |
| Tablet (600-1200px) | Requested width (up to 90% screen) or 70% default | Dialog |
| Desktop (>1200px) | Requested width or 700px default | Dialog |

> **✅ Fixed:** Cupertino dialogs now properly respect the `width` parameter. Form dialogs can display at full requested width (e.g., 700px) on iPad and desktop, while simple confirmation dialogs continue using narrow `CupertinoAlertDialog` for native iOS appearance.

### Helper Class

```dart
class DialogResponsiveness {
  // Check if full-screen should be used
  static bool shouldUseFullScreen(BuildContext context);
  
  // Get appropriate dialog width
  static double getDialogWidth(BuildContext context, {double? requested});
  
  // Get appropriate padding
  static EdgeInsets getDialogPadding(BuildContext context);
  
  // Device type checks
  static bool isMobile(BuildContext context);
  static bool isTablet(BuildContext context);
  static bool isDesktop(BuildContext context);
}
```

## Examples

### Using Proper Dialog Width (Cupertino Fix Applied)

```dart
// For forms and complex content that needs width
final result = await ui.showFormDialog<bool>(
  context: context,
  title: Text('Settings'),
  width: 700,  // ✅ This now works properly on iPad/macOS
  content: Column(
    children: [
      ui.listTile(
        title: Text('Enable Feature'),
        trailing: ui.switch_(value: enabled, onChanged: (v) => setState(() => enabled = v)),
      ),
      ui.textField(label: 'Name', controller: nameController),
      // ... more form fields
    ],
  ),
  actions: [
    ui.textButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
    ui.button(label: 'Save', onPressed: () => Navigator.pop(context, true)),
  ],
);

// For simple confirmations (uses narrow native dialog)
final confirmed = await ui.showConfirmationDialog(
  context: context,
  title: 'Delete Item?',
  message: 'This cannot be undone.',
  confirmText: 'Delete',
  isDestructive: true,
);
```

### Complex Form with Validation

```dart
class CreateProjectDialog extends StatefulWidget {
  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _enableSync = false;
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ui.textField(
            controller: _nameController,
            label: 'Project Name',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ui.textField(
            controller: _emailController,
            label: 'Contact Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (!value!.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ui.listTile(
            title: Text('Enable Cloud Sync'),
            trailing: ui.switch_(
              value: _enableSync,
              onChanged: (value) => setState(() => _enableSync = value),
            ),
          ),
          const SizedBox(height: 16),
          ...['low', 'medium', 'high'].map((priority) =>
            ui.radioListTile<String>(
              value: priority,
              groupValue: _priority,
              onChanged: (value) => setState(() => _priority = value!),
              title: Text(priority.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> show(BuildContext context) async {
    final ui = getAdaptiveFactory(context);
    
    final result = await ui.showFormDialog<bool>(
      context: context,
      title: Text('Create New Project'),
      width: 650,
      content: this,
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        ui.button(
          label: 'Create',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    );
    
    if (result == true) {
      // Handle project creation
    }
  }
}
```

### Dynamic Action Sheet

```dart
Future<void> showShareOptions(BuildContext context, Document doc) async {
  final ui = getAdaptiveFactory(context);
  
  // Build actions dynamically based on capabilities
  final actions = <AdaptiveActionSheetItem<String>>[];
  
  if (doc.canEmail) {
    actions.add(AdaptiveActionSheetItem(
      value: 'email',
      label: 'Email Document',
      icon: Icons.email,
    ));
  }
  
  if (doc.canShare) {
    actions.add(AdaptiveActionSheetItem(
      value: 'share',
      label: 'Share Link',
      icon: Icons.share,
      isDefault: true,
    ));
  }
  
  if (doc.canExport) {
    actions.add(AdaptiveActionSheetItem(
      value: 'export',
      label: 'Export as PDF',
      icon: Icons.picture_as_pdf,
    ));
  }
  
  if (doc.canDelete) {
    actions.add(AdaptiveActionSheetItem(
      value: 'delete',
      label: 'Delete Document',
      icon: Icons.delete,
      isDestructive: true,
    ));
  }
  
  final action = await ui.showActionSheet<String>(
    context: context,
    title: Text(doc.title),
    message: Text('Choose an action for this document'),
    actions: actions,
  );
  
  switch (action) {
    case 'email':
      await emailDocument(doc);
      break;
    case 'share':
      await shareDocument(doc);
      break;
    case 'export':
      await exportDocument(doc);
      break;
    case 'delete':
      await deleteDocument(doc);
      break;
  }
}
```

## Migration Guide

### From Basic showDialog

**Before:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: Text('Message'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);
```

**After:**
```dart
final ui = getAdaptiveFactory(context);

ui.showConfirmationDialog(
  context: context,
  title: 'Title',
  message: 'Message',
  confirmText: 'OK',
  cancelText: 'Cancel',
);
```

### From Custom Form Dialogs

**Before:**
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: Container(
      width: 600,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Form Title'),
          // Form fields...
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(...),
              ElevatedButton(...),
            ],
          ),
        ],
      ),
    ),
  ),
);
```

**After:**
```dart
final ui = getAdaptiveFactory(context);

ui.showFormDialog(
  context: context,
  title: Text('Form Title'),
  width: 600,
  content: Column(
    children: [
      // Form fields...
    ],
  ),
  actions: [
    ui.textButton(...),
    ui.button(...),
  ],
);
```

## Best Practices

### 1. Use Type-Safe Results
Always specify the return type for better type safety:
```dart
final result = await ui.showFormDialog<UserData>(
  // ...
);
```

### 2. Handle Dialog Dismissal
Check for null results when the user dismisses the dialog:
```dart
final result = await ui.showConfirmationDialog(...);
if (result == true) {
  // User confirmed
} else {
  // User cancelled or dismissed
}
```

### 3. Responsive Width
Let the system handle width on mobile, specify on desktop:
```dart
ui.showFormDialog(
  width: DialogResponsiveness.isMobile(context) ? null : 700,
  // ...
);
```

### 4. Consistent Actions
Use the adaptive factory for action buttons:
```dart
actions: [
  ui.textButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
  ui.button(label: 'Save', onPressed: () => save()),
]
```

### 5. Loading States
Show loading indicators in dialogs when needed:
```dart
StatefulBuilder(
  builder: (context, setState) {
    if (isLoading) {
      return ui.circularProgressIndicator();
    }
    return // ... form content
  },
)
```

### 6. Error Handling
Display errors within the dialog:
```dart
if (errorMessage != null) {
  ui.card(
    color: Colors.red.shade100,
    child: ui.listTile(
      title: Text(errorMessage),
      leading: Icon(Icons.error),
    ),
  ),
}
```

## Troubleshooting

### Dialog Not Showing
- Ensure you're using the correct context (not the app's root context)
- Check if `useRootNavigator` is set correctly

### Width Not Applying (FIXED)
- ✅ **Fixed in latest version**: Cupertino dialogs now properly respect width parameter
- Width applies on desktop/tablet screens (iPad, macOS, web desktop)
- Mobile (<600px) always uses full-screen for better UX
- Use `showFormDialog` with `width` parameter for forms needing more space (e.g., 700px)
- Simple alerts use `showConfirmationDialog` which maintains narrow native width

### Scrolling Issues
- Set `scrollable: true` for long content
- Use `maxHeight` to constrain dialog height

### Platform Styling Not Working
- Ensure the correct UI system is set in AppShellSettingsStore
- Check that platform-specific implementations are complete

## See Also
- [Adaptive Components](./adaptive-components.md)
- [UI Systems](./README.md)
- [Navigation](../navigation.md)