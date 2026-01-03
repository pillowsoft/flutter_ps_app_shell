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

  /// Optional callback for activating reactive effects.
  ///
  /// Called by the framework AFTER [appReady] check passes and BEFORE
  /// rendering the AppShell. This is the correct place to create effects
  /// that read from database watchers or other reactive signals.
  ///
  /// **Two-Phase Initialization Pattern**: Services should create watchers
  /// during `initialize()`, then create effects in `activateEffects()`
  /// called from this callback.
  ///
  /// **Why needed**: Prevents SignalEffectException by ensuring effects
  /// don't create dynamic signals during evaluation. Creating signals
  /// inside effects (e.g., calling `watchWhere()` inside an `effect()`)
  /// causes reactive cycles that `untracked()` cannot prevent.
  ///
  /// Example:
  /// ```dart
  /// class MyService {
  ///   late final ReadonlySignal<List<Map>> _itemsWatcher;
  ///   final items = signal<List<Item>>([]);
  ///
  ///   // Phase 1: Create watchers during initialization
  ///   Future<void> initialize() async {
  ///     _itemsWatcher = db.watchWhere('items', {});
  ///     final initial = await db.findWhere('items', {});
  ///     items.value = initial;
  ///     // NO effects created yet!
  ///   }
  ///
  ///   // Phase 2: Create effects from pre-existing watchers
  ///   void activateEffects() {
  ///     effect(() {
  ///       final data = _itemsWatcher.value;
  ///       untracked(() => items.value = data);
  ///     });
  ///   }
  /// }
  ///
  /// runShellApp(() async {
  ///   final service = MyService();
  ///   await service.initialize();  // Creates watchers, loads data
  ///
  ///   return AppConfig(
  ///     onEffectsActivate: () {
  ///       service.activateEffects();  // Creates effects from watchers
  ///     },
  ///     // ...
  ///   );
  /// });
  /// ```
  ///
  /// See `docs/signals-best-practices.md` for comprehensive pattern guide.
  final void Function()? onEffectsActivate;

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
    this.onEffectsActivate,
  });
}
