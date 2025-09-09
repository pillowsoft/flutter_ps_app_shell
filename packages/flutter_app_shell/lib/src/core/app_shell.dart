import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'app_route.dart';
import 'app_shell_action.dart';
import '../state/app_shell_settings_store.dart';
import '../navigation/drawer_content.dart';
import '../ui/components/action_button.dart';
import '../ui/components/dark_mode_toggle_button.dart';
import '../ui/adaptive/adaptive_widgets.dart';
import '../ui/adaptive/adaptive_widget_factory.dart';
import '../utils/logger.dart';

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
    final settingsStore = GetIt.I<AppShellSettingsStore>();

    return Watch((context) {
      final ui = getAdaptiveFactory(context);
      final isWideScreen = MediaQuery.of(context).size.width > 600;
      final isVeryWideScreen = MediaQuery.of(context).size.width > 1200;
      final sidebarCollapsed = settingsStore.sidebarCollapsed.value;

      // Determine navigation style based on screen size and visible route count
      final visibleRoutes =
          routes.where((route) => route.showInNavigation).toList();
      final useBottomNav = !isWideScreen && visibleRoutes.length <= 5;
      final useMobileDrawer = !isWideScreen && visibleRoutes.length > 5;
      final useRail = isWideScreen && !isVeryWideScreen;
      final useSidebar = isVeryWideScreen;

      // Debug logging to help troubleshoot navigation issues
      final screenWidth = MediaQuery.of(context).size.width;
      AppShellLogger.i(
          'AppShell navigation logic: screenWidth=${screenWidth.toInt()}px, '
          'isWideScreen=$isWideScreen, visibleRoutes=${visibleRoutes.length}, '
          'useBottomNav=$useBottomNav, useMobileDrawer=$useMobileDrawer, '
          'useRail=$useRail, useSidebar=$useSidebar');

      final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux;

      // Use factory methods to determine platform-specific behavior
      final needsDesktopPadding = isDesktop && ui.needsDesktopPadding();

      // Build the drawer for mobile navigation when needed
      final drawer = useMobileDrawer && !hideDrawer
          ? Drawer(
              child: Builder(
                builder: (drawerContext) => DrawerContent(
                  routes: routes,
                  actions:
                      actions.where((action) => action.showInDrawer).toList(),
                  collapsed: false,
                  onItemTap: () {
                    // Close the drawer after navigation
                    Navigator.of(drawerContext).pop();
                  },
                ),
              ),
            )
          : null;

      // Create bottom navigation if needed
      final bottomNavBar = useBottomNav && !hideDrawer
          ? _buildBottomNavigation(context, ui, visibleRoutes)
          : null;

      // Debug logging for UI factory inputs
      AppShellLogger.i(
          'AppShell scaffold inputs: drawer=${drawer != null ? "present" : "null"}, '
          'bottomNavBar=${bottomNavBar != null ? "present" : "null"}, '
          'uiSystem=${settingsStore.uiSystem.value}');

      final scaffoldContent = ui.scaffold(
        appBar: _buildAppBar(context, isWideScreen, useMobileDrawer,
            useBottomNav: useBottomNav),
        drawer: drawer,
        bottomNavBar: bottomNavBar,
        body: Row(
          children: [
            if (useSidebar && !hideDrawer) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sidebarCollapsed ? 72 : 250,
                child: _buildSidebar(context, sidebarCollapsed),
              ),
              Container(
                width: 1.0,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ] else if (useRail && !hideDrawer) ...[
              _buildNavigationRail(context, ui),
              const VerticalDivider(thickness: 1, width: 1),
            ],
            Expanded(
              child: needsDesktopPadding
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      );

      // Apply SafeArea based on platform and UI system
      if (isDesktop) {
        // On desktop, Cupertino handles its own safe area via CupertinoPageScaffold
        // Material/ForUI don't need SafeArea on desktop
        return scaffoldContent;
      } else {
        // On mobile, all UI systems benefit from SafeArea
        return SafeArea(child: scaffoldContent);
      }
    });
  }

  Widget _buildAppBar(
      BuildContext context, bool isWideScreen, bool useMobileDrawer,
      {bool? useBottomNav}) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();
    final ui = getAdaptiveFactory(context);
    final actions = <Widget>[
      ...this.actions.map((action) => ActionButton(action: action)),
      const DarkModeToggleButton(),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    AppShellLogger.i(
        'AppShell._buildAppBar: screenWidth=$screenWidth, isWideScreen=$isWideScreen, useMobileDrawer=$useMobileDrawer, useBottomNav=$useBottomNav, hideDrawer=$hideDrawer');

    // EXTRACT BACK NAVIGATION LOGIC - Independent of navigation mode
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.path;
    final pathSegments =
        currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final isNestedRoute = pathSegments.length > 1;
    final shouldShowBackButton = canPop || isNestedRoute;

    AppShellLogger.i(
        'AppShell._buildAppBar: Navigation state - canPop=$canPop, currentPath="$currentPath", pathSegments=$pathSegments, isNestedRoute=$isNestedRoute, shouldShowBackButton=$shouldShowBackButton');

    // Determine the leading widget and automaticallyImplyLeading behavior
    final Widget? leading;
    final bool automaticallyImplyLeading;

    // UNIVERSAL BACK NAVIGATION - Works for all navigation modes
    if (shouldShowBackButton) {
      AppShellLogger.i(
          'AppShell._buildAppBar: Using back button - canPop=$canPop, isNestedRoute=$isNestedRoute');

      // For Cupertino, we need to explicitly create a back button when using ShellRoute
      // because automaticallyImplyLeading doesn't work reliably in this context
      if (ui.runtimeType.toString() == 'CupertinoWidgetFactory') {
        leading = ui.iconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              // Fallback: navigate back to parent route
              if (pathSegments.length > 1) {
                final parentPathSegments = List<String>.from(pathSegments);
                parentPathSegments.removeLast();
                final parentPath = '/${parentPathSegments.join('/')}';
                AppShellLogger.i(
                    'AppShell._buildAppBar: Fallback navigation to parent: $parentPath');
                GoRouter.of(context).go(parentPath);
              }
            }
          },
        );
        automaticallyImplyLeading = false;
        AppShellLogger.i(
            'AppShell._buildAppBar: Using explicit Cupertino back button');
      } else {
        // Material and ForUI can use automatic back button
        leading = null;
        automaticallyImplyLeading = true;
        AppShellLogger.i(
            'AppShell._buildAppBar: Using automatic ${ui.runtimeType} back button');
      }
    } else if (useMobileDrawer && !hideDrawer && ui.shouldAddDrawerButton()) {
      // Mobile drawer mode without back navigation - show drawer button
      AppShellLogger.i(
          'AppShell._buildAppBar: Mobile drawer mode - using custom drawer button (${ui.runtimeType})');
      leading = ui.drawerButton(context);
      automaticallyImplyLeading = false;
    } else if (useMobileDrawer && !hideDrawer) {
      // Mobile drawer mode - Material/ForUI handle drawer automatically
      AppShellLogger.i(
          'AppShell._buildAppBar: Mobile drawer mode - using framework drawer button (${ui.runtimeType})');
      leading = null;
      automaticallyImplyLeading = true;
    } else if (screenWidth > 1200 && !hideDrawer) {
      // Desktop sidebar toggle remains unchanged
      AppShellLogger.i('AppShell._buildAppBar: Desktop sidebar toggle mode');
      leading = ui.iconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => settingsStore.toggleSidebar(),
      );
      automaticallyImplyLeading = false;
    } else {
      AppShellLogger.i(
          'AppShell._buildAppBar: Default mode (no custom leading)');
      leading = null;
      automaticallyImplyLeading = true;
    }

    // Determine title - use currentRouteTitle, or try to get from current route, or fallback to app title
    final dynamicTitle = _getCurrentRouteTitle(context);
    final displayTitle = currentRouteTitle ?? dynamicTitle ?? title;
    AppShellLogger.i(
        'AppShell._buildAppBar: currentRouteTitle="$currentRouteTitle", dynamicTitle="$dynamicTitle", displayTitle="$displayTitle"');

    // Use the factory's appBar method with proper settings
    return ui.appBar(
      title: Text(displayTitle),
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  /// Attempts to determine the current route title based on the current path
  String? _getCurrentRouteTitle(BuildContext context) {
    try {
      final currentPath = GoRouterState.of(context).uri.path;
      AppShellLogger.i(
          'AppShell._getCurrentRouteTitle: analyzing path="$currentPath"');

      // Handle navigation demo specific routes
      if (currentPath.startsWith('/navigation/detail/')) {
        final level = currentPath.split('/').last;
        final title = 'Detail Level $level';
        AppShellLogger.i(
            'AppShell._getCurrentRouteTitle: matched detail route -> "$title"');
        return title;
      } else if (currentPath.startsWith('/navigation/nested/')) {
        final level = currentPath.split('/').last;
        final title = 'Deep Navigation Level $level';
        AppShellLogger.i(
            'AppShell._getCurrentRouteTitle: matched nested route -> "$title"');
        return title;
      } else if (currentPath == '/navigation') {
        AppShellLogger.i(
            'AppShell._getCurrentRouteTitle: matched navigation root -> "Navigation Demo"');
        return 'Navigation Demo';
      }

      // Find matching route from the routes list
      final matchingRoute = routes.firstWhere(
        (route) => route.path == currentPath,
        orElse: () => routes.first,
      );

      // Return the route title if we found a match and it's not the fallback
      if (matchingRoute.path == currentPath) {
        AppShellLogger.i(
            'AppShell._getCurrentRouteTitle: matched route ${matchingRoute.path} -> "${matchingRoute.title}"');
        return matchingRoute.title;
      }

      AppShellLogger.i(
          'AppShell._getCurrentRouteTitle: no match found for path="$currentPath"');
      return null;
    } catch (e) {
      // If anything goes wrong, return null to use fallback title
      return null;
    }
  }

  Widget _buildSidebar(BuildContext context, bool collapsed) {
    final sidebar = Container(
      color: Theme.of(context).colorScheme.surface,
      child: DrawerContent(
        routes: routes,
        actions: actions.where((action) => action.showInDrawer).toList(),
        collapsed: collapsed,
      ),
    );

    // Always wrap with Material to ensure Material ancestor is available
    return Material(
      child: sidebar,
    );
  }

  Widget _buildNavigationRail(BuildContext context, AdaptiveWidgetFactory ui) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();
    final currentPath = GoRouterState.of(context).uri.path;

    // Only use visible routes for index calculation to match NavigationRail filtering
    final visibleRoutes =
        routes.where((route) => route.showInNavigation).toList();
    final currentIndex =
        visibleRoutes.indexWhere((route) => route.path == currentPath);

    return Watch((context) {
      final showLabels = settingsStore.showNavigationLabels.value;

      // Use factory method to create platform-specific navigation rail
      return ui.navigationRail(
        currentIndex: currentIndex, // Pass actual index, let factory handle -1
        routes: routes, // Pass all routes, filtering happens in factory
        onDestinationSelected: (index) {
          context.go(visibleRoutes[index].path);
        },
        showLabels: showLabels,
      );
    });
  }

  Widget _buildBottomNavigation(BuildContext context, AdaptiveWidgetFactory ui,
      List<AppRoute> visibleRoutes) {
    final currentPath = GoRouterState.of(context).uri.path;

    // Use pre-calculated visible routes to avoid duplicate filtering
    final currentIndex =
        visibleRoutes.indexWhere((route) => route.path == currentPath);

    // Convert visible routes to AdaptiveNavItems
    final navItems = visibleRoutes
        .map((route) => AdaptiveNavItem(
              icon: route.icon,
              label: route.title,
            ))
        .toList();

    return ui.navBar(
      currentIndex:
          currentIndex >= 0 ? currentIndex : 0, // Default to 0 if not found
      onTap: (index) {
        context.go(visibleRoutes[index].path);
      },
      items: navItems,
    );
  }
}
