import 'package:flutter/material.dart';
import '../../core/app_route.dart';
import 'components/adaptive_dialog_models.dart';
import '../dialog/dialog_handle.dart';

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

/// Popup menu item model for adaptive popup menus
class AdaptivePopupMenuItem<T> {
  final T value;
  final Widget child;
  final Widget? leading;
  final bool enabled;
  final bool destructive;

  const AdaptivePopupMenuItem({
    required this.value,
    required this.child,
    this.leading,
    this.enabled = true,
    this.destructive = false,
  });
}

/// Abstract factory for creating platform-specific widgets
abstract class AdaptiveWidgetFactory {
  /// Creates a scaffold with app bar and bottom navigation
  Widget scaffold({
    Key? key,
    Widget? appBar,
    required Widget body,
    Widget? drawer,
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
    bool largeTitle = false,
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

  /// Creates a radio button
  Widget radio<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    Color? activeColor,
  });

  /// Creates a radio list tile
  Widget radioListTile<T>({
    Key? key,
    required T value,
    required T? groupValue,
    required ValueChanged<T?>? onChanged,
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Color? activeColor,
  });

  /// Creates a button
  Widget button({
    Key? key,
    String? label,
    Widget? child,
    required VoidCallback onPressed,
    ButtonStyle? style,
  });

  /// Creates a button with icon
  Widget buttonWithIcon({
    Key? key,
    required Icon icon,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  });

  /// Creates an outlined/secondary button
  Widget outlinedButton({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    ButtonStyle? style,
  });

  /// Creates an outlined button with icon
  Widget outlinedButtonWithIcon({
    Key? key,
    required Icon icon,
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
    Widget? title,
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
  });

  /// Creates a form widget
  Widget form({
    Key? key,
    required GlobalKey<FormState> formKey,
    required Widget child,
  });

  /// Creates a divider
  Widget divider({
    Key? key,
    double? height,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
  });

  /// Creates an avatar/profile picture
  Widget avatar({
    Key? key,
    Widget? child,
    Color? backgroundColor,
    Color? foregroundColor,
    double? radius,
    String? text,
  });

