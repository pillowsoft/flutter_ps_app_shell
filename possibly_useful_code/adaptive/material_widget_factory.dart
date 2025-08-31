import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart'
    show
        Widget,
        Key,
        BuildContext,
        VoidCallback,
        Icon,
        ThemeMode,
        WidgetBuilder,
        Color,
        ButtonStyle,
        IconData,
        CrossAxisAlignment,
        Column;
import 'adaptive_widget_factory.dart';

/// Material Design implementation of the adaptive widget factory
class MaterialWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? bottomNavBar,
    Color? backgroundColor,
  }) {
    return material.Scaffold(
      key: key,
      appBar: appBar as material.PreferredSizeWidget?,
      body: body,
      bottomNavigationBar: bottomNavBar,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget appBar({
    Key? key,
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return material.AppBar(
      key: key,
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Widget navBar({
    Key? key,
    required int currentIndex,
    required Function(int) onTap,
    required List<AdaptiveNavItem> items,
  }) {
    return material.BottomNavigationBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      items: items
          .map((item) => material.BottomNavigationBarItem(
                icon: material.Icon(item.icon),
                activeIcon: item.activeIcon != null
                    ? material.Icon(item.activeIcon)
                    : null,
                label: item.label,
              ))
          .toList(),
    );
  }

  @override
  Widget listTile({
    Key? key,
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return material.ListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget switch_({
    Key? key,
    required bool value,
    required Function(bool) onChanged,
    Color? activeColor,
  }) {
    return material.Switch(
      key: key,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }

  @override
  Widget button({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return material.ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: material.Text(label),
    );
  }

  @override
  Widget iconButton({
    Key? key,
    required Icon icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return material.IconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  @override
  Widget textButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return material.TextButton(
      key: key,
      onPressed: onPressed,
      child: material.Text(label),
    );
  }

  @override
  Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return material.showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => material.AlertDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Future<T?> showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return material.showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
    );
  }

  @override
  Widget listSection({
    Key? key,
    Widget? header,
    required List<Widget> children,
    Widget? footer,
  }) {
    return material.Builder(
      builder: (context) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            material.Padding(
              padding: const material.EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: material.DefaultTextStyle(
                style: material.TextStyle(
                  fontSize: 14,
                  fontWeight: material.FontWeight.w500,
                  color: material.Theme.of(context).textTheme.bodySmall?.color,
                ),
                child: header,
              ),
            ),
          ...children,
          if (footer != null)
            material.Padding(
              padding: const material.EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: footer,
            ),
        ],
      ),
    );
  }

  @override
  Widget card({
    Key? key,
    required Widget child,
    material.EdgeInsets? margin,
    material.EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    final card = material.Card(
      key: key,
      margin: margin ?? const material.EdgeInsets.all(4),
      child: padding != null
          ? material.Padding(padding: padding, child: child)
          : child,
    );

    if (onTap != null) {
      return material.InkWell(
        onTap: onTap,
        borderRadius: material.BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }

  @override
  Widget textField({
    Key? key,
    material.TextEditingController? controller,
    String? labelText,
    String? hintText,
    int? maxLines,
    material.FormFieldValidator<String>? validator,
    material.ValueChanged<String>? onChanged,
    material.TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return material.TextFormField(
      key: key,
      controller: controller,
      decoration: material.InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: const material.OutlineInputBorder(),
      ),
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  @override
  Widget form({
    Key? key,
    required material.GlobalKey<material.FormState> formKey,
    required Widget child,
  }) {
    return material.Form(
      key: formKey,
      child: child,
    );
  }

  @override
  Widget themedApp({
    required Widget home,
    ThemeMode? themeMode,
    String? title,
  }) {
    return material.MaterialApp(
      title: title ?? 'Flutter App',
      theme: material.ThemeData.light(),
      darkTheme: material.ThemeData.dark(),
      themeMode: themeMode ?? material.ThemeMode.system,
      home: home,
    );
  }

  @override
  IconData getIcon(String semanticName) {
    switch (semanticName) {
      case 'folder':
        return material.Icons.folder_outlined;
      case 'folder_filled':
        return material.Icons.folder;
      case 'settings':
        return material.Icons.settings_outlined;
      case 'settings_filled':
        return material.Icons.settings;
      case 'add':
        return material.Icons.add;
      case 'chevron_right':
        return material.Icons.chevron_right;
      case 'camera':
        return material.Icons.camera_alt;
      case 'video':
        return material.Icons.videocam;
      case 'chevron_left':
        return material.Icons.chevron_left;
      case 'people':
        return material.Icons.people;
      case 'auto_fix':
        return material.Icons.auto_fix_high;
      default:
        return material.Icons.help_outline;
    }
  }
}
