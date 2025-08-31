import 'package:flutter/material.dart';
import 'app_route.dart';
import 'app_shell_action.dart';

class AppConfig {
  final List<AppRoute> routes;
  final String title;
  final bool hideDrawer;
  final List<AppShellAction> actions;
  final ThemeData Function(ThemeData)? themeExtensions;
  final Widget? splashScreen;
  final bool enableSuggestions;
  final bool enableAnalytics;
  final String? initialRoute;

  AppConfig({
    required this.routes,
    required this.title,
    this.hideDrawer = false,
    this.actions = const [],
    this.themeExtensions,
    this.splashScreen,
    this.enableSuggestions = false,
    this.enableAnalytics = false,
    this.initialRoute,
  });
}
