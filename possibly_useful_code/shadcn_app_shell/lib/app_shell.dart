import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:shadcn_app_shell/src/mobx_stores/settings_store.dart';
import 'package:shadcn_app_shell/src/services/navigation_service.dart';
import 'package:shadcn_app_shell/src/services/setup.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';

// Export the logger
export 'src/utilities/logger.dart';
export 'src/services/navigation_service.dart';
export 'src/services/setup.dart';

// Conditional import for desktop
import 'app_shell_desktop.dart' if (dart.library.html) 'app_shell_web.dart'
    as platform;

// First, let's modify the AppShellAction class to support toggle state
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
  }) : assert(
            !isToggleable ||
                (isToggleable && onToggle != null && initialValue != null),
            'Toggle actions must provide onToggle and initialValue');
}

// Create a new ToggleActionButton widget
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
      tooltip: TooltipContainer(
        child: Text(currentTooltip),
      ),
      child: GhostButton(
        density: ButtonDensity.icon,
        onPressed: () {
          setState(() {
            isToggled = !isToggled;
          });
          widget.action.onToggle?.call(isToggled);
          widget.action.onPressed();
        },
        child: Icon(currentIcon),
      ),
    );
  }
}

// Update the ActionButton to handle both regular and toggle buttons
class ActionButton extends StatelessWidget {
  final AppShellAction action;

  const ActionButton({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    if (action.isToggleable) {
      return ToggleActionButton(action: action);
    }

    return Tooltip(
      tooltip: TooltipContainer(
        child: Text(action.tooltip),
      ),
      child: GhostButton(
        density: ButtonDensity.icon,
        onPressed: action.onPressed,
        child: Icon(action.icon),
      ),
    );
  }
}

class AppRoute {
  final String title;
  final String path;
  final IconData icon;
  final Widget Function(BuildContext, GoRouterState) builder;
  final List<AppRoute> subRoutes;

  AppRoute({
    required this.title,
    required this.path,
    required this.icon,
    required this.builder,
    this.subRoutes = const [],
  });
}

class AppConfig {
  final List<AppRoute> routes;
  final String title;
  final bool hideDrawer;
  final List<AppShellAction> actions;

  AppConfig({
    required this.routes,
    required this.title,
    this.hideDrawer = false,
    this.actions = const [],
  });
}

class AppShell extends StatelessWidget {
  final Widget child;
  final List<AppRoute> routes;
  final String title;
  final bool hideDrawer;
  final List<AppShellAction> actions;

  const AppShell({
    super.key,
    required this.child,
    required this.routes,
    required this.title,
    this.hideDrawer = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final settingsStore = GetIt.instance.get<SettingsStore>();
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        headers: [
          AppBar(
            title: Text(title),
            leading: isWideScreen || hideDrawer
                ? []
                : [
                    GhostButton(
                      onPressed: () => _openDrawer(context),
                      density: ButtonDensity.icon,
                      child: const Icon(Icons.menu),
                    ),
                  ],
            trailing: [
              ...actions.map((action) => ActionButton(action: action)),
              Observer(
                builder: (_) => DarkModeToggle(
                  brightness: settingsStore.brightness,
                  onToggle: (brightness) =>
                      settingsStore.setBrightness(brightness),
                ),
              ),
            ],
          ),
          const Divider(),
        ],
        child: Row(
          children: [
            if (isWideScreen && !hideDrawer)
              Container(
                width: 200,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: DrawerContent(
                  routes: routes,
                  actions:
                      actions.where((action) => action.showInDrawer).toList(),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    if (hideDrawer) return;

    final theme = Theme.of(context);

    openDrawer(
      context: context,
      builder: (context) {
        return Container(
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(
            maxWidth: 180,
          ),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: DrawerContent(
            routes: routes,
            actions: actions.where((action) => action.showInDrawer).toList(),
            onItemTap: () {
              if (MediaQuery.of(context).size.width <= 600) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      },
      position: OverlayPosition.left,
    );
  }
}

class DrawerContent extends StatelessWidget {
  final List<AppRoute> routes;
  final List<AppShellAction> actions;
  final VoidCallback? onItemTap;

  const DrawerContent({
    super.key,
    required this.routes,
    this.actions = const [],
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...routes.map((route) => DrawerItem(route: route, onTap: onItemTap)),
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
    );
  }
}

class DrawerItem extends StatelessWidget {
  final AppRoute route;
  final VoidCallback? onTap;

  const DrawerItem({super.key, required this.route, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GhostButton(
      onPressed: () {
        context.go(route.path);
        onTap?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(route.icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                route.title,
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DarkModeToggle extends StatelessWidget {
  final Brightness brightness;
  final void Function(Brightness) onToggle;

  const DarkModeToggle({
    super.key,
    required this.brightness,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = brightness == Brightness.dark;
    return GhostButton(
      density: ButtonDensity.icon,
      onPressed: () {
        onToggle(isDarkMode ? Brightness.light : Brightness.dark);
      },
      child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
    );
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  if (!kIsWeb) {
    await platform.initializeDesktopApp();
  }
}

void runShellApp(Future<AppConfig> Function() initApp) async {
  await initializeApp();

  final appConfig = await initApp();
  final settingsStore = GetIt.instance.get<SettingsStore>();

  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          routes: appConfig.routes,
          title: appConfig.title,
          hideDrawer: appConfig.hideDrawer,
          actions: appConfig.actions,
          child: child,
        ),
        routes: appConfig.routes
            .map((route) => GoRoute(
                  path: route.path,
                  builder: route.builder,
                ))
            .toList(),
      ),
    ],
  );
  setupNavigation(router);

  runApp(
    Observer(
      builder: (_) => ShadcnApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: appConfig.title,
        scaling: const AdaptiveScaling(1.0),
        theme: ThemeData(
          colorScheme: (settingsStore.brightness == Brightness.dark)
              ? ColorSchemes.darkZinc()
              : ColorSchemes.lightZinc(),
          radius: 0.7,
        ),
      ),
    ),
  );
}
