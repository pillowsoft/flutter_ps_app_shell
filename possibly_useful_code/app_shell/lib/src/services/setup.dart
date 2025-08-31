import 'package:app_shell/src/signal_stores/app_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:app_shell/src/utilities/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GetIt> setupLocator() async {
  var locator = GetIt.instance;

  logger.i('logger: $logger');

  final SharedPreferencesWithCache sharedPreferences =
      await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
              // // When an allowlist is included, any keys that aren't included cannot be used.
              // allowList: <String>{'repeat', 'action'},
              ));

  locator.registerSingleton<AppShellSettingsStore>(
      AppShellSettingsStore(sharedPreferences));
  return locator;
}
