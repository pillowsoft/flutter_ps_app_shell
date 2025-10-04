import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/window_state_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_config.dart';
import 'app_route.dart';
import 'app_shell.dart';
import '../services/service_locator.dart';
import '../services/navigation_service.dart';
import '../state/app_shell_settings_store.dart';
import '../utils/logger.dart';
import 'package:logging/logging.dart';
import '../plugins/core/plugin_manager.dart';
import '../plugins/interfaces/base_plugin.dart';

// Service-specific logger
final Logger _logger = createServiceLogger('AppShellRunner');

/// Creates a platform-aware page with appropriate transitions
/// Main shell routes use NoTransitionPage (no animation between tabs)
/// Nested routes use platform-specific transitions (iOS sliding, Material fade/scale)
Page<dynamic> _buildPlatformAwarePage({
  required GoRouterState state,
  required Widget child,
  bool isNestedRoute = false,
}) {
  // For main shell routes (tab switching), use no transition
  if (!isNestedRoute) {
    return NoTransitionPage(
      key: state.pageKey,
      child: child,
    );
  }

  // For nested routes, use platform-aware transitions
  final settingsStore = GetIt.instance<AppShellSettingsStore>();
  final uiSystem = settingsStore.uiSystem.value;

  _logger.info(
      'Building page for nested route: ${state.uri.path} with UI system: $uiSystem');

  switch (uiSystem) {
    case 'cupertino':
      return CupertinoPage(
        key: state.pageKey,
        child: child,
      );
    case 'material':
      return MaterialPage(
        key: state.pageKey,
        child: child,
      );
    case 'forui':
    default:
      // ForUI uses Material-style transitions
      return MaterialPage(
        key: state.pageKey,
        child: child,
      );
  }
}

Future<void> initializeApp({
  bool enablePlugins = true,
  Map<String, dynamic> pluginConfiguration = const <String, dynamic>{},
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from asset bundle
  try {
    await dotenv.load(fileName: ".env");
    _logger.info('Environment variables loaded from .env file');
  } catch (e) {
    _logger.info('No .env file found or failed to load, using defaults');
  }

  await setupLocator();

  // Initialize plugin system if enabled
  if (enablePlugins) {
    try {
      _logger.info('Initializing plugin system...');
      final pluginManager = PluginManager();

      // Extract manual plugins from configuration
      final manualPluginsRaw = pluginConfiguration['manualPlugins'];
      final List<BasePlugin> manualPlugins;
      if (manualPluginsRaw is List<BasePlugin>) {
        manualPlugins = manualPluginsRaw;
      } else if (manualPluginsRaw is List) {
        manualPlugins = manualPluginsRaw.cast<BasePlugin>();
      } else {
        manualPlugins = [];
      }

      await pluginManager.initialize(
        enableAutoDiscovery: true,
        manualPlugins: manualPlugins,
        configuration: pluginConfiguration,
      );

      // Register PluginManager as a service for other components to use
      GetIt.instance.registerSingleton<PluginManager>(pluginManager);

      _logger.info('Plugin system initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize plugin system: $e');
      // Continue without plugins rather than failing completely
    }
  }

  // Initialize desktop window management
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await windowManager.ensureInitialized();

    // Get saved window size for initial WindowOptions, or use default
    Size initialSize = const Size(1200, 800); // Default size
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final savedWidth = sharedPrefs.getDouble('window.size.width');
      final savedHeight = sharedPrefs.getDouble('window.size.height');

      if (savedWidth != null &&
          savedHeight != null &&
          savedWidth >= 400 &&
          savedHeight >= 600) {
        initialSize = Size(savedWidth, savedHeight);
        _logger
            .info('Using saved window size for initial options: $initialSize');
      } else {
        _logger.info('No saved window size found, using default: $initialSize');
      }
    } catch (e) {
      _logger.warning('Failed to load saved window size, using default: $e');
    }

    // Check if we have saved window position to determine if we should center
    bool shouldCenter = true;
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final savedX = sharedPrefs.getDouble('window.position.x');
      if (savedX != null) {
        shouldCenter = false; // We have saved position, don't center
        _logger.info('Found saved window position, will not center on startup');
      } else {
        _logger.info('No saved window position, will center on first launch');
      }
    } catch (e) {
      _logger.warning('Failed to check saved position: $e');
    }

    WindowOptions windowOptions = WindowOptions(
      size: initialSize, // Use saved size or default
      center: shouldCenter, // Only center on first launch
      minimumSize: const Size(
          400, 600), // Reduced from 800 to 400 to allow mobile layout testing
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      // Prevent automatic resizing behavior
      alwaysOnTop: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Initialize and restore window state BEFORE showing
      try {
        final windowStateService = GetIt.instance<WindowStateService>();
        await windowStateService.initialize();
        await windowStateService.restoreWindowState();
        _logger
            .info('Window state service initialized and restored successfully');
      } catch (e) {
        _logger.warning('Failed to initialize or restore window state: $e');
        // Continue without window state restoration
      }

      // Finally, make it visible and focused
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final baseColorScheme = brightness == Brightness.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: baseColorScheme.copyWith(
      surface: brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFFAFAFA),
      surfaceContainer: brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF2F2F2),
      surfaceContainerLow: brightness == Brightness.dark
          ? const Color(0xFF232323)
          : const Color(0xFFF7F7F7),
      surfaceContainerHigh: brightness == Brightness.dark
          ? const Color(0xFF323232)
          : const Color(0xFFECECEC),
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFE6E6E6),
      secondaryContainer: brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFE6F3FF),
      // Fix text colors for dark mode
      onSurface: brightness == Brightness.dark
          ? const Color(0xFFE5E5E5) // Light text on dark surface
          : const Color(0xFF1A1A1A), // Dark text on light surface
      onSurfaceVariant: brightness == Brightness.dark
          ? const Color(0xFFB0B0B0) // Lighter gray for subtitles in dark mode
          : const Color(0xFF666666), // Darker gray for subtitles in light mode
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 14,
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E5E5)
            : const Color(0xFF1A1A1A),
      ),
      bodyMedium: TextStyle(
        fontSize: 12,
        color: brightness == Brightness.dark
            ? const Color(0xFFB0B0B0)
            : const Color(0xFF666666),
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E5E5)
            : const Color(0xFF1A1A1A),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E5E5)
            : const Color(0xFF1A1A1A),
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E5E5)
            : const Color(0xFF1A1A1A),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        color: brightness == Brightness.dark
            ? const Color(0xFFE5E5E5)
            : const Color(0xFF1A1A1A),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        color: brightness == Brightness.dark
            ? const Color(0xFFB0B0B0)
            : const Color(0xFF666666),
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        color: brightness == Brightness.dark
            ? const Color(0xFFB0B0B0)
            : const Color(0xFF666666),
      ),
    ),
    listTileTheme: ListTileThemeData(
      // Ensure ListTile subtitle uses proper colors
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        color: brightness == Brightness.dark
            ? const Color(0xFFB0B0B0)
            : const Color(0xFF666666),
      ),
    ),
    iconTheme: IconThemeData(
      size: 21.6,
      color: brightness == Brightness.dark
          ? const Color(0xFFE5E5E5)
          : const Color(0xFF1A1A1A),
    ),
  );
}

