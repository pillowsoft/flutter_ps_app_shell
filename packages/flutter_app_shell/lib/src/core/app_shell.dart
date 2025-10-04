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
import '../ui/adaptive/cupertino_widget_factory.dart';
import '../utils/logger.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final List<AppRoute> routes;
  final String title;
  final bool hideNavigation;
  final List<AppShellAction> actions;
  final String? currentRouteTitle;
  final bool showThemeToggle;
  final String? homeRoute;

  const AppShell({
    super.key,
    required this.child,
    required this.routes,
    required this.title,
    this.hideNavigation = false,
    this.actions = const [],
    this.currentRouteTitle,
    this.showThemeToggle = true,
    this.homeRoute,
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
      final drawer = useMobileDrawer && !hideNavigation
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
      final bottomNavBar =
          useBottomNav && !hideNavigation && visibleRoutes.isNotEmpty
              ? _buildBottomNavigation(context, ui, visibleRoutes)
              : null;

      // Debug logging for UI factory inputs
      AppShellLogger.i(
          'AppShell scaffold inputs: drawer=${drawer != null ? "present" : "null"}, '
          'bottomNavBar=${bottomNavBar != null ? "present" : "null"}, '
          'uiSystem=${settingsStore.uiSystem.value}');

      final scaffoldContent = ui.scaffold(
        appBar: _buildAppBar(context, isWideScreen, useMobileDrawer,
            useBottomNav: useBottomNav, visibleRoutes: visibleRoutes),
        drawer: drawer,
        bottomNavBar: bottomNavBar,
        body: Row(
          children: [
            if (useSidebar && !hideNavigation && visibleRoutes.isNotEmpty) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sidebarCollapsed ? 72 : 250,
                child: _buildSidebar(context, sidebarCollapsed),
              ),
              Container(
                width: 1.0,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ] else if (useRail &&
                !hideNavigation &&
                visibleRoutes.isNotEmpty) ...[
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
        // Cupertino handles safe areas via CupertinoPageScaffold + Container wrapper
        // Material/ForUI need explicit SafeArea
        if (ui is CupertinoWidgetFactory) {
          return scaffoldContent;
        } else {
          return SafeArea(child: scaffoldContent);
        }
      }
    });
  }

  Widget _buildAppBar(
      BuildContext context, bool isWideScreen, bool useMobileDrawer,
      {bool? useBottomNav, required List<AppRoute> visibleRoutes}) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();
    final ui = getAdaptiveFactory(context);
    final actions = <Widget>[
      ...this.actions.map((action) => ActionButton(action: action)),
      if (showThemeToggle) const DarkModeToggleButton(),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    AppShellLogger.i(
        'AppShell._buildAppBar: screenWidth=$screenWidth, isWideScreen=$isWideScreen, useMobileDrawer=$useMobileDrawer, useBottomNav=$useBottomNav, hideNavigation=$hideNavigation');

    // EXTRACT BACK NAVIGATION LOGIC - Independent of navigation mode
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final routerState = GoRouterState.of(context);
    final currentPath = routerState.uri.path;
    final pathSegments =
        currentPath.split('/').where((s) => s.isNotEmpty).toList();
    final isNestedRoute = pathSegments.length > 1;

    // Special case: When navigation is hidden (programmatic navigation mode),
    // show back button on all non-home routes to prevent users getting stuck
    // Note: On initial app launch, currentPath may be empty string before GoRouter initializes
    // Home page can be configured via AppConfig.homeRoute, defaults to '/'
    final configuredHomePath = homeRoute ?? '/';
    final isHomePage = currentPath == configuredHomePath ||
                       currentPath == '/' ||
                       currentPath.isEmpty;
    final needsBackForHiddenNav = visibleRoutes.isEmpty && !isHomePage;

    // Never show back button on home page, even if canPop is true
    final shouldShowBackButton =
        !isHomePage && (canPop || isNestedRoute || needsBackForHiddenNav);

    AppShellLogger.i(
        'AppShell._buildAppBar: Navigation state - canPop=$canPop, currentPath="$currentPath", pathSegments=$pathSegments, isNestedRoute=$isNestedRoute, shouldShowBackButton=$shouldShowBackButton');

    // Determine the leading widget and automaticallyImplyLeading behavior
    final Widget? leading;
    final bool automaticallyImplyLeading;

    // UNIVERSAL BACK NAVIGATION - Works for all navigation modes
    if (shouldShowBackButton) {
      AppShellLogger.i(
          'AppShell._buildAppBar: Using back button - canPop=$canPop, isNestedRoute=$isNestedRoute');

      // Create explicit back button handler
      void handleBackNavigation() {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          // Fallback: navigate back to parent route or home
          if (pathSegments.length > 1) {
            final parentPathSegments = List<String>.from(pathSegments);
            parentPathSegments.removeLast();
            final parentPath = '/${parentPathSegments.join('/')}';
            AppShellLogger.i(
                'AppShell._buildAppBar: Fallback navigation to parent: $parentPath');
            GoRouter.of(context).go(parentPath);
          } else if (visibleRoutes.isEmpty) {
            // Hidden navigation mode: navigate to home page
            AppShellLogger.i(
                'AppShell._buildAppBar: Hidden navigation mode - navigating to home');
            GoRouter.of(context).go('/');
          }
        }
      }

      // When navigation is hidden, always use explicit back button with custom handler
      // Otherwise, behavior depends on UI system
      if (visibleRoutes.isEmpty ||
          ui.runtimeType.toString() == 'CupertinoWidgetFactory') {
        // Explicit back button for hidden navigation or Cupertino
        final icon = ui.runtimeType.toString() == 'CupertinoWidgetFactory'
            ? const Icon(Icons.arrow_back_ios)
            : const Icon(Icons.arrow_back);
        leading = ui.iconButton(
          icon: icon,
          onPressed: handleBackNavigation,
        );
        automaticallyImplyLeading = false;
        AppShellLogger.i(
            'AppShell._buildAppBar: Using explicit back button (${ui.runtimeType}, hiddenNav=${visibleRoutes.isEmpty})');
      } else {
        // Material and ForUI can use automatic back button when navigation is visible
        leading = null;
        automaticallyImplyLeading = true;
        AppShellLogger.i(
            'AppShell._buildAppBar: Using automatic ${ui.runtimeType} back button');
      }
    } else if (useMobileDrawer &&
        !hideNavigation &&
        ui.shouldAddDrawerButton()) {
      // Mobile drawer mode without back navigation - show drawer button
      AppShellLogger.i(
          'AppShell._buildAppBar: Mobile drawer mode - using custom drawer button (${ui.runtimeType})');
      leading = ui.drawerButton(context);
      automaticallyImplyLeading = false;
    } else if (useMobileDrawer && !hideNavigation) {
      // Mobile drawer mode - Material/ForUI handle drawer automatically
      AppShellLogger.i(
          'AppShell._buildAppBar: Mobile drawer mode - using framework drawer button (${ui.runtimeType})');
      leading = null;
      automaticallyImplyLeading = true;
    } else if (screenWidth > 1200 && !hideNavigation) {
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
      // Never auto-imply leading on home page, even if canPop() returns true
      // This prevents back button from appearing on fresh app launch when GoRouter
      // might have internal navigation state that makes canPop() return true
      automaticallyImplyLeading = !isHomePage;
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
  /// Recursively searches through route tree including sub-routes
  String? _getCurrentRouteTitle(BuildContext context) {
    try {
      final currentPath = GoRouterState.of(context).uri.path;
      AppShellLogger.i(
          'AppShell._getCurrentRouteTitle: analyzing path="$currentPath"');

      // Recursive helper to search route tree
      String? findRouteTitle(
          List<AppRoute> routeList, String targetPath, String parentPath) {
        for (final route in routeList) {
          // Build full path for this route
          final fullPath = route.path.startsWith('/')
              ? route.path
              : '$parentPath/${route.path}';

          // Check for exact match (handling path parameters)
          if (_pathMatches(fullPath, targetPath)) {
            AppShellLogger.i(
                'AppShell._getCurrentRouteTitle: matched route $fullPath -> "${route.title}"');
            return route.title;
          }

          // Check sub-routes if path is under this route
          if (route.subRoutes.isNotEmpty &&
              targetPath.startsWith('$fullPath/')) {
            final subRouteTitle =
                findRouteTitle(route.subRoutes, targetPath, fullPath);
            if (subRouteTitle != null) {
              return subRouteTitle;
            }
            // If sub-route search failed but we're under this route, return parent title
            AppShellLogger.i(
                'AppShell._getCurrentRouteTitle: using parent title for $fullPath -> "${route.title}"');
            return route.title;
          }
        }
        return null;
      }

      return findRouteTitle(routes, currentPath, '');
    } catch (e) {
      AppShellLogger.e('AppShell._getCurrentRouteTitle: error=$e');
      return null;
    }
  }

  /// Helper to match paths with parameters like /detail/:level with /detail/1
  bool _pathMatches(String routePath, String actualPath) {
    final routeSegments =
        routePath.split('/').where((s) => s.isNotEmpty).toList();
    final actualSegments =
        actualPath.split('/').where((s) => s.isNotEmpty).toList();

    if (routeSegments.length != actualSegments.length) return false;

    for (int i = 0; i < routeSegments.length; i++) {
      if (routeSegments[i].startsWith(':')) continue; // Path parameter
      if (routeSegments[i] != actualSegments[i]) return false;
    }

    return true;
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
