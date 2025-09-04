import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRoute {
  final String title;
  final String path;
  final IconData icon;
  final Widget Function(BuildContext, GoRouterState) builder;
  final List<AppRoute> subRoutes;
  final bool requiresAuth;
  final bool showInNavigation;
  final bool fullscreen;

  AppRoute({
    required this.title,
    required this.path,
    required this.icon,
    required this.builder,
    this.subRoutes = const [],
    this.requiresAuth = false,
    this.showInNavigation = true,
    this.fullscreen = false,
  });
}