  /// Creates a text widget
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
      case 'camera':
        return Icons.camera_alt;
      case 'video':
        return Icons.videocam;
      case 'people':
        return Icons.people;
      case 'auto_fix':
        return Icons.auto_fix_high;
      default:
        return Icons.help_outline;
    }
  }

  // Extended Adaptive Components

  /// Creates a date picker
  Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  });

  /// Creates a time picker
  Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  });

  /// Creates a date range picker
  Future<DateTimeRange?> showDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  });

  /// Creates a range slider
  Widget rangeSlider({
    Key? key,
    required RangeValues values,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
    int? divisions,
    Color? activeColor,
    Color? inactiveColor,
  });

  /// Creates a slider
  Widget slider({
    Key? key,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
    Color? activeColor,
    Color? inactiveColor,
  });

  /// Creates a chip
  Widget chip({
    Key? key,
    required Widget label,
    Widget? avatar,
    Widget? deleteIcon,
    VoidCallback? onDeleted,
    Color? backgroundColor,
    Color? deleteIconColor,
  });

  /// Creates an action chip
  Widget actionChip({
    Key? key,
    required Widget label,
    required VoidCallback onPressed,
    Widget? avatar,
    Color? backgroundColor,
  });

  /// Creates a choice chip
  Widget choiceChip({
    Key? key,
    required Widget label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
  });

  /// Creates a filter chip
  Widget filterChip({
    Key? key,
    required Widget label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
  });

  /// Creates a checkbox
  Widget checkbox({
    Key? key,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    Color? activeColor,
    Color? checkColor,
  });

  /// Creates a checkbox list tile
  Widget checkboxListTile({
    Key? key,
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required Widget title,
    Widget? subtitle,
    Widget? secondary,
    Color? activeColor,
  });

  /// Creates a tab bar
  Widget tabBar({
    Key? key,
    required TabController controller,
    required List<Widget> tabs,
    bool isScrollable = false,
    Color? indicatorColor,
    Color? labelColor,
    Color? unselectedLabelColor,
  });

  /// Creates a tab bar view
  Widget tabBarView({
    Key? key,
    required TabController controller,
    required List<Widget> children,
  });

  /// Creates an expansion tile
  Widget expansionTile({
    Key? key,
    required Widget title,
    required List<Widget> children,
    Widget? leading,
    Widget? trailing,
    Color? backgroundColor,
    Color? collapsedBackgroundColor,
  });

  /// Creates a progress indicator (linear)
  Widget linearProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? minHeight,
  });

  /// Creates a progress indicator (circular)
  Widget circularProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? strokeWidth,
  });

  /// Creates a stepper
  Widget stepper({
    Key? key,
    required int currentStep,
    required List<Step> steps,
    required ValueChanged<int> onStepTapped,
    VoidCallback? onStepContinue,
    VoidCallback? onStepCancel,
  });

  /// Creates a segmented control (for selecting between options)
  Widget segmentedControl<T extends Object>({
    Key? key,
    required Map<T, Widget> children,
    required T? groupValue,
    required ValueChanged<T> onValueChanged,
    Color? thumbColor,
    Color? backgroundColor,
  });

  /// Creates a toggle buttons widget
  Widget toggleButtons({
    Key? key,
    required List<Widget> children,
    required List<bool> isSelected,
    required void Function(int) onPressed,
    Color? color,
    Color? selectedColor,
    Color? fillColor,
  });

  /// Creates a tooltip
  Widget tooltip({
    Key? key,
    required String message,
    required Widget child,
    double? height,
    EdgeInsets? padding,
    Duration? waitDuration,
  });

  /// Creates a badge
  Widget badge({
    Key? key,
    required Widget child,
    Widget? label,
    Color? backgroundColor,
    Color? textColor,
    bool isLabelVisible = true,
  });

  /// Creates a snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
  });

  // Navigation and Layout Helpers

  /// Creates a navigation rail for tablet/desktop layouts
  Widget navigationRail({
    required int currentIndex,
    required List<AppRoute> routes,
    required ValueChanged<int> onDestinationSelected,
    required bool showLabels,
  });

  /// Creates a drawer button for mobile navigation
  Widget? drawerButton(BuildContext context);

  /// Returns whether this UI system needs a manual drawer button
  bool shouldAddDrawerButton();

  /// Returns whether this UI system needs desktop padding
  bool needsDesktopPadding();

  /// Returns whether app bar title should be centered
  bool appBarCenterTitle();

  /// Creates a page title widget that adapts to platform conventions
  /// In Cupertino, returns SizedBox.shrink() since iOS uses navigation bar titles
  /// In Material/ForUI, renders as a prominent page header
  Widget pageTitle(String title);

  /// Creates a sliver scaffold with large title support
  /// Automatically handles iOS large title behavior with CustomScrollView
  /// For other platforms, uses standard scaffold with sliver app bar
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
  });

  /// Creates a popup menu button with platform-appropriate styling
  Widget popupMenuButton<T>({
    Key? key,
    required List<AdaptivePopupMenuItem<T>> items,
    required ValueChanged<T> onSelected,
    Widget? icon,
    Widget? child,
    String? tooltip,
    EdgeInsets? padding,
  });

  /// Creates a gesture wrapper with proper platform feedback
  /// Prevents "No Material widget found" errors by wrapping appropriately
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
  });

  // Enhanced Dialog Methods

  /// Shows a form dialog with custom width and layout support
  /// Used for complex forms with multiple inputs, switches, etc.
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
  });

  /// Shows a page-style modal that adapts to screen size
  /// Full-screen on mobile, centered dialog on desktop
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
  });

  /// Shows an action sheet with multiple options
  /// Bottom sheet on mobile, context menu on desktop
  Future<T?> showActionSheet<T>({
    required BuildContext context,
    required List<AdaptiveActionSheetItem<T>> actions,
    Widget? title,
    Widget? message,
    bool showCancelButton = true,
    String? cancelButtonText,
  });

  /// Shows a confirmation dialog with platform-appropriate styling
  Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
  });

  // Enhanced Dialog Utilities

  /// Safely dismiss a dialog if one is showing
  void dismissDialog(BuildContext context);

  /// Check if a dialog is currently showing
  bool hasDialog(BuildContext context);

  /// Dismiss dialog only if one is showing (no-op if not)
  void dismissDialogIfShowing(BuildContext context);

  /// Show a loading dialog with optional message updates
  LoadingDialogController showLoadingDialog({
    required BuildContext context,
    String? message,
    bool dismissible = false,
  });

  /// Show a progress dialog with step tracking
  ProgressDialogController showProgressDialog({
    required BuildContext context,
    String? title,
    String? initialMessage,
    int totalSteps = 1,
    bool dismissible = false,
  });
}
