import 'package:flutter/material.dart';

class AppShellAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool showInDrawer;
  final bool isToggleable;
  final bool? initialValue;
  final void Function(bool)? onToggle;
  final IconData? toggledIcon;
  final String? toggledTooltip;
  final Widget? customWidget;

  const AppShellAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.showInDrawer = false,
    this.isToggleable = false,
    this.initialValue,
    this.onToggle,
    this.toggledIcon,
    this.toggledTooltip,
    this.customWidget,
  }) : assert(
            !isToggleable ||
                (isToggleable && onToggle != null && initialValue != null),
            'Toggle actions must provide onToggle and initialValue');
}
