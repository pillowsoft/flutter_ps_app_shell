import 'package:flutter/material.dart';

/// Navigation item model for bottom navigation
class AdaptiveNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AdaptiveNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Abstract factory for creating platform-specific widgets
abstract class AdaptiveWidgetFactory {
  /// Creates a scaffold with app bar and bottom navigation
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? bottomNavBar,
    Color? backgroundColor,
  });

  /// Creates an app bar
  Widget appBar({
    Key? key,
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  });

  /// Creates a bottom navigation bar
  Widget navBar({
    Key? key,
    required int currentIndex,
    required Function(int) onTap,
    required List<AdaptiveNavItem> items,
  });

  /// Creates a list tile
  Widget listTile({
    Key? key,
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  });

  /// Creates a switch
  Widget switch_({
    Key? key,
    required bool value,
    required Function(bool) onChanged,
    Color? activeColor,
  });

  /// Creates a button
  Widget button({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  });

  /// Creates an icon button
  Widget iconButton({
    Key? key,
    required Icon icon,
    required VoidCallback onPressed,
    String? tooltip,
  });

  /// Creates a text button
  Widget textButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  });

  /// Creates a dialog
  Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  });

  /// Creates a modal bottom sheet
  Future<T?> showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  });

  /// Creates a list section (for grouped lists)
  Widget listSection({
    Key? key,
    Widget? header,
    required List<Widget> children,
    Widget? footer,
  });

  /// Creates a card widget
  Widget card({
    Key? key,
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
  });

  /// Creates a text field
  Widget textField({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    int? maxLines,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    bool obscureText = false,
  });

  /// Creates a form widget
  Widget form({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Widget child,
  });

  /// Creates a themed app wrapper
  Widget themedApp({
    required Widget home,
    ThemeMode? themeMode,
    String? title,
  });

  /// Gets the appropriate icon for the platform
  IconData getIcon(String semanticName) {
    // Default implementation - can be overridden
    switch (semanticName) {
      case 'folder':
        return Icons.folder_outlined;
      case 'folder_filled':
        return Icons.folder;
      case 'settings':
        return Icons.settings_outlined;
      case 'settings_filled':
        return Icons.settings;
      case 'add':
        return Icons.add;
      case 'chevron_right':
        return Icons.chevron_right;
      case 'chevron_left':
        return Icons.chevron_left;
      default:
        return Icons.help_outline;
    }
  }
}
