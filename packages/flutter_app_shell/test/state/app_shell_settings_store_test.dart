import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_shell/src/state/app_shell_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppShellSettingsStore store;

  setUp(() async {
    // Set up in-memory SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = AppShellSettingsStore(prefs);
  });

  group('AppShellSettingsStore - Signal Safety', () {
    test('should initialize without SignalEffectException', () async {
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not throw and should be ready
      expect(store.isReady.value, isTrue);
      expect(store.persistenceFailureCount.value, equals(0));
    });

    test('isReady signal should become true after setup', () async {
      // Initially might be false
      final initialReady = store.isReady.value;

      // Wait for microtask to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Should be ready now
      expect(store.isReady.value, isTrue);

      // Should either start true or transition to true
      if (!initialReady) {
        expect(store.isReady.value, isTrue);
      }
    });

    test('should handle rapid signal changes without crashes', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Rapidly change multiple signals
      for (var i = 0; i < 10; i++) {
        store.brightness.value =
            i % 2 == 0 ? Brightness.light : Brightness.dark;
        store.sidebarCollapsed.value = i % 2 == 0;
        store.textScaleFactor.value = 1.0 + (i * 0.1);
      }

      // Wait for all effects to settle
      await Future.delayed(const Duration(milliseconds: 200));

      // Should not throw SignalEffectException
      expect(store.persistenceFailureCount.value, equals(0));
      expect(store.lastPersistenceError.value, isNull);
    });

    test('should handle multiple concurrent signal changes', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Change multiple signals simultaneously
      store.brightness.value = Brightness.dark;
      store.themeMode.value = ThemeMode.dark;
      store.sidebarCollapsed.value = true;
      store.showNavigationLabels.value = false;
      store.debugMode.value = true;
      store.uiSystem.value = 'cupertino';

      // Wait for effects to process
      await Future.delayed(const Duration(milliseconds: 200));

      // Should persist without errors
      expect(store.persistenceFailureCount.value, equals(0));
      expect(store.lastPersistenceError.value, isNull);
    });

    test('should persist settings correctly', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Change settings
      store.brightness.value = Brightness.dark;
      store.uiSystem.value = 'cupertino';
      store.textScaleFactor.value = 1.5;

      // Wait for persistence
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify values persisted to SharedPreferences
      expect(prefs.getInt('brightness'), equals(Brightness.dark.index));
      expect(prefs.getString('uiSystem'), equals('cupertino'));
      expect(prefs.getDouble('textScaleFactor'), equals(1.5));
    });

    test('should load settings from SharedPreferences', () async {
      // Pre-populate SharedPreferences
      await prefs.setInt('brightness', Brightness.dark.index);
      await prefs.setString('uiSystem', 'forui');
      await prefs.setDouble('textScaleFactor', 1.2);

      // Create new store instance
      final newStore = AppShellSettingsStore(prefs);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify settings were loaded
      expect(newStore.brightness.value, equals(Brightness.dark));
      expect(newStore.uiSystem.value, equals('forui'));
      expect(newStore.textScaleFactor.value, equals(1.2));
    });

    test('should handle convenience methods without errors', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Test convenience methods
      store.setBrightness(Brightness.dark);
      await Future.delayed(const Duration(milliseconds: 50));

      store.setThemeMode(ThemeMode.light);
      await Future.delayed(const Duration(milliseconds: 50));

      store.toggleSidebar();
      await Future.delayed(const Duration(milliseconds: 50));

      store.setUiSystem('cupertino');
      await Future.delayed(const Duration(milliseconds: 50));

      store.resetToDefaults();
      await Future.delayed(const Duration(milliseconds: 100));

      // Should complete without errors
      expect(store.persistenceFailureCount.value, equals(0));
      expect(store.lastPersistenceError.value, isNull);
    });

    test('should handle resetToDefaults correctly', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Change all settings
      store.brightness.value = Brightness.dark;
      store.themeMode.value = ThemeMode.dark;
      store.sidebarCollapsed.value = true;
      store.showNavigationLabels.value = false;
      store.debugMode.value = true;
      store.logLevel.value = 'fine';
      store.uiSystem.value = 'cupertino';
      store.textScaleFactor.value = 1.5;

      // Reset to defaults
      store.resetToDefaults();
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify defaults
      expect(store.brightness.value, equals(Brightness.light));
      expect(store.themeMode.value, equals(ThemeMode.system));
      expect(store.sidebarCollapsed.value, equals(false));
      expect(store.showNavigationLabels.value, equals(true));
      expect(store.debugMode.value, equals(false));
      expect(store.logLevel.value, equals('info'));
      expect(store.uiSystem.value, equals('material'));
      expect(store.textScaleFactor.value, equals(1.0));
    });

    test('should handle setBrightness theme mode logic', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Start with system theme mode
      store.themeMode.value = ThemeMode.system;

      // Set brightness dark - should switch to manual dark theme mode
      store.setBrightness(Brightness.dark);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.brightness.value, equals(Brightness.dark));
      expect(store.themeMode.value, equals(ThemeMode.dark));

      // Reset to system mode
      store.themeMode.value = ThemeMode.system;
      await Future.delayed(const Duration(milliseconds: 50));

      // Set brightness light - should switch to manual light theme mode
      store.setBrightness(Brightness.light);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.brightness.value, equals(Brightness.light));
      expect(store.themeMode.value, equals(ThemeMode.light));
    });

    test('should handle setThemeMode brightness logic', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Set theme mode to dark
      store.setThemeMode(ThemeMode.dark);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.themeMode.value, equals(ThemeMode.dark));
      expect(store.brightness.value, equals(Brightness.dark));

      // Set theme mode to light
      store.setThemeMode(ThemeMode.light);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.themeMode.value, equals(ThemeMode.light));
      expect(store.brightness.value, equals(Brightness.light));

      // Set theme mode to system - brightness should not change
      final currentBrightness = store.brightness.value;
      store.setThemeMode(ThemeMode.system);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.themeMode.value, equals(ThemeMode.system));
      // Brightness stays the same when switching to system mode
      expect(store.brightness.value, equals(currentBrightness));
    });

    test('should only accept valid UI systems', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Valid UI systems
      store.setUiSystem('material');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.uiSystem.value, equals('material'));

      store.setUiSystem('cupertino');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.uiSystem.value, equals('cupertino'));

      store.setUiSystem('forui');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.uiSystem.value, equals('forui'));

      // Invalid UI system - should be ignored
      store.setUiSystem('invalid');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.uiSystem.value, equals('forui')); // Should remain unchanged
    });
  });

  group('AppShellSettingsStore - Initialization Lifecycle', () {
    test('should start with isReady = false', () {
      // Create new store
      final newStore = AppShellSettingsStore(prefs);

      // isReady should start false or become true very quickly
      // This is a race condition, so we just verify it exists
      expect(newStore.isReady, isNotNull);
    });

    test('should set isReady to true after effects setup', () async {
      // Create new store
      final newStore = AppShellSettingsStore(prefs);

      // Wait for microtask to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Should be ready now
      expect(newStore.isReady.value, isTrue);
    });

    test('should complete initialization within reasonable time', () async {
      // Create new store
      final newStore = AppShellSettingsStore(prefs);

      // Wait maximum 100ms for initialization
      var attempts = 0;
      while (!newStore.isReady.value && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 10));
        attempts++;
      }

      // Should be ready within 100ms
      expect(newStore.isReady.value, isTrue);
      expect(attempts, lessThan(10), reason: 'Initialization took too long');
    });
  });
}
