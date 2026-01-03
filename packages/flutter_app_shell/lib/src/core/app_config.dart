import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'app_route.dart';
import 'app_shell_action.dart';

class AppConfig {
  final List<AppRoute> routes;
  final String title;
  final bool hideNavigation;
  final List<AppShellAction> actions;
  final ThemeData Function(ThemeData)? themeExtensions;
  final Widget? splashScreen;
  final bool enableSuggestions;
  final bool enableAnalytics;
  final String? initialRoute;
  final bool showThemeToggle;
  final double maxTextScaleFactor;
  final String? homeRoute;

  /// Optional signal indicating when app-level services are ready.
  /// If provided, the app shell will wait for both framework initialization
  /// (settingsStore.isReady) AND this signal before rendering the main UI.
  ///
  /// This prevents SignalEffectException when app services create effects
  /// during initialization. Apps should set this signal to true after all
  /// services have completed their initialization.
  ///
  /// Example:
  /// ```dart
  /// final appReady = signal(false);
  ///
  /// Future<void> initializeServices() async {
  ///   await chatManager.initialize();
  ///   await eventFlowService.initialize();
  ///   // Wait for all service isReady signals
  ///   await Future.doWhile(() async {
  ///     await Future.delayed(Duration(milliseconds: 50));
  ///     return !chatManager.isReady.value || !eventFlowService.isReady.value;
  ///   });
  ///   appReady.value = true;
  /// }
  ///
  /// runShellApp(
  ///   appConfig: AppConfig(
  ///     appReady: appReady,
  ///     // ...
  ///   ),
  /// );
  /// ```
  final Signal<bool>? appReady;

  AppConfig({
    required this.routes,
    required this.title,
    this.hideNavigation = false,
    this.actions = const [],
    this.themeExtensions,
    this.splashScreen,
    this.enableSuggestions = false,
    this.enableAnalytics = false,
    this.initialRoute,
    this.showThemeToggle = true,
    this.maxTextScaleFactor = 1.3,
    this.homeRoute,
    this.appReady,
  });
}
