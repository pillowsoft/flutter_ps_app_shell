import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'adaptive_widget_factory.dart';

/// Cupertino (iOS) implementation of the adaptive widget factory
class CupertinoWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? bottomNavBar,
    Color? backgroundColor,
  }) {
    if (bottomNavBar != null) {
      // Use CupertinoTabScaffold for bottom navigation
      return CupertinoPageScaffold(
        key: key,
        navigationBar: appBar as ObstructingPreferredSizeWidget?,
        backgroundColor: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: body),
              bottomNavBar,
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      key: key,
      navigationBar: appBar as ObstructingPreferredSizeWidget?,
      backgroundColor: backgroundColor,
      child: body,
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
    return CupertinoNavigationBar(
      key: key,
      middle: title,
      leading: leading,
      trailing: actions != null && actions.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            )
          : null,
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
    return CupertinoTabBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon:
                    item.activeIcon != null ? Icon(item.activeIcon) : null,
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
    return CupertinoListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing:
          trailing ?? (onTap != null ? const CupertinoListTileChevron() : null),
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
    return CupertinoSwitch(
      key: key,
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor ?? CupertinoColors.systemBlue,
    );
  }

  @override
  Widget button({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return CupertinoButton.filled(
      key: key,
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget iconButton({
    Key? key,
    required Icon icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return CupertinoButton(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: icon,
    );
  }

  @override
  Widget textButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Text(label),
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
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions ?? [],
      ),
    );
  }

  @override
  Future<T?> showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: builder,
    );
  }

  @override
  Widget listSection({
    Key? key,
    Widget? header,
    required List<Widget> children,
    Widget? footer,
  }) {
    return CupertinoListSection.insetGrouped(
      key: key,
      header: header,
      footer: footer,
      children: children,
    );
  }

  @override
  Widget card({
    Key? key,
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    final container = Container(
      key: key,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            padding != null ? Padding(padding: padding, child: child) : child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }

  @override
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
  }) {
    // Wrap in a form field for validation support
    if (validator != null) {
      return FormField<String>(
        key: key,
        validator: validator,
        initialValue: controller?.text,
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labelText != null) ...[
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              CupertinoTextField(
                controller: controller,
                placeholder: hintText,
                maxLines: obscureText ? 1 : maxLines,
                onChanged: (value) {
                  state.didChange(value);
                  onChanged?.call(value);
                },
                keyboardType: keyboardType,
                obscureText: obscureText,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (state.hasError && state.errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ],
          );
        },
      );
    }

    // Simple text field without validation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 4),
        ],
        CupertinoTextField(
          key: key,
          controller: controller,
          placeholder: hintText,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  @override
  Widget form({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Widget child,
  }) {
    return Form(
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
    return CupertinoApp(
      title: title ?? 'Flutter App',
      theme: CupertinoThemeData(
        brightness: themeMode == ThemeMode.dark
            ? Brightness.dark
            : themeMode == ThemeMode.light
                ? Brightness.light
                : Brightness.light,
      ),
      home: home,
    );
  }

  @override
  IconData getIcon(String semanticName) {
    switch (semanticName) {
      case 'folder':
        return CupertinoIcons.folder;
      case 'folder_filled':
        return CupertinoIcons.folder_fill;
      case 'settings':
        return CupertinoIcons.settings;
      case 'settings_filled':
        return CupertinoIcons.settings_solid;
      case 'add':
        return CupertinoIcons.add;
      case 'chevron_right':
        return CupertinoIcons.chevron_right;
      case 'camera':
        return CupertinoIcons.camera_fill;
      case 'video':
        return CupertinoIcons.video_camera_solid;
      case 'chevron_left':
        return CupertinoIcons.chevron_left;
      case 'people':
        return CupertinoIcons.person_2_fill;
      case 'auto_fix':
        return CupertinoIcons.wand_stars;
      default:
        return CupertinoIcons.question_circle;
    }
  }
}
