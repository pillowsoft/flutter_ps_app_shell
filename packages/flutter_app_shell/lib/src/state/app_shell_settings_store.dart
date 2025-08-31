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
  }

  void _setupEffects() {
    _logger.fine('Setting up reactive effects for persistence...');

    // Set up effects to persist changes
    effect(() {
      _logger.fine('Saving brightness: ${brightness.value.index}');
      _prefs.setInt('brightness', brightness.value.index);
    });

    effect(() {
      _logger.fine('Saving themeMode: ${themeMode.value.index}');
      _prefs.setInt('themeMode', themeMode.value.index);
    });

    effect(() {
      _logger.fine('Saving sidebarCollapsed: ${sidebarCollapsed.value}');
      _prefs.setBool('sidebarCollapsed', sidebarCollapsed.value);
    });

    effect(() {
      _logger
          .fine('Saving showNavigationLabels: ${showNavigationLabels.value}');
      _prefs.setBool('showNavigationLabels', showNavigationLabels.value);
    });

    effect(() {
      _logger.fine('Saving debugMode: ${debugMode.value}');
      _prefs.setBool('debugMode', debugMode.value);
    });

    effect(() {
      _logger.fine('Saving logLevel: ${logLevel.value}');
      _prefs.setString('logLevel', logLevel.value);
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
      _logger.fine('Saving uiSystem: ${uiSystem.value}');
      _prefs.setString('uiSystem', uiSystem.value);
    });

    effect(() {
      _logger.fine('Saving textScaleFactor: ${textScaleFactor.value}');
      _prefs.setDouble('textScaleFactor', textScaleFactor.value);
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
    switch (themeMode.value) {
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  }
}
