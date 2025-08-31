import 'dart:async';
import 'package:app_shell/src/signal_stores/app_settings.dart';
import 'package:app_shell/src/utilities/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:app_shell/src/services/navigation_service.dart';
import 'package:app_shell/src/services/setup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

// Export the logger
export 'src/utilities/logger.dart';
export 'src/services/navigation_service.dart';
export 'src/services/setup.dart';
export 'src/mobx_stores/app_shell_settings_store.dart';

// Conditional import for desktop
import 'app_shell_desktop.dart' if (dart.library.html) 'app_shell_web.dart'
    as platform;

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
  final ThemeData Function(ThemeData)? themeExtensions; // Add this

  AppConfig({
    required this.routes,
    required this.title,
    this.hideDrawer = false,
    this.actions = const [],
    this.themeExtensions, // Add this
  });
}

// Simplified AppShell that uses theme colors directly
class AppShell extends StatelessWidget {
  final Widget child;
  final List<AppRoute> routes;
  final String title;
  final bool hideDrawer;
  final List<AppShellAction> actions;
  final String? currentRouteTitle;

  const AppShell({
    super.key,
    required this.child,
    required this.routes,
    required this.title,
    this.hideDrawer = false,
    this.actions = const [],
    this.currentRouteTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          leading: isWideScreen || hideDrawer
              ? null
              : Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu, size: 20),
                  ),
                ),
          title: Text(title), // App title on the left
          centerTitle: false, // Ensure app title stays left
          actions: [
            ...actions.map((action) => ActionButton(action: action)),
            const DarkModeToggleButton(),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              height: 1.0,
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          // Add a centered route title
          flexibleSpace: currentRouteTitle != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 15),
                    child: Text(
                      currentRouteTitle!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : null,
        ),
        drawer: (!isWideScreen && !hideDrawer)
            ? Drawer(
                child: DrawerContent(
                  routes: routes,
                  actions:
                      actions.where((action) => action.showInDrawer).toList(),
                  onItemTap: () => Navigator.pop(context),
                ),
              )
            : null,
        body: Row(
          children: [
            if (isWideScreen && !hideDrawer) ...[
              SizedBox(
                width: 150,
                child: DrawerContent(
                  routes: routes,
                  actions:
                      actions.where((action) => action.showInDrawer).toList(),
                ),
              ),
              Container(
                width: 1.0,
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ],
            Expanded(child: child),
          ],
        ),
      ),
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
    return ListTile(
      leading: Icon(route.icon),
      title: Text(
        route.title,
        textAlign: TextAlign.left,
      ),
      onTap: () {
        context.go(route.path);
        onTap?.call();
      },
    );
  }
}

class DarkModeToggleButton extends StatelessWidget {
  const DarkModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();

    return Watch(
      (context) {
        final isDarkMode = settingsStore.brightness.value == Brightness.dark;

        return IconButton(
          onPressed: () {
            settingsStore
                .setBrightness(isDarkMode ? Brightness.light : Brightness.dark);
          },
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 20,
          ),
        );
      },
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

// First, add the _buildTheme function at the top level of the file
ThemeData _buildTheme(Brightness brightness) {
  final baseColorScheme = brightness == Brightness.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: baseColorScheme.copyWith(
      // Base colors
      surface: brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFFAFAFA),
      surfaceContainer: brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF2F2F2),
      surfaceContainerLow: brightness == Brightness.dark
          ? const Color(0xFF232323)
          : const Color(0xFFF7F7F7),
      surfaceContainerHigh: brightness == Brightness.dark
          ? const Color(0xFF323232)
          : const Color(0xFFECECEC),
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFE6E6E6),
      // Message-specific colors
      secondaryContainer: brightness == Brightness.dark
          ? const Color(0xFF2A2A2A) // User message background
          : const Color(0xFFE6F3FF), // Light blue for user messages
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 14),
      bodyMedium: TextStyle(fontSize: 12),
      titleLarge: TextStyle(fontSize: 18),
      titleMedium: TextStyle(fontSize: 16),
      titleSmall: TextStyle(fontSize: 14),
      labelLarge: TextStyle(fontSize: 14),
      labelMedium: TextStyle(fontSize: 12),
      labelSmall: TextStyle(fontSize: 10),
    ),
    iconTheme: const IconThemeData(size: 21.6),
  );
}

// Then modify runShellApp to use _buildTheme
void runShellApp(Future<AppConfig> Function() initApp) async {
  await initializeApp();
  final appConfig = await initApp();
  final settingsStore = GetIt.instance.get<AppShellSettingsStore>();

  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Find the current route
          final currentRoute = appConfig.routes.firstWhere(
            (route) => route.path == state.uri.path,
            orElse: () => appConfig.routes.first,
          );
          return AppShell(
            routes: appConfig.routes,
            title: appConfig.title,
            currentRouteTitle: currentRoute.title, // Now using currentRoute
            hideDrawer: appConfig.hideDrawer,
            actions: appConfig.actions,
            child: child,
          );
        },
        routes: appConfig.routes
            .map((route) => GoRoute(
                  path: route.path,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: route.builder(context, state),
                  ),
                ))
            .toList(),
      ),
    ],
  );
  setupNavigation(router);

  runApp(
    Watch(
      (context) {
        ThemeData theme = _buildTheme(Brightness.light);
        ThemeData darkTheme = _buildTheme(Brightness.dark);

        // Apply any theme extensions from the app
        if (appConfig.themeExtensions != null) {
          logger.i('Applying theme extensions');
          theme = appConfig.themeExtensions!(theme);
          darkTheme = appConfig.themeExtensions!(darkTheme);
        }

        logger.i('Theme: $theme');

        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          title: appConfig.title,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: settingsStore.brightness.value == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      },
    ),
  );
}
