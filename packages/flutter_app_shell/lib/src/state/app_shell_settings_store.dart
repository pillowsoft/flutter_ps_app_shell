import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';
import '../services/logging_service.dart';

class AppShellSettingsStore {
  final SharedPreferences _prefs;

  // Service-specific logger
  static final Logger _logger = createServiceLogger('AppShellSettingsStore');

  // Theme settings
  late final Signal<Brightness> brightness;
  late final Signal<ThemeMode> themeMode;

  // Navigation settings
  late final Signal<bool> sidebarCollapsed;
  late final Signal<bool> showNavigationLabels;

  // Developer settings
  late final Signal<bool> debugMode;
  late final Signal<String> logLevel;

  // UI preferences
  late final Signal<String> uiSystem; // 'material', 'cupertino', 'forui'
  late final Signal<double> textScaleFactor;

  // Persistence error tracking
  late final Signal<String?> lastPersistenceError;
  late final Signal<int> persistenceFailureCount;

  // Initialization lifecycle
  late final Signal<bool> isReady;

  AppShellSettingsStore(this._prefs) {
    _initializeSignals();
    _loadSettings();
    _setupEffects();
  }

  void _initializeSignals() {
    _logger.fine('Initializing signals with default values...');

    // Theme settings
    brightness = signal(Brightness.light);
    themeMode = signal(ThemeMode.system);

    // Navigation settings
    sidebarCollapsed = signal(false);
    showNavigationLabels = signal(true);

    // Developer settings
    debugMode = signal(false);
    logLevel = signal('info');

    // UI preferences
    uiSystem = signal('material');
    textScaleFactor = signal(1.0);

    // Persistence error tracking
    lastPersistenceError = signal<String?>(null);
    persistenceFailureCount = signal<int>(0);

    // Initialization lifecycle
    isReady = signal<bool>(false);
  }

  void _setupEffects() {
    _logger.fine('Setting up reactive effects for persistence...');

    // CRITICAL PATTERN: Signal writes inside effects MUST use untracked()
    //
    // Rule: ALL signal mutations inside effect() must be wrapped in untracked(),
    // even synchronous writes to different signals. This prevents reactive cycles
    // when Watch widgets and effects are active simultaneously.
    //
    // Pattern:
    //   effect(() {
    //     final trigger = sourceSignal.value;  // Read (creates dependency)
    //     asyncOp(trigger).then((result) {
    //       untracked(() => targetSignal.value = result);  // Write in untracked
    //     });
    //   });
    //
    // This applies to:
    //   - ✅ Async callback writes (like these persistence effects)
    //   - ✅ Synchronous writes (e.g., data transformations)
    //   - ✅ Error handler writes
    //   - ✅ Conditional writes
    //
    // See docs/signals-best-practices.md for comprehensive examples and patterns.
    // See DatabaseService and AuthenticationService for reference implementations.

    // Set up effects to persist changes
    // Note: SharedPreferences methods return Futures but are fire-and-forget safe
    // We add error handling to catch any persistence issues
    effect(() {
      final value = brightness.value.index;
      _logger.fine('Saving brightness: $value');
      _prefs.setInt('brightness', value).then(
        (success) {
          if (success) {
            // Clear error on successful save
            untracked(() {
              if (lastPersistenceError.value?.contains('brightness') ?? false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('brightness', e)),
      );
    });

    effect(() {
      final value = themeMode.value.index;
      _logger.fine('Saving themeMode: $value');
      _prefs.setInt('themeMode', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('themeMode') ?? false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('themeMode', e)),
      );
    });

    effect(() {
      final value = sidebarCollapsed.value;
      _logger.fine('Saving sidebarCollapsed: $value');
      _prefs.setBool('sidebarCollapsed', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('sidebarCollapsed') ??
                  false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('sidebarCollapsed', e)),
      );
    });

    effect(() {
      final value = showNavigationLabels.value;
      _logger.fine('Saving showNavigationLabels: $value');
      _prefs.setBool('showNavigationLabels', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value
                      ?.contains('showNavigationLabels') ??
                  false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) => untracked(
            () => _handlePersistenceFailure('showNavigationLabels', e)),
      );
    });

    effect(() {
      final value = debugMode.value;
      _logger.fine('Saving debugMode: $value');
      _prefs.setBool('debugMode', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('debugMode') ?? false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('debugMode', e)),
      );
    });

    effect(() {
      final value = logLevel.value;
      _logger.fine('Saving logLevel: $value');
      _prefs.setString('logLevel', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('logLevel') ?? false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('logLevel', e)),
      );
    });

    // Connect logLevel signal to LoggingService
    effect(() {
      final levelString = logLevel.value;
      _logger.fine('Updating global log level to: $levelString');
      try {
        LoggingService.instance.setLevelFromString(levelString);
      } catch (e) {
        _logger.warning('Failed to update global log level: $e');
      }
    });

