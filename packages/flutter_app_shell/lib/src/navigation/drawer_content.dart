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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          ...routes
              .where((route) => route.showInNavigation)
              .map((route) => _buildCollapsedItem(context, route)),
          if (actions.isNotEmpty) ...[
            const Divider(),
            ...actions.map((action) => _buildCollapsedAction(context, action)),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
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
                  action.onPressed();
                  onItemTap?.call();
                },
              )),
        ],
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
          action.onPressed();
          onItemTap?.call();
        },
        icon: Icon(action.icon),
      ),
    );
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
