import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_route.dart';
import '../core/app_shell_action.dart';
import '../ui/adaptive/adaptive_widgets.dart';

class DrawerContent extends StatelessWidget {
  final List<AppRoute> routes;
  final List<AppShellAction> actions;
  final VoidCallback? onItemTap;
  final bool collapsed;

  const DrawerContent({
    super.key,
    required this.routes,
    this.actions = const [],
    this.onItemTap,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            ...routes
                .where((route) => route.showInNavigation)
                .map((route) => _buildCollapsedItem(context, route)),
            if (actions.isNotEmpty) ...[
              const Divider(),
              ...actions
                  .map((action) => _buildCollapsedAction(context, action)),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...routes
                .where((route) => route.showInNavigation)
                .map((route) => DrawerItem(route: route, onTap: onItemTap)),
            if (actions.isNotEmpty) const Divider(),
            ...actions.map((action) => DrawerItem(
                  route: AppRoute(
                    title: action.tooltip,
                    path: '',
                    icon: action.icon,
                    builder: (_, __) => const SizedBox(),
                  ),
                  onTap: () {
                    _handleActionPress(context, action);
                    onItemTap?.call();
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedItem(BuildContext context, AppRoute route) {
    return Tooltip(
      message: route.title,
      child: GestureDetector(
        onTap: () {
          context.go(route.path);
          onItemTap?.call();
        },
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          child: Icon(route.icon),
        ),
      ),
    );
  }

  Widget _buildCollapsedAction(BuildContext context, AppShellAction action) {
    final ui = getAdaptiveFactory(context);
    return Tooltip(
      message: action.tooltip,
      child: ui.iconButton(
        onPressed: () {
          _handleActionPress(context, action);
          onItemTap?.call();
        },
        icon: Icon(action.icon),
      ),
    );
  }

  void _handleActionPress(BuildContext context, AppShellAction action) {
    try {
      // Priority: route > onNavigate > onPressed
      if (action.route != null) {
        _handleRouteNavigation(context, action.route!, action);
      } else if (action.onNavigate != null) {
        action.onNavigate!(context);
      } else if (action.onPressed != null) {
        action.onPressed!();
      }
    } catch (e) {
      // Fallback: just log the error and continue
      debugPrint(
          'DrawerContent: Error handling action press for ${action.tooltip}: $e');
    }
  }

  void _handleRouteNavigation(
      BuildContext context, String route, AppShellAction action) {
    try {
      final router = GoRouter.of(context);
      if (action.useReplace) {
        router.replace(route);
      } else {
        router.go(route);
      }
    } catch (e) {
      debugPrint('DrawerContent: Error navigating to route $route: $e');
      // Fallback: try using Navigator if GoRouter fails
      try {
        Navigator.of(context).pushNamed(route);
      } catch (fallbackError) {
        debugPrint(
            'DrawerContent: Fallback navigation also failed for $route: $fallbackError');
      }
    }
  }
}

class DrawerItem extends StatelessWidget {
  final AppRoute route;
  final VoidCallback? onTap;

  const DrawerItem({super.key, required this.route, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ui.listTile(
      leading: Icon(route.icon),
      title: Text(
        route.title,
        textAlign: TextAlign.left,
      ),
      onTap: () {
        if (route.path.isNotEmpty) {
          context.go(route.path);
        }
        onTap?.call();
      },
    );
  }
}
