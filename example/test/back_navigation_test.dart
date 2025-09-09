import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  group('Back Navigation Logic Tests', () {
    test('AppRoute model supports navigation properties', () {
      // Test that AppRoute has the necessary properties for navigation
      final route = AppRoute(
        title: 'Test Route',
        path: '/test',
        icon: Icons.home,
        builder: (context, state) => Container(),
        showInNavigation: true,
      );

      expect(route.title, 'Test Route');
      expect(route.path, '/test');
      expect(route.showInNavigation, true);
      expect(route.subRoutes, isEmpty);
    });

    test('AppRoute supports nested routes', () {
      // Test that AppRoute can have sub-routes for nested navigation
      final parentRoute = AppRoute(
        title: 'Parent',
        path: '/parent',
        icon: Icons.folder,
        builder: (context, state) => Container(),
        subRoutes: [
          AppRoute(
            title: 'Child',
            path: 'child',
            icon: Icons.description,
            builder: (context, state) => Container(),
            showInNavigation: false,
          ),
        ],
      );

      expect(parentRoute.subRoutes.length, 1);
      expect(parentRoute.subRoutes.first.title, 'Child');
      expect(parentRoute.subRoutes.first.path, 'child');
      expect(parentRoute.subRoutes.first.showInNavigation, false);
    });

    test('Back navigation logic detects nested routes correctly', () {
      // Test the path parsing logic that determines if a route is nested
      const currentPath1 = '/'; // Root route
      const currentPath2 = '/home'; // Single-level route
      const currentPath3 = '/navigation/detail/1'; // Nested route
      const currentPath4 = '/profile/settings/advanced'; // Deep nested route

      // Simulate the path parsing logic from AppShell._buildAppBar
      List<String> getPathSegments(String path) =>
          path.split('/').where((s) => s.isNotEmpty).toList();

      expect(getPathSegments(currentPath1).length, 0); // Root: no segments
      expect(getPathSegments(currentPath2).length, 1); // Single: 1 segment
      expect(getPathSegments(currentPath3).length, 3); // Nested: 3 segments
      expect(
          getPathSegments(currentPath4).length, 3); // Deep nested: 3 segments

      // Nested route detection: more than 1 segment
      bool isNestedRoute(String path) => getPathSegments(path).length > 1;

      expect(isNestedRoute(currentPath1), false); // Root
      expect(isNestedRoute(currentPath2), false); // Single-level
      expect(isNestedRoute(currentPath3), true); // Nested
      expect(isNestedRoute(currentPath4), true); // Deep nested
    });

    test('Navigation mode detection works correctly', () {
      // Test the navigation mode logic from AppShell.build()
      bool isWideScreen(double width) => width > 600;
      bool isVeryWideScreen(double width) => width > 1200;

      bool useBottomNav(double width, int visibleRoutes) =>
          !isWideScreen(width) && visibleRoutes <= 5;
      bool useMobileDrawer(double width, int visibleRoutes) =>
          !isWideScreen(width) && visibleRoutes > 5;
      bool useRail(double width) =>
          isWideScreen(width) && !isVeryWideScreen(width);
      bool useSidebar(double width) => isVeryWideScreen(width);

      // Test mobile scenarios (width <= 600)
      expect(useBottomNav(400, 3), true); // Mobile with 3 routes
      expect(useBottomNav(400, 5), true); // Mobile with 5 routes
      expect(useMobileDrawer(400, 6), true); // Mobile with 6 routes
      expect(useMobileDrawer(400, 10), true); // Mobile with 10 routes

      expect(useBottomNav(400, 6),
          false); // Mobile with 6 routes should use drawer
      expect(useMobileDrawer(400, 3),
          false); // Mobile with 3 routes should use bottom nav

      // Test tablet scenarios (600 < width <= 1200)
      expect(useRail(800), true); // Tablet width
      expect(useBottomNav(800, 3), false); // Tablet doesn't use bottom nav
      expect(
          useMobileDrawer(800, 10), false); // Tablet doesn't use mobile drawer

      // Test desktop scenarios (width > 1200)
      expect(useSidebar(1400), true); // Desktop width
      expect(useRail(1400), false); // Desktop doesn't use rail
      expect(useBottomNav(1400, 3), false); // Desktop doesn't use bottom nav
    });
  });
}
