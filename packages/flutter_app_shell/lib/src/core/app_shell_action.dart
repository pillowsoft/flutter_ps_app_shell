import 'package:flutter/material.dart';

class AppShellAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool showInDrawer;
  final bool isToggleable;
  final bool? initialValue;
  final void Function(bool)? onToggle;
  final IconData? toggledIcon;
  final String? toggledTooltip;
  final Widget? customWidget;

  // New navigation properties
  final String? route;
  final void Function(BuildContext)? onNavigate;
  final bool useReplace;

  const AppShellAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.showInDrawer = false,
    this.isToggleable = false,
    this.initialValue,
    this.onToggle,
    this.toggledIcon,
    this.toggledTooltip,
    this.customWidget,
    this.route,
    this.onNavigate,
    this.useReplace = false,
  })  : assert(
            !isToggleable ||
                (isToggleable && onToggle != null && initialValue != null),
            'Toggle actions must provide onToggle and initialValue'),
        assert(onPressed != null || route != null || onNavigate != null,
            'AppShellAction must provide one of: onPressed, route, or onNavigate'),
        assert(!(route != null && onNavigate != null),
            'Cannot specify both route and onNavigate - use one or the other');

  /// Factory constructor for simple navigation to a route
  factory AppShellAction.route({
    required IconData icon,
    required String tooltip,
    required String route,
    bool showInDrawer = false,
    bool useReplace = false,
    Widget? customWidget,
  }) {
    return AppShellAction(
      icon: icon,
      tooltip: tooltip,
      route: route,
      showInDrawer: showInDrawer,
      useReplace: useReplace,
      customWidget: customWidget,
    );
  }

  /// Factory constructor for context-aware navigation
  factory AppShellAction.navigate({
    required IconData icon,
    required String tooltip,
    required void Function(BuildContext) onNavigate,
    bool showInDrawer = false,
    Widget? customWidget,
  }) {
    return AppShellAction(
      icon: icon,
      tooltip: tooltip,
      onNavigate: onNavigate,
      showInDrawer: showInDrawer,
      customWidget: customWidget,
    );
  }

  /// Factory constructor for traditional callback actions (backward compatibility)
  factory AppShellAction.callback({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool showInDrawer = false,
    Widget? customWidget,
  }) {
    return AppShellAction(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      showInDrawer: showInDrawer,
      customWidget: customWidget,
    );
  }

  /// Check if this action has navigation capability
  bool get hasNavigation => route != null || onNavigate != null;

  /// Check if this action has a traditional callback
  bool get hasCallback => onPressed != null;
}
