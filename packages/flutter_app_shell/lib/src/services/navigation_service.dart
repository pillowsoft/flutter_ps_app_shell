import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

class NavigationService {
  late GoRouter _router;

  // Dialog awareness
  bool _hasActiveDialog = false;
  bool _allowNavigationWithDialog = false;
  final List<VoidCallback> _beforeNavigateCallbacks = [];
  final List<BuildContext> _contextStack = [];

  GoRouter get router => _router;

  /// Whether a dialog is currently active
  bool get hasActiveDialog => _hasActiveDialog;

  /// Whether navigation is allowed when a dialog is showing
  bool get allowNavigationWithDialog => _allowNavigationWithDialog;

  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Set whether a dialog is currently active
  void setDialogActive(bool active) {
    _hasActiveDialog = active;
  }

  /// Set whether navigation should be allowed with an active dialog
  void setAllowNavigationWithDialog(bool allow) {
    _allowNavigationWithDialog = allow;
  }

  /// Add a callback to be called before navigation
  void addBeforeNavigateCallback(VoidCallback callback) {
    _beforeNavigateCallbacks.add(callback);
  }

  /// Remove a before navigate callback
  void removeBeforeNavigateCallback(VoidCallback callback) {
    _beforeNavigateCallbacks.remove(callback);
  }

  /// Check if navigation is currently allowed
  bool canNavigate() {
    return !_hasActiveDialog || _allowNavigationWithDialog;
  }

  /// Safely navigate, dismissing dialogs if needed
  Future<void> safeNavigate(String path,
      {Object? extra, bool dismissDialogs = true}) async {
    if (_hasActiveDialog && dismissDialogs) {
      // Notify all callbacks (dialogs can auto-dismiss)
      for (final callback in List.from(_beforeNavigateCallbacks)) {
        callback();
      }
      // Wait a frame for dialogs to dismiss
      await Future.delayed(const Duration(milliseconds: 100));
    }
    go(path, extra: extra);
  }

  void go(String path, {Object? extra}) {
    // Notify listeners before navigation
    for (final callback in List.from(_beforeNavigateCallbacks)) {
      callback();
    }
    _router.go(path, extra: extra);
  }

  void push(String path, {Object? extra}) {
    // Notify listeners before navigation
    for (final callback in List.from(_beforeNavigateCallbacks)) {
      callback();
    }
    _router.push(path, extra: extra);
  }

  /// Enhanced pop that can handle dialog dismissal
  void pop({bool isDialog = false}) {
    if (isDialog) {
      _hasActiveDialog = false;
    }

    if (_router.canPop()) {
      _router.pop();
    }
  }

  void replace(String path, {Object? extra}) {
    // Notify listeners before navigation
    for (final callback in List.from(_beforeNavigateCallbacks)) {
      callback();
    }
    _router.replace(path, extra: extra);
  }

  void pushReplacement(String path, {Object? extra}) {
    // Notify listeners before navigation
    for (final callback in List.from(_beforeNavigateCallbacks)) {
      callback();
    }
    _router.pushReplacement(path, extra: extra);
  }

  String get currentPath {
    final RouteMatch lastMatch =
        _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  bool canPop() {
    return _router.canPop();
  }

  // Context stack management for dialog awareness

  /// Push a context to the stack (used when showing dialogs)
  void pushContext(BuildContext context) {
    _contextStack.add(context);
  }

  /// Pop a context from the stack (used when dismissing dialogs)
  void popContext() {
    if (_contextStack.isNotEmpty) {
      _contextStack.removeLast();
    }
  }

  /// Check if there's a modal context (dialog) in the stack
  bool hasModalContext() {
    return _contextStack.any((ctx) {
      try {
        return ctx.mounted && Navigator.of(ctx, rootNavigator: true).canPop();
      } catch (_) {
        return false;
      }
    });
  }

  /// Clear all contexts (used on app reset)
  void clearContextStack() {
    _contextStack.clear();
    _hasActiveDialog = false;
  }
}

void setupNavigation(GoRouter router) {
  final navigationService = GetIt.instance.get<NavigationService>();
  navigationService.setRouter(router);
}
