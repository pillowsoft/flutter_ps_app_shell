import 'package:flutter/material.dart';
import '../../core/app_shell_action.dart';

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
        onPressed: action.onPressed,
        icon: Icon(
          action.icon,
          size: 20,
        ),
      ),
    );
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
        onPressed: () {
          setState(() {
            isToggled = !isToggled;
          });
          widget.action.onToggle?.call(isToggled);
          widget.action.onPressed();
        },
        icon: Icon(currentIcon),
      ),
    );
  }
}
