import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import '../state/app_shell_settings_store.dart';
import 'navigation_service.dart';
import 'database_service.dart';
import 'preferences_service.dart';
import 'network_service.dart';
import 'authentication_service.dart';
import 'logging_service.dart';
import 'cloudflare_service.dart';
import 'window_state_service.dart';
import '../utils/logger.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize LoggingService first (before any logging calls)
  if (!getIt.isRegistered<LoggingService>()) {
    final loggingService = LoggingService.instance;
    await loggingService.initialize(
      globalLevel: Level.INFO,
      enableFileLogging: false, // Can be configured later
    );
    getIt.registerSingleton<LoggingService>(loggingService);
  }

  // Get a hierarchical logger for this service
  final logger = createServiceLogger('ServiceLocator');
  logger.info('Setting up service locator...');

  // Core Services

  // Register NavigationService
  if (!getIt.isRegistered<NavigationService>()) {
    getIt.registerLazySingleton<NavigationService>(() => NavigationService());
    logger.info('Registered NavigationService');
  } else {
    logger.info('NavigationService already registered, skipping');
  }

  // Get SharedPreferences instance
  if (!getIt.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    logger.info('Registered SharedPreferences');
  } else {
    logger.info('SharedPreferences already registered, skipping');
  }

  // Register PreferencesService and initialize
  if (!getIt.isRegistered<PreferencesService>()) {
    final preferencesService = PreferencesService.instance;
    await preferencesService.initialize();
    getIt.registerSingleton<PreferencesService>(preferencesService);
    logger.info('Registered PreferencesService');
  } else {
    logger.info('PreferencesService already registered, skipping');
  }

  // Register AppShellSettingsStore
  if (!getIt.isRegistered<AppShellSettingsStore>()) {
    getIt.registerLazySingleton<AppShellSettingsStore>(
      () => AppShellSettingsStore(getIt<SharedPreferences>()),
    );
    logger.info('Registered AppShellSettingsStore');
  } else {
    logger.info('AppShellSettingsStore already registered, skipping');
  }

  // Advanced Services

  // Register DatabaseService with automatic configuration from environment
  if (!getIt.isRegistered<DatabaseService>()) {
    try {
      // Get configuration from environment variables
      final appId = dotenv.env['INSTANTDB_APP_ID'] ?? '';
      final enableSync = dotenv.env['INSTANTDB_ENABLE_SYNC'] != 'false';
      final verboseLogging = dotenv.env['INSTANTDB_VERBOSE_LOGGING'] == 'true';
      final forceLocalOnly = dotenv.env['FORCE_LOCAL_ONLY'] == 'true';

      final databaseService = DatabaseService.instance;
      await databaseService.initialize(
        appId: forceLocalOnly ? '' : appId,
        enableSync: enableSync,
        verboseLogging: verboseLogging,
      );
      getIt.registerSingleton<DatabaseService>(databaseService);

      final mode =
          (appId.isEmpty || forceLocalOnly) ? 'local-only' : 'cloud-sync';
      logger.info('Registered database service ($mode mode)');
    } catch (e) {
      // If dotenv is not loaded, fallback to local-only mode
      logger.warning(
          'Environment variables not available, using local-only database mode');
      final databaseService = DatabaseService.instance;
      await databaseService
          .initialize(); // Empty appId defaults to local-only mode
      getIt.registerSingleton<DatabaseService>(databaseService);
      logger.info('Registered database service (local-only mode)');
    }
  } else {
    logger.info('DatabaseService already registered, skipping');
  }

  // Register NetworkService and initialize
  if (!getIt.isRegistered<NetworkService>()) {
    final networkService = NetworkService.instance;
    await networkService.initialize();
    getIt.registerSingleton<NetworkService>(networkService);
    logger.info('Registered NetworkService');
  } else {
    logger.info('NetworkService already registered, skipping');
  }

  // Register AuthenticationService and initialize
  if (!getIt.isRegistered<AuthenticationService>()) {
    final authService = AuthenticationService.instance;
    await authService.initialize();
    getIt.registerSingleton<AuthenticationService>(authService);
    logger.info('Registered AuthenticationService');
  } else {
    logger.info('AuthenticationService already registered, skipping');
  }

  // Register CloudflareService and initialize
  if (!getIt.isRegistered<CloudflareService>()) {
    try {
      // Get Cloudflare configuration from environment variables
      final workerUrl = dotenv.env['CLOUDFLARE_WORKER_URL'] ?? '';
      final jwtSecret = dotenv.env['SESSION_JWT_SECRET'] ?? '';
      final jwtIssuer = dotenv.env['SESSION_JWT_ISSUER'] ?? '';
      final jwtAudience = dotenv.env['SESSION_JWT_AUDIENCE'] ?? '';

      final cloudflareService = CloudflareService.instance;
      await cloudflareService.initialize(
        authShimUrl: workerUrl.isNotEmpty
            ? '${workerUrl.replaceAll('/api/', '/auth/')}'
            : '',
        apiWorkerUrl: workerUrl.isNotEmpty ? workerUrl : '',
        authService: getIt<AuthenticationService>(),
      );
      getIt.registerSingleton<CloudflareService>(cloudflareService);

      logger.info(
          'Registered CloudflareService${workerUrl.isEmpty ? ' (not configured)' : ''}');
    } catch (e) {
      // If CloudflareService fails to initialize, register it anyway but mark as disabled
      logger.warning(
          'CloudflareService initialization failed, registering as disabled: $e');
      final cloudflareService = CloudflareService.instance;
      getIt.registerSingleton<CloudflareService>(cloudflareService);
    }
  } else {
    logger.info('CloudflareService already registered, skipping');
  }

  // Register WindowStateService without initialization (will be initialized after window is ready)
  if (!getIt.isRegistered<WindowStateService>()) {
    final windowStateService = WindowStateService.instance;
    getIt.registerSingleton<WindowStateService>(windowStateService);
    logger.info('Registered window state service (initialization deferred)');
  } else {
    logger.info('WindowStateService already registered, skipping');
  }

  logger.info('Service locator setup complete');
}