void runShellApp(
  Future<AppConfig> Function() initApp, {
  bool enablePlugins = true,
  Map<String, dynamic> pluginConfiguration = const <String, dynamic>{},
}) async {
  await initializeApp(
    enablePlugins: enablePlugins,
    pluginConfiguration: pluginConfiguration,
  );
  final appConfig = await initApp();
  final settingsStore = GetIt.instance.get<AppShellSettingsStore>();

  // Separate fullscreen routes from shell routes
  final fullscreenRoutes = appConfig.routes.where((r) => r.fullscreen).toList();
  final shellRoutes = appConfig.routes.where((r) => !r.fullscreen).toList();

  _logger.info(
      'Configuring router with ${fullscreenRoutes.length} fullscreen routes and ${shellRoutes.length} shell routes');

  final router = GoRouter(
    initialLocation: appConfig.initialRoute ?? appConfig.routes.first.path,
    routes: [
      // Fullscreen routes (outside ShellRoute)
      ...fullscreenRoutes.map((route) {
        _logger.info(
            'Registering fullscreen route: ${route.path} (${route.title})');
        for (final subRoute in route.subRoutes) {
          _logger.info(
              '  → Registering fullscreen sub-route: ${route.path}/${subRoute.path} (${subRoute.title})');
        }
        return GoRoute(
          path: route.path,
          pageBuilder: (context, state) => _buildPlatformAwarePage(
            state: state,
            child: route.builder(context, state),
            isNestedRoute: false, // Fullscreen routes - no transitions
          ),
          routes: route.subRoutes
              .map((subRoute) => GoRoute(
                    path: subRoute.path,
                    pageBuilder: (context, state) => _buildPlatformAwarePage(
                      state: state,
                      child: subRoute.builder(context, state),
                      isNestedRoute:
                          true, // Nested routes - platform-aware transitions
                    ),
                  ))
              .toList(),
        );
      }),

      // Shell routes (wrapped in AppShell)
      if (shellRoutes.isNotEmpty)
        ShellRoute(
          builder: (context, state, child) {
            // Find the parent route for the current path
            final currentPath = state.uri.path;
            _logger.info('ShellRoute builder: current path = $currentPath');

            AppRoute? currentRoute;

            // First try exact match
            currentRoute = shellRoutes.cast<AppRoute?>().firstWhere(
                  (route) => route?.path == currentPath,
                  orElse: () => null,
                );

            // If no exact match, find parent route for nested paths
            if (currentRoute == null) {
              currentRoute = shellRoutes.cast<AppRoute?>().firstWhere(
                    (route) =>
                        route != null &&
                        currentPath.startsWith('${route.path}/'),
                    orElse: () => shellRoutes.first,
                  );
            }

            _logger.info(
                'ShellRoute builder: matched route = ${currentRoute?.path} (${currentRoute?.title})');

            return AppShell(
              routes:
                  shellRoutes, // Only pass shell routes, not fullscreen routes
              title: appConfig.title,
              currentRouteTitle:
                  null, // Let AppShell determine the title dynamically
              hideNavigation: appConfig.hideNavigation,
              actions: appConfig.actions,
              showThemeToggle: appConfig.showThemeToggle,
              homeRoute: appConfig.homeRoute,
              child: child,
            );
          },
          routes: shellRoutes.map((route) {
            _logger.info(
                'Registering shell route: ${route.path} (${route.title})');
            for (final subRoute in route.subRoutes) {
              _logger.info(
                  '  → Registering shell sub-route: ${route.path}/${subRoute.path} (${subRoute.title})');
            }
            return GoRoute(
              path: route.path,
              pageBuilder: (context, state) => _buildPlatformAwarePage(
                state: state,
                child: route.builder(context, state),
                isNestedRoute:
                    false, // Main shell routes - no transitions between tabs
              ),
              routes: route.subRoutes
                  .map((subRoute) => GoRoute(
                        path: subRoute.path,
                        pageBuilder: (context, state) =>
                            _buildPlatformAwarePage(
                          state: state,
                          child: subRoute.builder(context, state),
                          isNestedRoute:
                              true, // Nested routes - platform-aware transitions
                        ),
                      ))
                  .toList(),
            );
          }).toList(),
        ),
    ],
  );

  setupNavigation(router);

  runApp(
    Watch(
      (context) {
        ThemeData theme = _buildTheme(Brightness.light);
        ThemeData darkTheme = _buildTheme(Brightness.dark);

        // Apply any theme extensions from the app
        if (appConfig.themeExtensions != null) {
          _logger.info('Applying theme extensions');
          theme = appConfig.themeExtensions!(theme);
          darkTheme = appConfig.themeExtensions!(darkTheme);
        }

        // Get the appropriate UI factory and use it to create the app
        final uiSystem = settingsStore.uiSystem.value;

        // Get current brightness - computed once here to ensure Watch tracks themeMode dependency
        // and to use as key for forcing CupertinoApp rebuilds
        final currentBrightness = settingsStore.getCurrentBrightness(context);

        // Clamp text scale factor to prevent extreme accessibility scaling from breaking UI
        final mediaData = MediaQuery.of(context);
        final currentScale = mediaData.textScaler.scale(1.0);
        final clampedScale = currentScale.clamp(1.0, appConfig.maxTextScaleFactor);

        // Wrap app in MediaQuery to apply text scale clamping
        return MediaQuery(
          data: mediaData.copyWith(
            textScaler: TextScaler.linear(clampedScale),
          ),
          child: uiSystem == 'cupertino'
              ? CupertinoApp.router(
                  key: ValueKey('cupertino_$currentBrightness'),
                  routerConfig: router,
                  debugShowCheckedModeBanner: false,
                  title: appConfig.title,
                  theme: CupertinoThemeData(
                    brightness: currentBrightness,
                  ),
                  // Add localizations to support Material widgets within Cupertino app
                  localizationsDelegates: const [
                    DefaultMaterialLocalizations.delegate,
                    DefaultCupertinoLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                  ],
                )
              : MaterialApp.router(
                  routerConfig: router,
                  debugShowCheckedModeBanner: false,
                  title: appConfig.title,
                  theme: theme,
                  darkTheme: darkTheme,
                  themeMode: settingsStore.themeMode.value,
                ),
        );
      },
    ),
  );
}
