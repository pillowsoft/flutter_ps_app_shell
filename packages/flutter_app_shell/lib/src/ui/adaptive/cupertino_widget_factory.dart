import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' as material show showDateRangePicker;
import 'package:flutter/material.dart'
    show
        Material,
        Scaffold,
        ButtonStyle,
        ThemeMode,
        Widget,
        Key,
        BuildContext,
        VoidCallback,
        Icon,
        WidgetBuilder,
        Color,
        IconData,
        CrossAxisAlignment,
        Column,
        EdgeInsets,
        TextEditingController,
        FormFieldValidator,
        ValueChanged,
        TextInputType,
        GlobalKey,
        FormState,
        TimeOfDay,
        DateTimeRange,
        RangeValues,
        TabController,
        Step,
        SnackBar,
        SnackBarAction,
        SnackBarClosedReason,
        ScaffoldFeatureController,
        ScaffoldMessenger,
        AlwaysStoppedAnimation,
        NavigationRail,
        NavigationRailDestination,
        NavigationRailLabelType,
        Theme,
        ThemeData,
        RangeSlider,
        SliderThemeData,
        Checkbox,
        CheckboxThemeData,
        MaterialStateProperty,
        MaterialState,
        RoundedRectangleBorder,
        BorderRadius,
        TabBar,
        TabBarTheme,
        TabBarThemeData,
        TabBarView,
        ExpansionTile,
        ExpansionTileTheme,
        ExpansionTileThemeData,
        LinearProgressIndicator,
        CircularProgressIndicator,
        ProgressIndicatorThemeData,
        Stepper,
        ColorScheme,
        ToggleButtons,
        ToggleButtonsTheme,
        ToggleButtonsThemeData,
        Tooltip,
        TooltipTheme,
        TooltipThemeData,
        BoxDecoration,
        TextStyle,
        FontWeight,
        Badge,
        SnackBarBehavior,
        BorderSide,
        PreferredSizeWidget,
        TextAlign,
        TextDirection,
        Locale,
        TextOverflow,
        Colors,
        Navigator;
import 'package:flutter/foundation.dart';
import 'adaptive_widget_factory.dart';
import '../../core/app_route.dart';
import 'components/adaptive_dialog_models.dart';
import '../dialog/dialog_handle.dart';

