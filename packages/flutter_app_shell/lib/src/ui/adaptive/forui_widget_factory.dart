import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material
    show showDatePicker, showTimePicker, showDateRangePicker;
import 'package:flutter/services.dart';
import 'adaptive_widget_factory.dart';
import 'components/adaptive_dialog_models.dart';
import '../../core/app_route.dart';
import '../dialog/dialog_handle.dart';

/// ForUI implementation of the adaptive widget factory
/// Implements ForUI-style components using Material widgets with custom styling
/// Based on ForUI design principles: minimal, modern, and accessible
class ForUIWidgetFactory extends AdaptiveWidgetFactory {
  // ForUI Color Palette
  static const _primaryColor = Color(0xFF020817); // zinc-950
  static const _primaryLight = Color(0xFFF8FAFC); // slate-50
  static const _borderColor = Color(0xFFE4E4E7); // zinc-200
  static const _borderColorDark = Color(0xFF27272A); // zinc-800
  static const _accentColor = Color(0xFF0F172A); // slate-900
  static const _mutedColor = Color(0xFFF4F4F5); // zinc-100
  static const _mutedForeground = Color(0xFF71717A); // zinc-500
  static const _destructiveColor = Color(0xFFEF4444); // red-500

  // ForUI specific styling constants
  static const _borderRadius = 8.0;
  static const _buttonHeight = 40.0;
  static const _inputHeight = 44.0;
  @override
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? drawer,
    Widget? bottomNavBar,
    Color? backgroundColor,
  }) {
    final effectiveBackgroundColor = backgroundColor ?? _primaryLight;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Dark icons on light ForUI background
        systemNavigationBarColor: effectiveBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: key,
        appBar: appBar as PreferredSizeWidget?,
        drawer: drawer,
        body: body,
        bottomNavigationBar: bottomNavBar,
        backgroundColor: effectiveBackgroundColor,
        drawerScrimColor: _primaryColor.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget appBar({
    Key? key,
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool largeTitle = false,
  }) {
    if (largeTitle) {
      // For large titles, return SliverAppBar with ForUI styling
      // Note: This should be used within a CustomScrollView
      return SliverAppBar(
        key: key,
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        expandedHeight: 120.0,
        floating: true,
        pinned: true,
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          title: title,
        ),
      );
    }

    // Placeholder: Use Material AppBar with ForUI styling
    return AppBar(
      key: key,
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Widget navBar({
    Key? key,
    required int currentIndex,
    required Function(int) onTap,
    required List<AdaptiveNavItem> items,
  }) {
    return Container(
      key: key,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: _mutedColor,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(
                    item.icon,
                    color: _mutedForeground,
                    size: 20,
                  ),
                  selectedIcon: Icon(
                    item.activeIcon ?? item.icon,
                    color: _primaryColor,
                    size: 20,
                  ),
                  label: item.label,
                ))
            .toList(),
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        splashColor: _mutedColor,
        highlightColor: _mutedColor.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primaryColor,
                        height: 1.4,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _mutedForeground,
                          height: 1.3,
                        ),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget switch_({
    Key? key,
    required bool value,
    required Function(bool) onChanged,
    Color? activeColor,
  }) {
    return Switch(
      key: key,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? Colors.white,
      activeTrackColor: _primaryColor,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: _borderColor,
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget radio<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    Color? activeColor,
  }) {
    return Radio<T>(
      key: key,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor ?? _primaryColor,
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return activeColor ?? _primaryColor;
        }
        return _borderColor;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget radioListTile<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Color? activeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onChanged != null ? () => onChanged(value) : null,
        splashColor: _mutedColor,
        highlightColor: _mutedColor.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              radio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: activeColor,
              ),
              const SizedBox(width: 12),
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _primaryColor,
                        height: 1.4,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _mutedForeground,
                          height: 1.3,
                        ),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget button({
    Key? key,
    String? label,
    Widget? child,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    final buttonChild = child ?? (label != null ? Text(label) : null);
    assert(buttonChild != null, 'Either label or child must be provided');

    return Container(
      key: key,
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _primaryLight,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return _primaryColor.withValues(alpha: 0.9);
                }
                if (states.contains(MaterialState.pressed)) {
                  return _primaryColor.withValues(alpha: 0.8);
                }
                return null;
              }),
            ),
        child: buttonChild!,
      ),
    );
  }

  @override
  Widget buttonWithIcon({
    Key? key,
    required Icon icon,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: style ??
            ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _primaryLight,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return _primaryColor.withValues(alpha: 0.9);
                }
                if (states.contains(MaterialState.pressed)) {
                  return _primaryColor.withValues(alpha: 0.8);
                }
                return null;
              }),
            ),
      ),
    );
  }

  @override
  Widget outlinedButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      height: _buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style ??
            OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              side: const BorderSide(color: _borderColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return _mutedColor;
                }
                if (states.contains(MaterialState.pressed)) {
                  return _borderColor;
                }
                return null;
              }),
            ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget outlinedButtonWithIcon({
    Key? key,
    required Icon icon,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      height: _buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: style ??
            OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              side: const BorderSide(color: _borderColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return _mutedColor;
                }
                if (states.contains(MaterialState.pressed)) {
                  return _borderColor;
                }
                return null;
              }),
            ),
      ),
    );
  }

  @override
  Widget iconButton({
    Key? key,
    required Icon icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    // Placeholder: Use Material IconButton
    return IconButton(
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
    return Container(
      key: key,
      height: _buttonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return _mutedColor;
            }
            if (states.contains(MaterialState.pressed)) {
              return _borderColor;
            }
            return null;
          }),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Future<T?> showDialog<T>({
    required BuildContext context,
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showAdaptiveDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: _primaryColor.withValues(alpha: 0.5),
      builder: (dialogContext) => AlertDialog(
        title: title != null
            ? DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                  height: 1.4,
                ),
                child: title,
              )
            : null,
        content: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            color: _mutedForeground,
            height: 1.5,
          ),
          child: content,
        ),
        actions: actions,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: _borderColor, width: 1),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Future<T?> showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
          border: Border(
            top: BorderSide(color: _borderColor, width: 1),
            left: BorderSide(color: _borderColor, width: 1),
            right: BorderSide(color: _borderColor, width: 1),
          ),
        ),
        child: builder(context),
      ),
    );
  }

  @override
  Widget listSection({
    Key? key,
    Widget? header,
    required List<Widget> children,
    Widget? footer,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10, top: 16),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600, // ForUI muted gray header
                letterSpacing: 0.3,
              ),
              child: header,
            ),
          ),
        // ForUI flat design with prominent borders and neutral colors
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6), // Sharp ForUI corners
            border: Border.all(
              color: Colors.grey.shade400, // Visible gray border
              width: 2, // Prominent border width
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 1),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: child,
                  ),
                  if (index < children.length - 1)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300, // ForUI gray divider
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 11,
                color: _mutedForeground,
                height: 1.4,
              ),
              child: footer,
            ),
          ),
      ],
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
    final card = Container(
      key: key,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: _borderColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Material(
          color: Colors.transparent,
          child:
              padding != null ? Padding(padding: padding, child: child) : child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        splashColor: _mutedColor,
        highlightColor: _mutedColor.withValues(alpha: 0.5),
        child: card,
      );
    }
    return card;
  }

  @override
  Widget textField({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? label,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsets? prefixIconPadding,
    EdgeInsets? suffixIconPadding,
    int? maxLines,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    final effectiveLabel = labelText ?? label;
    return SizedBox(
      key: key,
      height: _inputHeight,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          color: _primaryColor,
          height: 1.4,
        ),
        decoration: InputDecoration(
          labelText: effectiveLabel,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: _mutedForeground,
            fontWeight: FontWeight.w400,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: _mutedForeground,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: prefixIconPadding ??
                      const EdgeInsets.only(left: 8, right: 4),
                  child: IconTheme(
                    data: const IconThemeData(
                      color: _mutedForeground,
                      size: 16,
                    ),
                    child: prefixIcon,
                  ),
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: suffixIconPadding ??
                      const EdgeInsets.only(left: 4, right: 8),
                  child: IconTheme(
                    data: const IconThemeData(
                      color: _mutedForeground,
                      size: 16,
                    ),
                    child: suffixIcon,
                  ),
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _destructiveColor, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _destructiveColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: obscureText ? 1 : (maxLines ?? 1),
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
      ),
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
  Widget divider({
    Key? key,
    double? height,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
  }) {
    return Container(
      key: key,
      height: thickness ?? 1,
      margin: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
        top: ((height ?? 1) - (thickness ?? 1)) / 2,
        bottom: ((height ?? 1) - (thickness ?? 1)) / 2,
      ),
      color: color ?? _borderColor,
    );
  }

  @override
  Widget avatar({
    Key? key,
    Widget? child,
    Color? backgroundColor,
    Color? foregroundColor,
    double? radius,
    String? text,
  }) {
    return Container(
      key: key,
      width: (radius ?? 20) * 2,
      height: (radius ?? 20) * 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: backgroundColor ?? _mutedColor,
        border: Border.all(color: _borderColor, width: 1),
      ),
      alignment: Alignment.center,
      child: child ??
          (text != null
              ? Text(
                  text,
                  style: TextStyle(
                    color: foregroundColor ?? _primaryColor,
                    fontSize: radius != null ? radius * 0.8 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
    );
  }

  @override
  Widget themedApp({
    required Widget home,
    ThemeMode? themeMode,
    String? title,
  }) {
    // ForUI-inspired theme with clean, minimal design
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor, // zinc-950
        onPrimary: _primaryLight, // slate-50
        surface: _primaryLight, // slate-50
        onSurface: _primaryColor, // zinc-950
        surfaceContainer: Colors.white, // white
        outline: _borderColor, // zinc-200
        error: _destructiveColor, // red-500
      ),
      scaffoldBackgroundColor: _primaryLight,
      cardTheme: const CardThemeData(
        color: Colors.white,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: _borderColor,
      dividerTheme: const DividerThemeData(
        color: _borderColor,
        thickness: 1,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryLight, // slate-50
        onPrimary: _primaryColor, // zinc-950
        surface: _primaryColor, // zinc-950
        onSurface: _primaryLight, // slate-50
        surfaceContainer: _borderColorDark, // zinc-800
        outline: _borderColorDark, // zinc-800
        error: _destructiveColor, // red-500
      ),
      scaffoldBackgroundColor: _primaryColor,
      cardTheme: const CardThemeData(
        color: _borderColorDark,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: _borderColorDark,
      dividerTheme: const DividerThemeData(
        color: _borderColorDark,
        thickness: 1,
      ),
    );

    return MaterialApp(
      title: title ?? 'Flutter App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode ?? ThemeMode.system,
      home: home,
    );
  }

  @override
  IconData getIcon(String semanticName) {
    // Use Material icons for ForUI (placeholder)
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
      case 'camera':
        return Icons.camera_alt_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'chevron_left':
        return Icons.chevron_left;
      case 'people':
        return Icons.people_outline;
      case 'auto_fix':
        return Icons.auto_fix_high_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'person':
        return Icons.person_outline;
      case 'palette':
        return Icons.palette_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Extended Adaptive Components with ForUI Styling

  @override
  Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await material.showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Color(0xFFFAFAFA), // Light gray background for ForUI
              onSurface: _primaryColor,
              surfaceVariant: Color(0xFFF4F4F5), // zinc-100
              onSurfaceVariant: Color(0xFF71717A), // zinc-500
              outline: Color(0xFFD4D4D8), // zinc-300 for borders
            ),
            dialogBackgroundColor: const Color(0xFFFAFAFA),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Sharp ForUI corners
                side: const BorderSide(
                    color: Color(0xFFD4D4D8), width: 2), // Prominent border
              ),
              elevation: 0, // Flat design - no shadows
              backgroundColor: const Color(0xFFFAFAFA),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFFFAFAFA),
              elevation: 0, // Flat design
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Sharp corners
                side: const BorderSide(color: _borderColor, width: 1),
              ),
              headerBackgroundColor:
                  const Color(0xFFF4F4F5), // Light zinc background
              headerForegroundColor: _primaryColor,
              headerHeadlineStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
              headerHelpStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A), // zinc-500
              ),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return const Color(0xFFA1A1AA); // zinc-400
                }
                return _primaryColor;
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _primaryColor;
                }
                if (states.contains(MaterialState.hovered)) {
                  return const Color(0xFFF4F4F5); // zinc-100
                }
                return null;
              }),
              dayShape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(2), // Very sharp corners for ForUI
                  side: const BorderSide(
                      color: Color(0xFFE4E4E7), width: 1), // zinc-200 border
                ),
              ),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return _mutedColor;
                }
                if (states.contains(MaterialState.pressed)) {
                  return _borderColor;
                }
                return null;
              }),
              yearForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _primaryLight;
                }
                return _primaryColor;
              }),
              yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return _primaryColor;
                }
                return null;
              }),
              todayForegroundColor: MaterialStateProperty.all(_primaryColor),
              todayBackgroundColor: MaterialStateProperty.all(_mutedColor),
              todayBorder: const BorderSide(color: _primaryColor, width: 1),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    return await material.showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Color(0xFFFAFAFA), // Light gray background for ForUI
              onSurface: _primaryColor,
              surfaceVariant: Color(0xFFF4F4F5), // zinc-100
              onSurfaceVariant: Color(0xFF71717A), // zinc-500
              outline: Color(0xFFD4D4D8), // zinc-300 for borders
            ),
            dialogBackgroundColor: const Color(0xFFFAFAFA),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Sharp ForUI corners
                side: const BorderSide(
                    color: Color(0xFFD4D4D8), width: 2), // Prominent border
              ),
              elevation: 0, // Flat design - no shadows
              backgroundColor: const Color(0xFFFAFAFA),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFFFAFAFA),
              elevation: 0, // Flat design
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Sharp corners
                side: const BorderSide(color: Color(0xFFD4D4D8), width: 2),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2), // Very sharp corners
                side: const BorderSide(
                    color: Color(0xFFE4E4E7), width: 1), // zinc-200
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2), // Very sharp corners
                side: const BorderSide(
                    color: Color(0xFFE4E4E7), width: 1), // zinc-200
              ),
              hourMinuteTextColor: _primaryColor,
              hourMinuteColor: const Color(0xFFF4F4F5), // zinc-100
              dayPeriodTextColor: const Color(0xFF71717A), // zinc-500
              dayPeriodColor: const Color(0xFFF4F4F5), // zinc-100
              dialHandColor: _primaryColor,
              dialBackgroundColor: const Color(0xFFF4F4F5), // zinc-100
              dialTextColor: _primaryColor,
              entryModeIconColor: _primaryColor,
              hourMinuteTextStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
              dayPeriodTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A), // zinc-500
              ),
              helpTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A), // zinc-500
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _primaryLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Future<DateTimeRange?> showDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await material.showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: _primaryLight,
              surface: Colors.white,
              onSurface: _primaryColor,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: _primaryColor,
              foregroundColor: _primaryLight,
              elevation: 0,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget rangeSlider({
    Key? key,
    required RangeValues values,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
    int? divisions,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: activeColor ?? _primaryColor,
        inactiveTrackColor: inactiveColor ?? _borderColor,
        thumbColor: activeColor ?? _primaryColor,
        overlayColor: (activeColor ?? _primaryColor).withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8,
          elevation: 0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 8,
          elevation: 0,
        ),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        rangeValueIndicatorShape:
            const RectangularRangeSliderValueIndicatorShape(),
        valueIndicatorColor: _primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: _primaryLight,
          fontSize: 12,
        ),
      ),
      child: RangeSlider(
        key: key,
        values: values,
        min: min,
        max: max,
        onChanged: onChanged,
        divisions: divisions,
      ),
    );
  }

  @override
  Widget slider({
    Key? key,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: activeColor ?? _primaryColor,
        inactiveTrackColor: inactiveColor ?? _borderColor,
        thumbColor: activeColor ?? _primaryColor,
        overlayColor: (activeColor ?? _primaryColor).withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8,
          elevation: 0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        valueIndicatorColor: _primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: _primaryLight,
          fontSize: 12,
        ),
        valueIndicatorShape: const RectangularSliderValueIndicatorShape(),
      ),
      child: Slider(
        key: key,
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        divisions: divisions,
      ),
    );
  }

  @override
  Widget chip({
    Key? key,
    required Widget label,
    Widget? avatar,
    Widget? deleteIcon,
    VoidCallback? onDeleted,
    Color? backgroundColor,
    Color? deleteIconColor,
  }) {
    return Chip(
      key: key,
      label: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        child: label,
      ),
      avatar: avatar,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor ?? _mutedColor,
      deleteIconColor: deleteIconColor ?? _mutedForeground,
      side: const BorderSide(color: _borderColor, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget actionChip({
    Key? key,
    required Widget label,
    required VoidCallback onPressed,
    Widget? avatar,
    Color? backgroundColor,
  }) {
    return ActionChip(
      key: key,
      label: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        child: label,
      ),
      avatar: avatar,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Colors.white,
      side: const BorderSide(color: _borderColor, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget choiceChip({
    Key? key,
    required Widget label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
  }) {
    return ChoiceChip(
      key: key,
      label: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? _primaryLight : _primaryColor,
        ),
        child: label,
      ),
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? Colors.white,
      selectedColor: selectedColor ?? _primaryColor,
      side: BorderSide(
        color: selected ? _primaryColor : _borderColor,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget filterChip({
    Key? key,
    required Widget label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
  }) {
    return FilterChip(
      key: key,
      label: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selected ? _primaryLight : _primaryColor,
        ),
        child: label,
      ),
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? Colors.white,
      selectedColor: selectedColor ?? _primaryColor,
      side: BorderSide(
        color: selected ? _primaryColor : _borderColor,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      showCheckmark: false,
    );
  }

  @override
  Widget checkbox({
    Key? key,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    Color? activeColor,
    Color? checkColor,
  }) {
    return Checkbox(
      key: key,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? _primaryColor,
      checkColor: checkColor ?? _primaryLight,
      side: const BorderSide(color: _borderColor, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget checkboxListTile({
    Key? key,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required Widget title,
    Widget? subtitle,
    Widget? secondary,
    Color? activeColor,
  }) {
    return CheckboxListTile(
      key: key,
      value: value,
      onChanged: onChanged,
      title: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle(
              style: const TextStyle(
                fontSize: 12,
                color: _mutedForeground,
              ),
              child: subtitle,
            )
          : null,
      secondary: secondary,
      activeColor: activeColor ?? _primaryColor,
      checkColor: _primaryLight,
      side: const BorderSide(color: _borderColor, width: 1),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget tabBar({
    Key? key,
    required TabController controller,
    required List<Widget> tabs,
    bool isScrollable = false,
    Color? indicatorColor,
    Color? labelColor,
    Color? unselectedLabelColor,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: TabBar(
        key: key,
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        indicatorColor: indicatorColor ?? _primaryColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: labelColor ?? _primaryColor,
        unselectedLabelColor: unselectedLabelColor ?? _mutedForeground,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        overlayColor: MaterialStateProperty.all(_mutedColor),
      ),
    );
  }

  @override
  Widget tabBarView({
    Key? key,
    required TabController controller,
    required List<Widget> children,
  }) {
    return TabBarView(
      key: key,
      controller: controller,
      children: children,
    );
  }

  @override
  Widget expansionTile({
    Key? key,
    required Widget title,
    required List<Widget> children,
    Widget? leading,
    Widget? trailing,
    Color? backgroundColor,
    Color? collapsedBackgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: collapsedBackgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: key,
          title: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
            child: title,
          ),
          leading: leading,
          trailing: trailing ??
              Icon(
                Icons.expand_more,
                color: _mutedForeground,
                size: 20,
              ),
          backgroundColor: backgroundColor ?? Colors.white,
          collapsedBackgroundColor: collapsedBackgroundColor ?? Colors.white,
          iconColor: _primaryColor,
          collapsedIconColor: _mutedForeground,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          children: children,
        ),
      ),
    );
  }

  @override
  Widget linearProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? minHeight,
  }) {
    return Container(
      height: minHeight ?? 4,
      child: LinearProgressIndicator(
        key: key,
        value: value,
        backgroundColor: backgroundColor ?? _borderColor,
        valueColor: AlwaysStoppedAnimation(valueColor ?? _primaryColor),
        minHeight: minHeight ?? 4,
      ),
    );
  }

  @override
  Widget circularProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? strokeWidth,
  }) {
    return CircularProgressIndicator(
      key: key,
      value: value,
      backgroundColor: backgroundColor ?? _borderColor,
      valueColor: AlwaysStoppedAnimation(valueColor ?? _primaryColor),
      strokeWidth: strokeWidth ?? 2,
    );
  }

  @override
  Widget stepper({
    Key? key,
    required int currentStep,
    required List<Step> steps,
    required ValueChanged<int> onStepTapped,
    VoidCallback? onStepContinue,
    VoidCallback? onStepCancel,
  }) {
    return Theme(
      data: ThemeData().copyWith(
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          onPrimary: _primaryLight,
          surface: Colors.white,
          onSurface: _primaryColor,
        ),
      ),
      child: Stepper(
        key: key,
        currentStep: currentStep,
        steps: steps,
        onStepTapped: onStepTapped,
        onStepContinue: onStepContinue,
        onStepCancel: onStepCancel,
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (onStepContinue != null)
                button(
                  label: 'Continue',
                  onPressed: onStepContinue,
                ),
              const SizedBox(width: 8),
              if (onStepCancel != null)
                outlinedButton(
                  label: 'Cancel',
                  onPressed: onStepCancel,
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget segmentedControl<T extends Object>({
    Key? key,
    required Map<T, Widget> children,
    required T? groupValue,
    required ValueChanged<T> onValueChanged,
    Color? thumbColor,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? _mutedColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children.entries.map((entry) {
          final isSelected = entry.key == groupValue;
          final isFirst = entry.key == children.keys.first;
          final isLast = entry.key == children.keys.last;

          return Expanded(
            child: GestureDetector(
              onTap: () => onValueChanged(entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (thumbColor ?? _primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst
                        ? Radius.circular(_borderRadius - 1)
                        : Radius.zero,
                    right: isLast
                        ? Radius.circular(_borderRadius - 1)
                        : Radius.zero,
                  ),
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? _primaryLight : _primaryColor,
                    ),
                    child: entry.value,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget toggleButtons({
    Key? key,
    required List<Widget> children,
    required List<bool> isSelected,
    required void Function(int) onPressed,
    Color? color,
    Color? selectedColor,
    Color? fillColor,
  }) {
    return ToggleButtons(
      key: key,
      children: children
          .map((child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ))
          .toList(),
      isSelected: isSelected,
      onPressed: onPressed,
      color: color ?? _mutedForeground,
      selectedColor: selectedColor ?? _primaryLight,
      fillColor: fillColor ?? _primaryColor,
      splashColor: _mutedColor,
      highlightColor: _borderColor,
      borderColor: _borderColor,
      selectedBorderColor: _primaryColor,
      borderRadius: BorderRadius.circular(_borderRadius),
      borderWidth: 1,
      constraints: const BoxConstraints(minHeight: _buttonHeight),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget tooltip({
    Key? key,
    required String message,
    required Widget child,
    double? height,
    EdgeInsets? padding,
    Duration? waitDuration,
  }) {
    return Tooltip(
      key: key,
      message: message,
      child: child,
      height: height,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      waitDuration: waitDuration,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: _primaryLight,
        fontSize: 12,
      ),
      preferBelow: true,
    );
  }

  @override
  Widget badge({
    Key? key,
    required Widget child,
    Widget? label,
    Color? backgroundColor,
    Color? textColor,
    bool isLabelVisible = true,
  }) {
    return Badge(
      key: key,
      isLabelVisible: isLabelVisible,
      label: label,
      backgroundColor: backgroundColor ?? _destructiveColor,
      textColor: textColor ?? Colors.white,
      textStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      child: child,
    );
  }

  @override
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: _primaryLight,
          fontSize: 14,
        ),
      ),
      duration: duration,
      action: action,
      backgroundColor: backgroundColor ?? _primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      margin: const EdgeInsets.all(16),
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Navigation and Layout Helpers

  @override
  Widget navigationRail({
    required int currentIndex,
    required List<AppRoute> routes,
    required ValueChanged<int> onDestinationSelected,
    required bool showLabels,
  }) {
    // ForUI style navigation rail with minimal design
    return Container(
      width: showLabels ? 88 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex >= 0 ? currentIndex : 0,
        onDestinationSelected: onDestinationSelected,
        labelType: showLabels
            ? NavigationRailLabelType.all
            : NavigationRailLabelType.none,
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(
          color: _primaryColor,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: _mutedForeground,
          size: 24,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: _primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: _mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _mutedColor,
        useIndicator: true,
        destinations: routes
            .where((route) => route.showInNavigation)
            .map((route) => NavigationRailDestination(
                  icon: Icon(route.icon),
                  label: Text(route.title),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget? drawerButton(BuildContext context) {
    // ForUI uses standard Material drawer button behavior
    return null;
  }

  @override
  bool shouldAddDrawerButton() {
    // ForUI scaffold automatically handles drawer button
    return false;
  }

  @override
  bool needsDesktopPadding() {
    // ForUI needs manual padding on desktop
    return true;
  }

  @override
  bool appBarCenterTitle() {
    // ForUI doesn't center title
    return false;
  }

  @override
  Widget pageTitle(String title) {
    // ForUI uses clean, modern page headers
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  @override
  Widget sliverScaffold({
    Key? key,
    Widget? largeTitle,
    required List<Widget> slivers,
    Widget? drawer,
    Widget? bottomNavBar,
    Color? backgroundColor,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    // Create the sliver list with app bar
    final sliverList = [
      if (largeTitle != null)
        SliverAppBar(
          key: key,
          title: largeTitle,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          expandedHeight: 120.0,
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFFF8F9FA),
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            title: largeTitle,
          ),
        ),
      ...slivers,
    ];

    // Build the custom scroll view
    final scrollView = CustomScrollView(
      slivers: sliverList,
    );

    return Scaffold(
      key: key,
      body: scrollView,
      drawer: drawer,
      bottomNavigationBar: bottomNavBar,
      backgroundColor: backgroundColor ?? _primaryLight,
      drawerScrimColor: _primaryColor.withValues(alpha: 0.5),
    );
  }

  @override
  Widget popupMenuButton<T>({
    Key? key,
    required List<AdaptivePopupMenuItem<T>> items,
    required ValueChanged<T> onSelected,
    Widget? icon,
    Widget? child,
    String? tooltip,
    EdgeInsets? padding,
  }) {
    return PopupMenuButton<T>(
      key: key,
      onSelected: onSelected,
      tooltip: tooltip,
      padding: padding ?? const EdgeInsets.all(8.0),
      icon: icon,
      child: child,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: _borderColor),
      ),
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      itemBuilder: (context) => items
          .map((item) => PopupMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.leading != null) ...[
                        item.leading!,
                        const SizedBox(width: 12.0),
                      ],
                      Expanded(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.destructive
                                ? _destructiveColor
                                : (item.enabled
                                    ? _primaryColor
                                    : _mutedForeground),
                          ),
                          child: item.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget inkWell({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDoubleTap,
    BorderRadius? borderRadius,
    Color? splashColor,
    Color? highlightColor,
    bool enableFeedback = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        splashColor: splashColor ?? _mutedColor,
        highlightColor: highlightColor ?? _borderColor,
        enableFeedback: enableFeedback,
        child: child,
      ),
    );
  }

  @override
  Widget text(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
  }) {
    return Text(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Future<T?> showFormDialog<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    double? width,
    double? maxHeight,
    EdgeInsets? contentPadding,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
    bool scrollable = true,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    Widget dialogContent = content;
    if (scrollable) {
      dialogContent = SingleChildScrollView(
        child: content,
      );
    }

    if (maxHeight != null) {
      dialogContent = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: dialogContent,
      );
    }

    return showAdaptiveDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: _primaryColor.withValues(alpha: 0.5),
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          child: Container(
            width: isSmallScreen
                ? screenSize.width * 0.9
                : (width ?? DialogResponsiveness.getDialogWidth(context)),
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width * 0.9 : (width ?? 700),
              maxHeight: maxHeight ?? screenSize.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _borderColor, width: 1),
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                    child: title,
                  ),
                ),
                // Content
                Flexible(
                  child: Padding(
                    padding: contentPadding ?? const EdgeInsets.all(20),
                    child: dialogContent,
                  ),
                ),
                // Actions
                if (actions != null && actions.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: _borderColor, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions.map((action) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
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
  }) {
    final isMobile = DialogResponsiveness.isMobile(context);

    if (isMobile && fullscreenOnMobile) {
      // Full-screen modal for mobile
      return Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(title),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0,
              shape: const Border(
                bottom: BorderSide(color: _borderColor, width: 1),
              ),
              leading: leading ??
                  (showCloseButton
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : null),
              actions: actions,
            ),
            body: builder(context),
          ),
        ),
      );
    } else {
      // Dialog for desktop/tablet
      return showAdaptiveDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierColor: _primaryColor.withValues(alpha: 0.5),
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          child: Container(
            width: desktopWidth ?? 800,
            constraints: BoxConstraints(
              maxWidth: desktopMaxWidth ?? 900,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _borderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      if (actions != null)
                        ...actions
                      else if (showCloseButton)
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: _mutedForeground),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: builder(dialogContext),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Future<T?> showActionSheet<T>({
    required BuildContext context,
    required List<AdaptiveActionSheetItem<T>> actions,
    Widget? title,
    Widget? message,
    bool showCancelButton = true,
    String? cancelButtonText,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: _borderColor, width: 1),
            left: BorderSide(color: _borderColor, width: 1),
            right: BorderSide(color: _borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || message != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedForeground,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          child: title,
                        ),
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                          child: message,
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: _borderColor, height: 1),
              ],
              ...actions.map((action) {
                final isDestructive = action.isDestructive;
                final isDefault = action.isDefault;

                return InkWell(
                  onTap: action.enabled
                      ? () => Navigator.of(sheetContext).pop(action.value)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        if (action.icon != null) ...[
                          Icon(
                            action.icon,
                            size: 20,
                            color: isDestructive
                                ? Colors.red
                                : (action.enabled
                                    ? _primaryColor
                                    : _mutedForeground),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDestructive
                                  ? Colors.red
                                  : (action.enabled
                                      ? _primaryColor
                                      : _mutedForeground),
                              fontWeight: isDefault
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (showCancelButton) ...[
                const Divider(color: _borderColor, height: 1),
                InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        cancelButtonText ?? 'Cancel',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: _primaryColor.withValues(alpha: 0.5),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: _borderColor, width: 1),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 48,
                        color: isDestructive ? Colors.red : _primaryColor,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    outlinedButton(
                      label: cancelText ?? 'Cancel',
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                    const SizedBox(width: 8),
                    button(
                      label: confirmText ?? 'Confirm',
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: isDestructive
                          ? ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.red),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Dialog Utilities

  @override
  void dismissDialog(BuildContext context) {
    if (hasDialog(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  bool hasDialog(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).canPop();
  }

  @override
  void dismissDialogIfShowing(BuildContext context) {
    if (hasDialog(context)) {
      dismissDialog(context);
    }
  }

  @override
  LoadingDialogController showLoadingDialog({
    required BuildContext context,
    String? message,
    bool dismissible = false,
  }) {
    final controller = LoadingDialogController(
      context: context,
      initialMessage: message,
      dismissible: dismissible,
    );

    final dialogFuture = showAdaptiveDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) {
        // Pass the dialog context to the controller
        controller.setDialogContext(dialogContext);
        return AlertDialog(
          backgroundColor: Colors.white,
          content: ValueListenableBuilder<String?>(
            valueListenable: controller.messageNotifier,
            builder: (context, currentMessage, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: _primaryColor,
                  ),
                  if (currentMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      currentMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );

    // Store the future in the controller for proper cleanup
    controller.setDialogFuture(dialogFuture);

    return controller;
  }

  @override
  ProgressDialogController showProgressDialog({
    required BuildContext context,
    String? title,
    String? initialMessage,
    int totalSteps = 1,
    bool dismissible = false,
  }) {
    final controller = ProgressDialogController(
      context: context,
      initialMessage: initialMessage,
      totalSteps: totalSteps,
      dismissible: dismissible,
    );

    showAdaptiveDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: title != null
            ? Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              )
            : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: controller.progressNotifier,
              builder: (context, progress, _) {
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _mutedColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_primaryColor),
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: controller.messageNotifier,
              builder: (context, currentMessage, _) {
                return Text(
                  currentMessage ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    return controller;
  }
}