    effect(() {
      final value = uiSystem.value;
      _logger.fine('Saving uiSystem: $value');
      _prefs.setString('uiSystem', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('uiSystem') ?? false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('uiSystem', e)),
      );
    });

    effect(() {
      final value = textScaleFactor.value;
      _logger.fine('Saving textScaleFactor: $value');
      _prefs.setDouble('textScaleFactor', value).then(
        (success) {
          if (success) {
            untracked(() {
              if (lastPersistenceError.value?.contains('textScaleFactor') ??
                  false) {
                lastPersistenceError.value = null;
              }
            });
          }
        },
        onError: (e) =>
            untracked(() => _handlePersistenceFailure('textScaleFactor', e)),
      );
    });

    // Mark as ready AFTER all effects are set up
    Future.microtask(() {
      isReady.value = true;
      _logger.info('AppShellSettingsStore initialization complete');
    });
  }

  void _handlePersistenceFailure(String key, dynamic error) {
    final errorMessage = 'Failed to persist $key: $error';
    _logger.severe(errorMessage);
    // Use batch() for atomic updates and prevent reactive cycles
    batch(() {
      lastPersistenceError.value = errorMessage;
      persistenceFailureCount.value += 1;
    });
  }

  void _loadSettings() {
    _logger.fine('Loading settings from SharedPreferences...');
    _logger.fine('Available keys: ${_prefs.getKeys()}');

    // Load theme settings
    final brightnessIndex =
        _prefs.getInt('brightness') ?? Brightness.light.index;
    final themeModeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;

    _logger.fine(
        'Loading brightness: stored=$brightnessIndex, default=${Brightness.light.index}');
    _logger.fine(
        'Loading themeMode: stored=$themeModeIndex, default=${ThemeMode.system.index}');

    brightness.value = Brightness.values[brightnessIndex];
    themeMode.value = ThemeMode.values[themeModeIndex];

    // Load navigation settings
    final storedSidebarCollapsed = _prefs.getBool('sidebarCollapsed') ?? false;
    final storedShowNavigationLabels =
        _prefs.getBool('showNavigationLabels') ?? true;

    _logger.fine('Loading sidebarCollapsed: stored=$storedSidebarCollapsed');
    _logger.fine(
        'Loading showNavigationLabels: stored=$storedShowNavigationLabels');

    sidebarCollapsed.value = storedSidebarCollapsed;
    showNavigationLabels.value = storedShowNavigationLabels;

    // Load developer settings
    final storedDebugMode = _prefs.getBool('debugMode') ?? false;
    final storedLogLevel = _prefs.getString('logLevel') ?? 'info';

    _logger.fine('Loading debugMode: stored=$storedDebugMode');
    _logger.fine('Loading logLevel: stored=$storedLogLevel');

    debugMode.value = storedDebugMode;
    logLevel.value = storedLogLevel;

    // Load UI preferences
    final storedUiSystem = _prefs.getString('uiSystem') ?? 'material';
    final storedTextScaleFactor = _prefs.getDouble('textScaleFactor') ?? 1.0;

    _logger.fine('Loading uiSystem: stored=$storedUiSystem');
    _logger.fine('Loading textScaleFactor: stored=$storedTextScaleFactor');

    uiSystem.value = storedUiSystem;
    textScaleFactor.value = storedTextScaleFactor;

    _logger.info(
        'Settings loaded from SharedPreferences - brightness: ${brightness.value}, themeMode: ${themeMode.value}, uiSystem: ${uiSystem.value}');
  }

  // Convenience methods
  void setBrightness(Brightness value) {
    brightness.value = value;
    // When manually setting brightness, switch to manual theme mode
    if (themeMode.value == ThemeMode.system) {
      themeMode.value =
          value == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    if (mode != ThemeMode.system) {
      brightness.value =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    }
  }

  void toggleSidebar() {
    sidebarCollapsed.value = !sidebarCollapsed.value;
  }

  void setUiSystem(String system) {
    if (['material', 'cupertino', 'forui'].contains(system)) {
      uiSystem.value = system;
      _logger.info('UI system changed to: $system');
    }
  }

  void resetToDefaults() {
    brightness.value = Brightness.light;
    themeMode.value = ThemeMode.system;
    sidebarCollapsed.value = false;
    showNavigationLabels.value = true;
    debugMode.value = false;
    logLevel.value = 'info';
    uiSystem.value = 'material';
    textScaleFactor.value = 1.0;

    _logger.info('Settings reset to defaults');
  }

  // Get current theme based on theme mode and system brightness
  Brightness getCurrentBrightness(BuildContext context) {
    // Access themeMode.value to create signal dependency for Watch to track
    // This ensures the UI rebuilds when theme mode changes
    final mode = themeMode.value;

    switch (mode) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  }
}