/// Cupertino (iOS) implementation of the adaptive widget factory
class CupertinoWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? drawer,
    Widget? bottomNavBar,
    Color? backgroundColor,
  }) {
    // Check if we're on desktop
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    // Wrap body with SafeArea on desktop to handle window chrome
    final wrappedBody = isDesktop
        ? SafeArea(
            top: true, // Handle top window chrome
            bottom: false,
            child: body,
          )
        : body;

    // Priority: Bottom navigation first, then drawer
    // This ensures apps with few routes get bottom tabs instead of drawer fallback
    if (bottomNavBar != null) {
      // Use CupertinoPageScaffold with bottom navigation
      final effectiveBackgroundColor =
          backgroundColor ?? CupertinoColors.systemGroupedBackground;

      // Platform-specific SystemUiOverlayStyle
      // Note: systemNavigationBarColor only works on Android
      // iOS home indicator color auto-adapts based on background beneath it
      final overlayStyle = defaultTargetPlatform == TargetPlatform.iOS
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.light, // iOS: light = dark icons
              statusBarIconBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor:
                  effectiveBackgroundColor, // Android only
              systemNavigationBarIconBrightness: Brightness.dark,
            );

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: CupertinoPageScaffold(
          key: key,
          navigationBar: appBar as ObstructingPreferredSizeWidget?,
          backgroundColor: Colors.transparent, // Let Container handle color
          child: Container(
            color: effectiveBackgroundColor,
            child: SafeArea(
              top: false, // Nav bar handles top spacing
              bottom: false, // Allow extension to home indicator
              child: Column(
                children: [
                  Expanded(child: wrappedBody),
                  bottomNavBar,
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If drawer is needed, wrap with Material Scaffold
    // CupertinoPageScaffold doesn't support drawers natively
    if (drawer != null) {
      return Material(
        child: Scaffold(
          key: key,
          appBar: appBar as PreferredSizeWidget?,
          drawer: drawer,
          body: wrappedBody,
          bottomNavigationBar:
              bottomNavBar, // This will be null when drawer is used
          backgroundColor: backgroundColor,
        ),
      );
    }

    final effectiveBackgroundColor =
        backgroundColor ?? CupertinoColors.systemGroupedBackground;

    // Platform-specific SystemUiOverlayStyle
    // Note: systemNavigationBarColor only works on Android
    // iOS home indicator color auto-adapts based on background beneath it
    final overlayStyle = defaultTargetPlatform == TargetPlatform.iOS
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light, // iOS: light = dark icons
            statusBarIconBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: effectiveBackgroundColor, // Android only
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: CupertinoPageScaffold(
        key: key,
        navigationBar: appBar as ObstructingPreferredSizeWidget?,
        backgroundColor: Colors.transparent, // Let Container handle color
        child: Container(
          color: effectiveBackgroundColor,
          child: SafeArea(
            top: false, // Nav bar handles top spacing
            bottom: false, // Allow extension to home indicator
            child: wrappedBody,
          ),
        ),
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
      // For large titles, return CupertinoSliverNavigationBar
      // Note: This should be used within a CustomScrollView
      return CupertinoSliverNavigationBar(
        key: key,
        largeTitle: title,
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
                icon: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(item.icon),
                ),
                activeIcon: item.activeIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Icon(item.activeIcon!),
                      )
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
  Widget radio<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    Color? activeColor,
  }) {
    // Cupertino doesn't have a native radio widget, so we use a custom implementation
    final isSelected = value == groupValue;
    return GestureDetector(
      key: key,
      onTap: onChanged != null ? () => onChanged(value) : null,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (activeColor ?? CupertinoColors.systemBlue)
                : CupertinoColors.inactiveGray,
            width: isSelected ? 8 : 2,
          ),
          color: isSelected
              ? (activeColor ?? CupertinoColors.systemBlue)
              : CupertinoColors.systemBackground,
        ),
      ),
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
    return CupertinoListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
      onTap: onChanged != null ? () => onChanged(value) : null,
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

    return CupertinoButton.filled(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(child: buttonChild!),
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
    return CupertinoButton.filled(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label),
          ],
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
    return CupertinoButton(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.activeBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: CupertinoColors.activeBlue),
          ),
        ),
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
    return CupertinoButton(
      key: key,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.activeBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: CupertinoColors.activeBlue),
            ),
          ],
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
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions?.map((action) {
              // Wrap actions to use correct context
              if (action is CupertinoButton) {
                return CupertinoDialogAction(
                  onPressed: action.onPressed,
                  child: action.child,
                );
              }
              return action;
            }).toList() ??
            [],
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
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
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
              if (effectiveLabel != null) ...[
                Text(
                  effectiveLabel,
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
                prefix: prefixIcon != null
                    ? Padding(
                        padding: prefixIconPadding ??
                            const EdgeInsets.only(left: 8, right: 4),
                        child: prefixIcon,
                      )
                    : null,
                suffix: suffixIcon != null
                    ? Padding(
                        padding: suffixIconPadding ??
                            const EdgeInsets.only(left: 4, right: 8),
                        child: suffixIcon,
                      )
                    : null,
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
        if (effectiveLabel != null) ...[
          Text(
            effectiveLabel,
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
          prefix: prefixIcon != null
              ? Padding(
                  padding: prefixIconPadding ??
                      const EdgeInsets.only(left: 8, right: 4),
                  child: prefixIcon,
                )
              : null,
          suffix: suffixIcon != null
              ? Padding(
                  padding: suffixIconPadding ??
                      const EdgeInsets.only(left: 4, right: 8),
                  child: suffixIcon,
                )
              : null,
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
      height: height ?? 0.5,
      margin: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
      ),
      color: color ?? CupertinoColors.separator,
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
        shape: BoxShape.circle,
        color: backgroundColor ?? CupertinoColors.systemGrey5,
      ),
      alignment: Alignment.center,
      child: child ??
          (text != null
              ? Text(
                  text,
                  style: TextStyle(
                    color: foregroundColor ?? CupertinoColors.label,
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
      case 'home':
        return CupertinoIcons.house;
      case 'dashboard':
        return CupertinoIcons.rectangle_grid_2x2;
      case 'person':
        return CupertinoIcons.person;
      case 'palette':
        return CupertinoIcons.paintbrush;
      default:
        return CupertinoIcons.question_circle;
    }
  }

  // Extended Adaptive Components - Cupertino implementations

  @override
  Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime? selectedDate = initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            mode: CupertinoDatePickerMode.date,
            minimumDate: firstDate,
            maximumDate: lastDate,
            onDateTimeChanged: (DateTime newDate) {
              selectedDate = newDate;
            },
          ),
        ),
      ),
    );

    return selectedDate;
  }

  @override
  Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    DateTime initialDateTime = DateTime(
      2000,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );
    DateTime? selectedTime = initialDateTime;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDateTime,
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            onDateTimeChanged: (DateTime newTime) {
              selectedTime = newTime;
            },
          ),
        ),
      ),
    );

    return selectedTime != null
        ? TimeOfDay(hour: selectedTime!.hour, minute: selectedTime!.minute)
        : null;
  }

  @override
  Future<DateTimeRange?> showDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Cupertino doesn't have a native date range picker, fallback to Material
    return await material.showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
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
    // Cupertino doesn't have a native range slider, use Material with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        sliderTheme: SliderThemeData(
          activeTrackColor: activeColor ?? CupertinoColors.activeBlue,
          inactiveTrackColor: inactiveColor ?? CupertinoColors.systemGrey4,
          thumbColor: CupertinoColors.white,
          overlayColor: CupertinoColors.activeBlue.withOpacity(0.1),
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
    return CupertinoSlider(
      key: key,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      divisions: divisions,
      activeColor: activeColor,
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
    // Cupertino doesn't have chips, create custom implementation
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[avatar, const SizedBox(width: 4)],
          label,
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDeleted,
              child: deleteIcon ??
                  Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: deleteIconColor ?? CupertinoColors.systemGrey,
                  ),
            ),
          ],
        ],
      ),
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
    return CupertinoButton(
      key: key,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      color: backgroundColor ?? CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[avatar, const SizedBox(width: 4)],
          label,
        ],
      ),
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
    return CupertinoButton(
      key: key,
      onPressed: () => onSelected(!selected),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      color: selected
          ? (selectedColor ?? CupertinoColors.activeBlue)
          : (backgroundColor ?? CupertinoColors.systemGrey6),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[avatar, const SizedBox(width: 4)],
          DefaultTextStyle(
            style: TextStyle(
              color: selected ? CupertinoColors.white : CupertinoColors.label,
            ),
            child: label,
          ),
        ],
      ),
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
    return choiceChip(
      key: key,
      label: label,
      selected: selected,
      onSelected: onSelected,
      avatar: avatar,
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
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
    // Cupertino doesn't have checkboxes, use Material checkbox with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return activeColor ?? CupertinoColors.activeBlue;
            }
            return CupertinoColors.systemGrey4;
          }),
          checkColor:
              MaterialStateProperty.all(checkColor ?? CupertinoColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      child: Checkbox(
        key: key,
        value: value,
        onChanged: onChanged,
      ),
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
    return CupertinoListTile(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: secondary,
      trailing: checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      ),
      onTap: () => onChanged(!(value ?? false)),
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
    // Use Material TabBar with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        tabBarTheme: TabBarThemeData(
          labelColor: labelColor ?? CupertinoColors.activeBlue,
          unselectedLabelColor:
              unselectedLabelColor ?? CupertinoColors.systemGrey,
          indicatorColor: indicatorColor ?? CupertinoColors.activeBlue,
        ),
      ),
      child: TabBar(
        key: key,
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
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
    // Use Material ExpansionTile with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
          collapsedBackgroundColor:
              collapsedBackgroundColor ?? CupertinoColors.systemBackground,
          iconColor: CupertinoColors.systemGrey,
          collapsedIconColor: CupertinoColors.systemGrey,
        ),
      ),
      child: ExpansionTile(
        key: key,
        title: title,
        leading: leading,
        trailing: trailing,
        children: children,
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
        backgroundColor: backgroundColor ?? CupertinoColors.systemGrey4,
        valueColor:
            AlwaysStoppedAnimation(valueColor ?? CupertinoColors.activeBlue),
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
    if (value != null) {
      // Use Material CircularProgressIndicator for determinate progress
      return Theme(
        data: ThemeData.light().copyWith(
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: valueColor ?? CupertinoColors.activeBlue,
          ),
        ),
        child: CircularProgressIndicator(
          key: key,
          value: value,
          backgroundColor: backgroundColor,
          strokeWidth: strokeWidth ?? 2.0,
        ),
      );
    }

    // Use CupertinoActivityIndicator for indeterminate progress
    return CupertinoActivityIndicator(
      key: key,
      radius: (strokeWidth ?? 2.0) * 5,
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
    // Use Material Stepper with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: CupertinoColors.activeBlue,
        ),
      ),
      child: Stepper(
        key: key,
        currentStep: currentStep,
        steps: steps,
        onStepTapped: onStepTapped,
        onStepContinue: onStepContinue,
        onStepCancel: onStepCancel,
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
    return CupertinoSlidingSegmentedControl<T>(
      key: key,
      children: children,
      groupValue: groupValue,
      onValueChanged: (T? value) {
        if (value != null) onValueChanged(value);
      },
      thumbColor: thumbColor ?? CupertinoColors.white,
      backgroundColor: backgroundColor ?? CupertinoColors.tertiarySystemFill,
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
    // Use Material ToggleButtons with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        toggleButtonsTheme: ToggleButtonsThemeData(
          color: color ?? CupertinoColors.systemGrey,
          selectedColor: selectedColor ?? CupertinoColors.white,
          fillColor: fillColor ?? CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: ToggleButtons(
        key: key,
        children: children,
        isSelected: isSelected,
        onPressed: onPressed,
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
    // Use Material Tooltip with iOS styling
    return Theme(
      data: ThemeData.light().copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: CupertinoColors.darkBackgroundGray,
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 12,
          ),
        ),
      ),
      child: Tooltip(
        key: key,
        message: message,
        child: child,
        height: height,
        padding: padding,
        waitDuration: waitDuration,
      ),
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
    // Use Material Badge with iOS styling
    return Badge(
      key: key,
      isLabelVisible: isLabelVisible,
      label: label,
      backgroundColor: backgroundColor ?? CupertinoColors.systemRed,
      textColor: textColor ?? CupertinoColors.white,
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
    // Use iOS-style notification overlay for Cupertino
    return _CupertinoNotificationController._show(
      context: context,
      message: message,
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
    );
  }

  // Navigation and Layout Helpers

  @override
  Widget navigationRail({
    required int currentIndex,
    required List<AppRoute> routes,
    required ValueChanged<int> onDestinationSelected,
    required bool showLabels,
  }) {
    // Create a custom Cupertino-style vertical navigation
    return Builder(
      builder: (context) => Container(
        width: 88,
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground,
          context,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: routes
                  .where((route) => route.showInNavigation)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final route = entry.value;
                final isSelected = currentIndex >= 0 && index == currentIndex;

                return CupertinoButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () => onDestinationSelected(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        route.icon,
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.inactiveGray,
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 4),
                        Text(
                          route.title,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget? drawerButton(BuildContext context) {
    // Cupertino needs manual drawer button
    return Builder(
      builder: (scaffoldContext) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
        child: const Icon(CupertinoIcons.bars, size: 24),
      ),
    );
  }

  @override
  bool shouldAddDrawerButton() {
    // Cupertino needs manual drawer button
    return true;
  }

  @override
  bool needsDesktopPadding() {
    // Cupertino handles its own desktop padding
    return false;
  }

  @override
  bool appBarCenterTitle() {
    // iOS typically centers title
    return true;
  }

  @override
  Widget pageTitle(String title) {
    // iOS uses navigation bar titles, so page titles are not needed
    return const SizedBox.shrink();
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
    // Check if we're on desktop
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    // Create the sliver list with navigation bar
    final sliverList = [
      if (largeTitle != null)
        CupertinoSliverNavigationBar(
          key: key,
          largeTitle: largeTitle,
          leading: leading,
          trailing: actions != null && actions.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                )
              : null,
          automaticallyImplyLeading: automaticallyImplyLeading,
        ),
      ...slivers,
    ];

    // Build the scroll view
    Widget scrollView = CustomScrollView(
      slivers: sliverList,
    );

    // Wrap with SafeArea on desktop to handle window chrome
    if (isDesktop) {
      scrollView = SafeArea(
        top: true, // Handle top window chrome
        bottom: false,
        child: scrollView,
      );
    }

    // If drawer is needed, wrap with Material Scaffold
    // CupertinoPageScaffold doesn't support drawers natively
    if (drawer != null) {
      return Material(
        child: Scaffold(
          drawer: drawer,
          body: scrollView,
          bottomNavigationBar: bottomNavBar,
          backgroundColor: backgroundColor,
        ),
      );
    }

    if (bottomNavBar != null) {
      // Use CupertinoPageScaffold with bottom navigation
      return CupertinoPageScaffold(
        backgroundColor:
            backgroundColor ?? CupertinoColors.systemGroupedBackground,
        child: Column(
          children: [
            Expanded(child: scrollView),
            bottomNavBar,
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor:
          backgroundColor ?? CupertinoColors.systemGroupedBackground,
      child: scrollView,
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
    return Builder(
      builder: (context) => GestureDetector(
        key: key,
        onTap: () => _showCupertinoActionSheet<T>(
          context: context,
          items: items,
          onSelected: onSelected,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(8.0),
          child: child ?? icon ?? const Icon(CupertinoIcons.ellipsis),
        ),
      ),
    );
  }

  void _showCupertinoActionSheet<T>({
    required BuildContext context,
    required List<AdaptivePopupMenuItem<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: items
              .where((item) => item.enabled)
              .map((item) => CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSelected(item.value);
                    },
                    isDestructiveAction: item.destructive,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.leading != null) ...[
                          item.leading!,
                          const SizedBox(width: 8.0),
                        ],
                        item.child,
                      ],
                    ),
                  ))
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
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
    return GestureDetector(
      key: key,
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
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

  // Enhanced Dialog Methods

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
    final isMobile = DialogResponsiveness.isMobile(context);

    if (isMobile) {
      // Use full-screen modal on iPhone
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (routeContext) => CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: title,
              leading: barrierDismissible
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(routeContext).pop(),
                    )
                  : null,
              trailing: actions != null && actions.isNotEmpty
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () {
                        // Trigger the first action if available
                        if (actions.isNotEmpty &&
                            actions.first is CupertinoButton) {
                          (actions.first as CupertinoButton).onPressed?.call();
                        }
                      },
                    )
                  : null,
            ),
            child: SafeArea(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: contentPadding ?? const EdgeInsets.all(16),
                      child: content,
                    )
                  : Padding(
                      padding: contentPadding ?? const EdgeInsets.all(16),
                      child: content,
                    ),
            ),
          ),
        ),
      );
    } else {
      // Custom dialog for iPad/macOS
      final dialogWidth =
          DialogResponsiveness.getDialogWidth(context, requested: width);
      final dialogMaxHeight = DialogResponsiveness.getDialogMaxHeight(context,
          requested: maxHeight);

      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) => Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: width ?? dialogWidth,
              minWidth: 280,
              maxHeight: dialogMaxHeight,
            ),
            decoration: BoxDecoration(
              color:
                  CupertinoColors.systemBackground.resolveFrom(dialogContext),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    // Custom navigation bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground
                            .resolveFrom(dialogContext),
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator
                                .resolveFrom(dialogContext),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: NavigationToolbar(
                        middle: DefaultTextStyle(
                          style: CupertinoTheme.of(dialogContext)
                              .textTheme
                              .navTitleTextStyle,
                          child: title,
                        ),
                        trailing: barrierDismissible
                            ? CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(
                                    CupertinoIcons.xmark_circle_fill),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              )
                            : null,
                      ),
                    ),
                    // Content
                    Expanded(
                      child: scrollable
                          ? SingleChildScrollView(
                              padding:
                                  contentPadding ?? const EdgeInsets.all(20),
                              child: content,
                            )
                          : Padding(
                              padding:
                                  contentPadding ?? const EdgeInsets.all(20),
                              child: content,
                            ),
                    ),
                    // Actions
                    if (actions != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: CupertinoColors.separator
                                  .resolveFrom(dialogContext),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: actions,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
      // Full screen on mobile
      return Navigator.of(context, rootNavigator: true).push<T>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (routeContext) => CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(title),
              leading: leading ??
                  (showCloseButton
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Close'),
                          onPressed: () => Navigator.of(routeContext).pop(),
                        )
                      : null),
              trailing: actions != null && actions.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    )
                  : null,
            ),
            child: SafeArea(
              child: builder(routeContext),
            ),
          ),
        ),
      );
    } else {
      // Dialog on desktop/tablet
      return showFormDialog<T>(
        context: context,
        title: Text(title),
        content: builder(context),
        actions: actions,
        width: desktopWidth ?? desktopMaxWidth,
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
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: title,
        message: message,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            onPressed: action.enabled
                ? () => Navigator.of(sheetContext).pop(action.value)
                : () {}, // Provide no-op function for disabled actions
            isDestructiveAction: action.isDestructive,
            isDefaultAction: action.isDefault,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(
                    action.icon,
                    size: 20,
                    color: action.isDestructive
                        ? CupertinoColors.destructiveRed
                        : action.isDefault
                            ? CupertinoTheme.of(sheetContext).primaryColor
                            : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(action.label),
              ],
            ),
          );
        }).toList(),
        cancelButton: showCancelButton
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(cancelButtonText ?? 'Cancel'),
              )
            : null,
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
    return showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Column(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: isDestructive ? CupertinoColors.destructiveRed : null,
              ),
              const SizedBox(height: 8),
            ],
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            isDestructiveAction: isDestructive,
            isDefaultAction: !isDestructive,
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
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

    final dialogFuture = showCupertinoDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) {
        // Pass the dialog context to the controller
        controller.setDialogContext(dialogContext);
        return CupertinoAlertDialog(
          content: ValueListenableBuilder<String?>(
            valueListenable: controller.messageNotifier,
            builder: (context, currentMessage, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(),
                  if (currentMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      currentMessage,
                      textAlign: TextAlign.center,
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

    showCupertinoDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: controller.progressNotifier,
              builder: (context, progress, _) {
                // iOS doesn't have a native linear progress indicator in dialogs
                // We'll use a custom one or the activity indicator
                if (progress != null) {
                  return Container(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: CupertinoColors.systemGrey5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                } else {
                  return const CupertinoActivityIndicator();
                }
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: controller.messageNotifier,
              builder: (context, currentMessage, _) {
                return Text(
                  currentMessage ?? '',
                  textAlign: TextAlign.center,
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

/// iOS-style notification controller wrapper that acts like ScaffoldFeatureController
class _CupertinoNotificationController {
  final OverlayEntry _overlayEntry;
  final Completer<SnackBarClosedReason> _completer =
      Completer<SnackBarClosedReason>();
  bool _isDisposed = false;
  late final _controller = _CupertinoSnackBarController(this);

  _CupertinoNotificationController._({required OverlayEntry overlayEntry})
      : _overlayEntry = overlayEntry;

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show({
    required BuildContext context,
    required String message,
    required Duration duration,
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    late OverlayEntry overlayEntry;
    late _CupertinoNotificationController wrapper;

    overlayEntry = OverlayEntry(
      builder: (context) => _CupertinoNotificationWidget(
        message: message,
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        onDismissed: (reason) {
          if (!wrapper._isDisposed) {
            wrapper._hide();
            if (!wrapper._completer.isCompleted) {
              wrapper._completer.complete(reason);
            }
          }
        },
      ),
    );

    wrapper = _CupertinoNotificationController._(overlayEntry: overlayEntry);

    // Insert the overlay
    Overlay.of(context).insert(overlayEntry);

    return wrapper._controller;
  }

  void _hide() {
    if (!_isDisposed) {
      _isDisposed = true;
      _overlayEntry.remove();
      if (!_completer.isCompleted) {
        _completer.complete(SnackBarClosedReason.hide);
      }
    }
  }

  void _setState(void Function() fn) {
    // Since we're using an overlay, we need to mark it as dirty
    if (!_isDisposed) {
      _overlayEntry.markNeedsBuild();
      fn();
    }
  }
}

/// The actual ScaffoldFeatureController implementation
class _CupertinoSnackBarController
    implements ScaffoldFeatureController<SnackBar, SnackBarClosedReason> {
  final _CupertinoNotificationController _wrapper;

  _CupertinoSnackBarController(this._wrapper);

  @override
  void Function() get close => _wrapper._hide;

  @override
  Future<SnackBarClosedReason> get closed => _wrapper._completer.future;

  @override
  bool get isDisposed => _wrapper._isDisposed;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  // ScaffoldFeatureController has setState as a property, not a method
  @override
  void Function(void Function()) get setState => _wrapper._setState;
}

/// iOS-style notification widget
class _CupertinoNotificationWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final SnackBarAction? action;
  final Color? backgroundColor;
  final Function(SnackBarClosedReason) onDismissed;

  const _CupertinoNotificationWidget({
    required this.message,
    required this.duration,
    required this.onDismissed,
    this.action,
    this.backgroundColor,
  });

  @override
  State<_CupertinoNotificationWidget> createState() =>
      _CupertinoNotificationWidgetState();
}

class _CupertinoNotificationWidgetState
    extends State<_CupertinoNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Auto-dismiss after duration
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss(SnackBarClosedReason.timeout);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss(SnackBarClosedReason reason) {
    if (!mounted) return;

    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed(reason);
      }
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(-50, 0);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset < -20 || details.velocity.pixelsPerSecond.dy < -100) {
      _dismiss(SnackBarClosedReason.swipe);
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: GestureDetector(
              onVerticalDragUpdate: _handleVerticalDragUpdate,
              onVerticalDragEnd: _handleVerticalDragEnd,
              onTap: () {
                if (widget.action != null) {
                  widget.action!.onPressed();
                  _dismiss(SnackBarClosedReason.action);
                }
              },
              child: Container(
                margin: EdgeInsets.only(
                  top: topPadding + 8,
                  left: 8,
                  right: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ??
                            CupertinoColors.systemBackground
                                .resolveFrom(context)
                                .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.message,
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (widget.action != null) ...[
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              onPressed: () {
                                widget.action!.onPressed();
                                _dismiss(SnackBarClosedReason.action);
                              },
                              child: Text(
                                widget.action!.label,
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
