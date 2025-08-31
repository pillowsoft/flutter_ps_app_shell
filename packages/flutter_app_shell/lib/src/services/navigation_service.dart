import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

class NavigationService {
  late GoRouter _router;

  GoRouter get router => _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  void go(String path, {Object? extra}) {
    _router.go(path, extra: extra);
  }

  void push(String path, {Object? extra}) {
    _router.push(path, extra: extra);
  }

  void pop() {
    if (_router.canPop()) {
      _router.pop();
    }
  }

  void replace(String path, {Object? extra}) {
    _router.replace(path, extra: extra);
  }

  void pushReplacement(String path, {Object? extra}) {
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
}

void setupNavigation(GoRouter router) {
  final navigationService = GetIt.instance.get<NavigationService>();
  navigationService.setRouter(router);
}
