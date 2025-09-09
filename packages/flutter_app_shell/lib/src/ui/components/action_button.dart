import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_shell_action.dart';
import '../../utils/logger.dart';

class ActionButton extends StatelessWidget {
  final AppShellAction action;

  const ActionButton({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    // If a custom widget is provided, use it instead of the default button
    if (action.customWidget != null) {
      return action.customWidget!;
    }

    if (action.isToggleable) {
      return ToggleActionButton(action: action);
    }

    return Tooltip(
      message: action.tooltip,
      child: IconButton(
        onPressed: () => _handlePress(context),
        icon: Icon(
          action.icon,
          size: 20,
        ),
      ),
    );
  }

  void _handlePress(BuildContext context) {
    try {
      // Priority: route > onNavigate > onPressed
      if (action.route != null) {
        _handleRouteNavigation(context, action.route!);
      } else if (action.onNavigate != null) {
        AppShellLogger.i(
            'ActionButton: Executing context-aware navigation for ${action.tooltip}');
        action.onNavigate!(context);
      } else if (action.onPressed != null) {
        AppShellLogger.i(
            'ActionButton: Executing callback for ${action.tooltip}');
        action.onPressed!();
      } else {
        AppShellLogger.w(
            'ActionButton: No action defined for ${action.tooltip}');
      }
    } catch (e, stackTrace) {
      AppShellLogger.e(
          'ActionButton: Error handling press for ${action.tooltip}',
          e,
          stackTrace);
      // Don't rethrow - just log and continue
    }
  }

  void _handleRouteNavigation(BuildContext context, String route) {
    try {
      final router = GoRouter.of(context);
      if (action.useReplace) {
        AppShellLogger.i('ActionButton: Replacing route to $route');
        router.replace(route);
      } else {
        AppShellLogger.i('ActionButton: Navigating to route $route');
        router.go(route);
      }
    } catch (e, stackTrace) {
      AppShellLogger.e(
          'ActionButton: Error navigating to route $route', e, stackTrace);
      // Fallback: try using Navigator if GoRouter fails
      try {
        Navigator.of(context).pushNamed(route);
      } catch (fallbackError) {
        AppShellLogger.e(
            'ActionButton: Fallback navigation also failed for $route',
            fallbackError);
      }
    }
  }
}

class ToggleActionButton extends StatefulWidget {
  final AppShellAction action;

  const ToggleActionButton({
    super.key,
    required this.action,
  });

  @override
  State<ToggleActionButton> createState() => _ToggleActionButtonState();
}

class _ToggleActionButtonState extends State<ToggleActionButton> {
  late bool isToggled;

  @override
  void initState() {
    super.initState();
    isToggled = widget.action.initialValue!;
  }

  @override
  Widget build(BuildContext context) {
    final currentIcon = isToggled
        ? (widget.action.toggledIcon ?? widget.action.icon)
        : widget.action.icon;
    final currentTooltip = isToggled
        ? (widget.action.toggledTooltip ?? widget.action.tooltip)
        : widget.action.tooltip;

    return Tooltip(
      message: currentTooltip,
      child: IconButton(
        onPressed: () => _handleTogglePress(context),
        icon: Icon(currentIcon),
      ),
    );
  }

  void _handleTogglePress(BuildContext context) {
    try {
      setState(() {
        isToggled = !isToggled;
      });
      widget.action.onToggle?.call(isToggled);

      // Handle navigation or callback
      if (widget.action.route != null) {
        _handleRouteNavigation(context, widget.action.route!);
      } else if (widget.action.onNavigate != null) {
        AppShellLogger.i(
            'ToggleActionButton: Executing context-aware navigation for ${widget.action.tooltip}');
        widget.action.onNavigate!(context);
      } else if (widget.action.onPressed != null) {
        AppShellLogger.i(
            'ToggleActionButton: Executing callback for ${widget.action.tooltip}');
        widget.action.onPressed!();
      }
    } catch (e, stackTrace) {
      AppShellLogger.e(
          'ToggleActionButton: Error handling toggle press for ${widget.action.tooltip}',
          e,
          stackTrace);
    }
  }

  void _handleRouteNavigation(BuildContext context, String route) {
    try {
      final router = GoRouter.of(context);
      if (widget.action.useReplace) {
        AppShellLogger.i('ToggleActionButton: Replacing route to $route');
        router.replace(route);
      } else {
        AppShellLogger.i('ToggleActionButton: Navigating to route $route');
        router.go(route);
      }
    } catch (e, stackTrace) {
      AppShellLogger.e('ToggleActionButton: Error navigating to route $route',
          e, stackTrace);
      // Fallback: try using Navigator if GoRouter fails
      try {
        Navigator.of(context).pushNamed(route);
      } catch (fallbackError) {
        AppShellLogger.e(
            'ToggleActionButton: Fallback navigation also failed for $route',
            fallbackError);
      }
    }
  }
}
