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
        TextStyle,
        FontWeight,
        DialogThemeData,
        RoundedRectangleBorder,
        BorderRadius,
        DatePickerThemeData,
        MaterialStateProperty,
        MaterialState,
        BorderSide,
        TimePickerThemeData,
        SingleChildScrollView,
        ConstrainedBox,
        BoxConstraints,
        IntrinsicHeight,
        Row,
        MainAxisSize,
        SizedBox,
        Expanded,
        DefaultTextStyle,
        Colors,
        Material,
        PopupMenuItem,
        TextAlign,
        TextDirection,
        Locale,
        TextOverflow,
        Navigator,
        MediaQuery,
        showDialog,
        showModalBottomSheet,
        showDatePicker,
        showTimePicker,
        showDateRangePicker,
        AnnotatedRegion,
        Brightness;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'adaptive_widget_factory.dart';
import 'components/adaptive_dialog_models.dart';
import '../../core/app_route.dart';
import '../dialog/dialog_handle.dart';

/// Material Design implementation of the adaptive widget factory
class MaterialWidgetFactory extends AdaptiveWidgetFactory {
  @override
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? drawer,
    Widget? bottomNavBar,
    Color? backgroundColor,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Dark icons on light Material background
        systemNavigationBarColor: backgroundColor ?? Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: material.Scaffold(
        key: key,
        appBar: appBar as material.PreferredSizeWidget?,
        drawer: drawer,
        body: body,
        bottomNavigationBar: bottomNavBar,
        backgroundColor: backgroundColor,
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
      // For large titles, return SliverAppBar with flexibleSpace
      // Note: This should be used within a CustomScrollView
      return material.SliverAppBar(
        key: key,
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        expandedHeight: 120.0,
        floating: true,
        pinned: true,
        flexibleSpace: material.FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
          title: title,
        ),
      );
    }

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
    // Use NavigationBar (Material 3) instead of BottomNavigationBar
    return material.NavigationBar(
      key: key,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items
          .map((item) => material.NavigationDestination(
                icon: material.Icon(item.icon),
                selectedIcon: item.activeIcon != null
                    ? material.Icon(item.activeIcon!)
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
  Widget radio<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    Color? activeColor,
  }) {
    return material.Radio<T>(
      key: key,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor,
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
    return material.RadioListTile<T>(
      key: key,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      secondary: leading,
      activeColor: activeColor,
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
    final buttonChild = child ?? (label != null ? material.Text(label) : null);
    assert(buttonChild != null, 'Either label or child must be provided');

    return material.FilledButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: buttonChild!,
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
    return material.FilledButton.icon(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: material.Text(label),
      style: style,
    );
  }

  @override
  Widget outlinedButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  }) {
    return material.OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: material.Text(label),
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
    return material.OutlinedButton.icon(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: material.Text(label),
      style: style,
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
    Widget? title,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: material.DefaultTextStyle(
                style: material.TextStyle(
                  fontSize: 16,
                  fontWeight: material.FontWeight.w600,
                  color: material.Colors.blue.shade700, // Material blue header
                  letterSpacing: 0.5,
                ),
                child: header,
              ),
            ),
          // Material Design Card with prominent elevation and Material styling
          material.Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 8, // Prominent Material elevation
            shadowColor: material.Colors.black.withValues(alpha: 0.3),
            shape: material.RoundedRectangleBorder(
              borderRadius: material.BorderRadius.circular(
                  12), // Material rounded corners
            ),
            child: material.Container(
              decoration: material.BoxDecoration(
                borderRadius: material.BorderRadius.circular(12),
                gradient: material.LinearGradient(
                  begin: material.Alignment.topLeft,
                  end: material.Alignment.bottomRight,
                  colors: [
                    material.Colors.white,
                    material.Colors.blue.shade50, // Subtle Material blue tint
                  ],
                ),
              ),
              child: Column(
                children: children.asMap().entries.map((entry) {
                  final index = entry.key;
                  final child = entry.value;
                  return Column(
                    children: [
                      material.Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: child,
                      ),
                      if (index < children.length - 1)
                        material.Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: material.Divider(
                            height: 1,
                            thickness: 1,
                            color: material
                                .Colors.blue.shade100, // Material blue divider
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          if (footer != null)
            material.Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    final card = material.Card(
      key: key,
      margin: margin ?? const EdgeInsets.all(4),
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
    return material.TextFormField(
      key: key,
      controller: controller,
      decoration: material.InputDecoration(
        labelText: effectiveLabel,
        hintText: hintText,
        border: const material.OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: prefixIconPadding != null
            ? material.BoxConstraints(
                minWidth: prefixIconPadding.left + prefixIconPadding.right + 24,
                minHeight:
                    prefixIconPadding.top + prefixIconPadding.bottom + 24,
              )
            : null,
        suffixIconConstraints: suffixIconPadding != null
            ? material.BoxConstraints(
                minWidth: suffixIconPadding.left + suffixIconPadding.right + 24,
                minHeight:
                    suffixIconPadding.top + suffixIconPadding.bottom + 24,
              )
            : null,
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
    required GlobalKey<FormState> formKey,
    required Widget child,
  }) {
    return material.Form(
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
    return material.Divider(
      key: key,
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
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
    return material.CircleAvatar(
      key: key,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      radius: radius,
      child: child ?? (text != null ? material.Text(text) : null),
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
      theme: material.ThemeData.light(useMaterial3: true),
      darkTheme: material.ThemeData.dark(useMaterial3: true),
      themeMode: themeMode ?? ThemeMode.system,
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
      case 'home':
        return material.Icons.home_outlined;
      case 'dashboard':
        return material.Icons.dashboard_outlined;
      case 'person':
        return material.Icons.person_outlined;
      case 'palette':
        return material.Icons.palette_outlined;
      default:
        return material.Icons.help_outline;
    }
  }

  // Extended Adaptive Components - Material implementations

  @override
  Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return material.showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary:
                      material.Colors.blue.shade600, // Material blue primary
                  onPrimary: material.Colors.white,
                  surface: material.Colors.white,
                  onSurface: material.Colors.grey.shade800,
                  surfaceVariant: material.Colors.blue.shade50,
                  onSurfaceVariant: material.Colors.grey.shade700,
                  outline: material.Colors.blue.shade200,
                ),
            dialogBackgroundColor: material.Colors.white,
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16), // Material rounded corners
              ),
              elevation: 24, // Material elevation
              shadowColor: material.Colors.black.withValues(alpha: 0.2),
              backgroundColor: material.Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: material.Colors.white,
              elevation: 24, // Material elevation
              shadowColor: material.Colors.black.withValues(alpha: 0.2),
              surfaceTintColor: material.Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16), // Material rounded corners
              ),
              headerBackgroundColor: material.Colors.blue.shade600,
              headerForegroundColor: material.Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: material.Colors.white,
              ),
              headerHelpStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: material.Colors.blue.shade100,
              ),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return material.Colors.white;
                }
                if (states.contains(MaterialState.disabled)) {
                  return material.Colors.grey.shade400;
                }
                return material.Colors.grey.shade800;
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return material.Colors.blue.shade600;
                }
                if (states.contains(MaterialState.hovered)) {
                  return material.Colors.blue.shade50;
                }
                return null;
              }),
              dayShape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12), // Material rounded corners
                ),
              ),
              dayOverlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered)) {
                  return material.Colors.blue.shade100;
                }
                if (states.contains(MaterialState.pressed)) {
                  return material.Colors.blue.shade200;
                }
                return null;
              }),
              todayForegroundColor:
                  MaterialStateProperty.all(material.Colors.blue.shade600),
              todayBackgroundColor:
                  MaterialStateProperty.all(material.Colors.blue.shade50),
              todayBorder:
                  BorderSide(color: material.Colors.blue.shade600, width: 2),
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
  }) {
    return material.showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary:
                      material.Colors.blue.shade600, // Material blue primary
                  onPrimary: material.Colors.white,
                  surface: material.Colors.white,
                  onSurface: material.Colors.grey.shade800,
                  surfaceVariant: material.Colors.blue.shade50,
                  onSurfaceVariant: material.Colors.grey.shade700,
                  outline: material.Colors.blue.shade200,
                ),
            dialogBackgroundColor: material.Colors.white,
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16), // Material rounded corners
              ),
              elevation: 24, // Material elevation
              shadowColor: material.Colors.black.withValues(alpha: 0.2),
              backgroundColor: material.Colors.white,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: material.Colors.white,
              elevation: 24, // Material elevation
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16), // Material rounded corners
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Material rounded corners
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12), // Material rounded corners
              ),
              hourMinuteTextColor: material.Colors.blue.shade600,
              hourMinuteColor: material.Colors.blue.shade50,
              dayPeriodTextColor: material.Colors.grey.shade700,
              dayPeriodColor: material.Colors.blue.shade50,
              dialHandColor: material.Colors.blue.shade600,
              dialBackgroundColor: material.Colors.blue.shade50,
              dialTextColor: material.Colors.grey.shade800,
              entryModeIconColor: material.Colors.blue.shade600,
              hourMinuteTextStyle: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: material.Colors.blue.shade600,
              ),
              dayPeriodTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: material.Colors.grey.shade700,
              ),
              helpTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: material.Colors.grey.shade600,
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
  }) {
    return material.showDateRangePicker(
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
    return material.RangeSlider(
      key: key,
      values: values,
      min: min,
      max: max,
      onChanged: onChanged,
      divisions: divisions,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
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
    return material.Slider(
      key: key,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      divisions: divisions,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
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
    return material.Chip(
      key: key,
      label: label,
      avatar: avatar,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor,
      deleteIconColor: deleteIconColor,
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
    return material.ActionChip(
      key: key,
      label: label,
      avatar: avatar,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
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
    return material.ChoiceChip(
      key: key,
      label: label,
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
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
    return material.FilterChip(
      key: key,
      label: label,
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
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
    return material.Checkbox(
      key: key,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      checkColor: checkColor,
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
    return material.CheckboxListTile(
      key: key,
      value: value,
      onChanged: onChanged,
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      activeColor: activeColor,
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
    return material.TabBar(
      key: key,
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
    );
  }

  @override
  Widget tabBarView({
    Key? key,
    required TabController controller,
    required List<Widget> children,
  }) {
    return material.TabBarView(
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
    return material.ExpansionTile(
      key: key,
      title: title,
      leading: leading,
      trailing: trailing,
      backgroundColor: backgroundColor,
      collapsedBackgroundColor: collapsedBackgroundColor,
      children: children,
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
    return material.LinearProgressIndicator(
      key: key,
      value: value,
      backgroundColor: backgroundColor,
      valueColor:
          valueColor != null ? AlwaysStoppedAnimation(valueColor) : null,
      minHeight: minHeight,
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
    return material.CircularProgressIndicator(
      key: key,
      value: value,
      backgroundColor: backgroundColor,
      valueColor:
          valueColor != null ? AlwaysStoppedAnimation(valueColor) : null,
      strokeWidth: strokeWidth ?? 4.0,
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
    return material.Stepper(
      key: key,
      currentStep: currentStep,
      steps: steps,
      onStepTapped: onStepTapped,
      onStepContinue: onStepContinue,
      onStepCancel: onStepCancel,
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
    // Material doesn't have a native segmented control, so we'll use ToggleButtons
    final keys = children.keys.toList();
    final widgets = children.values.toList();
    final selectedIndex = groupValue != null ? keys.indexOf(groupValue) : -1;

    return material.ToggleButtons(
      key: key,
      children: widgets,
      isSelected:
          List.generate(widgets.length, (index) => index == selectedIndex),
      onPressed: (index) => onValueChanged(keys[index]),
      fillColor: thumbColor,
      selectedColor: material.Colors.white,
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
    return material.ToggleButtons(
      key: key,
      children: children,
      isSelected: isSelected,
      onPressed: onPressed,
      color: color,
      selectedColor: selectedColor,
      fillColor: fillColor,
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
    return material.Tooltip(
      key: key,
      message: message,
      child: child,
      height: height,
      padding: padding,
      waitDuration: waitDuration,
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
    return material.Badge(
      key: key,
      isLabelVisible: isLabelVisible,
      label: label,
      backgroundColor: backgroundColor,
      textColor: textColor,
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
    final snackBar = material.SnackBar(
      content: material.Text(message),
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
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
    final destinations = routes
        .where((route) => route.showInNavigation)
        .map((route) => NavigationRailDestination(
              icon: Icon(route.icon),
              label: material.Text(route.title),
            ))
        .toList();

    return material.Align(
      alignment: material.Alignment.topCenter,
      child: material.SingleChildScrollView(
        child: material.ConstrainedBox(
          constraints: const material.BoxConstraints(
            minHeight: 0,
          ),
          child: material.IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: currentIndex >= 0
                  ? currentIndex
                  : null, // Allow null for no selection
              onDestinationSelected: onDestinationSelected,
              labelType: showLabels
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.none,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget? drawerButton(BuildContext context) {
    // Material automatically adds drawer button, no need for manual one
    return null;
  }

  @override
  bool shouldAddDrawerButton() {
    // Material scaffold automatically handles drawer button
    return false;
  }

  @override
  bool needsDesktopPadding() {
    // Material needs manual padding on desktop
    return true;
  }

  @override
  bool appBarCenterTitle() {
    // Material typically doesn't center title
    return false;
  }

  @override
  Widget pageTitle(String title) {
    // Material uses prominent page headers
    return material.Padding(
      padding: const EdgeInsets.all(16.0),
      child: material.Text(
        title,
        style: const material.TextStyle(
          fontSize: 32,
          fontWeight: material.FontWeight.bold,
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
        material.SliverAppBar(
          key: key,
          title: largeTitle,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          expandedHeight: 120.0,
          floating: true,
          pinned: true,
          flexibleSpace: material.FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            title: largeTitle,
          ),
        ),
      ...slivers,
    ];

    // Build the custom scroll view
    final scrollView = material.CustomScrollView(
      slivers: sliverList,
    );

    return material.Scaffold(
      key: key,
      body: scrollView,
      drawer: drawer,
      bottomNavigationBar: bottomNavBar,
      backgroundColor: backgroundColor,
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
    return material.PopupMenuButton<T>(
      key: key,
      onSelected: onSelected,
      tooltip: tooltip,
      padding: padding ?? const EdgeInsets.all(8.0),
      icon: icon,
      child: child,
      itemBuilder: (context) => items
          .map((item) => material.PopupMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.leading != null) ...[
                      item.leading!,
                      const SizedBox(width: 12.0),
                    ],
                    Expanded(
                      child: DefaultTextStyle(
                        style: item.destructive
                            ? const TextStyle(color: Colors.red)
                            : const TextStyle(),
                        child: item.child,
                      ),
                    ),
                  ],
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
      child: material.InkWell(
        key: key,
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        borderRadius: borderRadius,
        splashColor: splashColor,
        highlightColor: highlightColor,
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
    return material.Text(
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
    return material.showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;
        final dialogWidth = DialogResponsiveness.getDialogWidth(dialogContext,
            requested: width);
        final dialogMaxHeight = DialogResponsiveness.getDialogMaxHeight(
            dialogContext,
            requested: maxHeight);

        return material.Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(28), // Material 3 large rounding
          ),
          clipBehavior: material.Clip.antiAlias,
          child: material.Container(
            width: dialogWidth,
            constraints: material.BoxConstraints(
              maxWidth: width ?? 800,
              minWidth: 280,
              maxHeight: dialogMaxHeight,
            ),
            child: material.Scaffold(
              backgroundColor: material.Colors.transparent,
              appBar: material.AppBar(
                title: title,
                automaticallyImplyLeading: false,
                backgroundColor: material.Colors.transparent,
                elevation: 0,
                actions: [
                  if (barrierDismissible)
                    material.IconButton(
                      icon: const Icon(material.Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                ],
              ),
              body: scrollable
                  ? SingleChildScrollView(
                      padding: contentPadding ?? const EdgeInsets.all(24),
                      child: content,
                    )
                  : material.Padding(
                      padding: contentPadding ?? const EdgeInsets.all(24),
                      child: content,
                    ),
              bottomNavigationBar: actions != null
                  ? material.Padding(
                      padding: const EdgeInsets.all(16),
                      child: material.Row(
                        mainAxisAlignment: material.MainAxisAlignment.end,
                        children: actions,
                      ),
                    )
                  : null,
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
      // Full screen on mobile
      return Navigator.of(context, rootNavigator: true).push<T>(
        material.MaterialPageRoute(
          fullscreenDialog: true,
          builder: (routeContext) => material.Scaffold(
            appBar: material.AppBar(
              title: material.Text(title),
              leading: leading ??
                  (showCloseButton ? const material.CloseButton() : null),
            ),
            body: builder(routeContext),
            bottomNavigationBar: actions != null
                ? material.BottomAppBar(
                    child: material.Row(
                      mainAxisAlignment: material.MainAxisAlignment.end,
                      children: actions,
                    ),
                  )
                : null,
          ),
        ),
      );
    } else {
      // Dialog on desktop/tablet
      return showFormDialog<T>(
        context: context,
        title: material.Text(title),
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
    return material.showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: material.Radius.circular(20)),
      ),
      builder: (sheetContext) => material.SafeArea(
        child: Column(
          mainAxisSize: material.MainAxisSize.min,
          children: [
            if (title != null || message != null)
              material.Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (title != null)
                      material.DefaultTextStyle(
                        style: Theme.of(sheetContext).textTheme.titleMedium!,
                        child: title,
                      ),
                    if (message != null) ...[
                      const material.SizedBox(height: 8),
                      material.DefaultTextStyle(
                        style: Theme.of(sheetContext).textTheme.bodyMedium!,
                        child: message,
                      ),
                    ],
                  ],
                ),
              ),
            if (title != null || message != null)
              const material.Divider(height: 1),
            ...actions.map((action) {
              final color = action.isDestructive
                  ? material.Colors.red
                  : action.isDefault
                      ? Theme.of(sheetContext).primaryColor
                      : null;

              return material.ListTile(
                enabled: action.enabled,
                leading: action.icon != null
                    ? Icon(action.icon, color: color)
                    : null,
                title: material.Text(
                  action.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: action.isDefault ? FontWeight.bold : null,
                  ),
                ),
                onTap: action.enabled
                    ? () => Navigator.of(sheetContext).pop(action.value)
                    : null,
              );
            }),
            if (showCancelButton) ...[
              const material.Divider(height: 1),
              material.ListTile(
                title: material.Text(cancelButtonText ?? 'Cancel'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ],
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
    return material.showDialog<bool>(
      context: context,
      builder: (dialogContext) => material.AlertDialog(
        icon: icon != null
            ? Icon(
                icon,
                size: 48,
                color: isDestructive ? material.Colors.red : null,
              )
            : null,
        title: material.Text(title),
        content: material.Text(message),
        actions: [
          material.TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: material.Text(cancelText ?? 'Cancel'),
          ),
          material.TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDestructive
                ? material.TextButton.styleFrom(
                    foregroundColor: material.Colors.red,
                  )
                : null,
            child: material.Text(confirmText ?? 'Confirm'),
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

    final dialogFuture = material.showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) {
        // Pass the dialog context to the controller
        controller.setDialogContext(dialogContext);
        return material.AlertDialog(
          content: material.ValueListenableBuilder<String?>(
            valueListenable: controller.messageNotifier,
            builder: (context, currentMessage, _) {
              return material.Column(
                mainAxisSize: material.MainAxisSize.min,
                children: [
                  const material.CircularProgressIndicator(),
                  if (currentMessage != null) ...[
                    const material.SizedBox(height: 16),
                    material.Text(
                      currentMessage,
                      textAlign: material.TextAlign.center,
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

    material.showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => material.AlertDialog(
        title: title != null ? material.Text(title) : null,
        content: material.Column(
          mainAxisSize: material.MainAxisSize.min,
          children: [
            material.ValueListenableBuilder<double?>(
              valueListenable: controller.progressNotifier,
              builder: (context, progress, _) {
                return material.LinearProgressIndicator(
                  value: progress,
                );
              },
            ),
            const material.SizedBox(height: 16),
            material.ValueListenableBuilder<String?>(
              valueListenable: controller.messageNotifier,
              builder: (context, currentMessage, _) {
                return material.Text(
                  currentMessage ?? '',
                  textAlign: material.TextAlign.center,
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
