import 'package:get_it/get_it.dart';
import 'package:shadcn_app_shell/src/mobx_stores/settings_store.dart';
import 'package:shadcn_app_shell/src/utilities/logger.dart';
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

  // sharedPreferences.setDouble('pi', 3.14159);

  // print('pi: ${sharedPreferences.getDouble('pi')}');

  locator.registerSingleton<SettingsStore>(SettingsStore(sharedPreferences));
  return locator;
}
