import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  final void Function(String) _navigate;

  NavigationService(this._navigate);

  void navigateTo(String path) {
    _navigate(path);
  }
}

// Add this to your AppShell initialization
void setupNavigation(GoRouter router) {
  GetIt.I.registerSingleton<NavigationService>(
    NavigationService((path) => router.go(path)),
  );
}
