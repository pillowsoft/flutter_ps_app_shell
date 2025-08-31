import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import '../utils/logger.dart';
import 'package:logging/logging.dart';

/// Enhanced preferences service with reactive signals and type safety
class PreferencesService {
  // Service-specific logger
  static final Logger _logger = createServiceLogger('PreferencesService');
  static PreferencesService? _instance;
  static PreferencesService get instance =>
      _instance ??= PreferencesService._();

  PreferencesService._();

  SharedPreferences? _prefs;
  SharedPreferences get prefs => _prefs!;

  bool get isInitialized => _prefs != null;

  /// Internal map to store reactive signals
  final Map<String, Signal<dynamic>> _signals = {};

  /// Initialize the preferences service
  Future<void> initialize() async {
    if (_prefs != null) return;

    try {
      _logger.info('Initializing preferences service...');
      _prefs = await SharedPreferences.getInstance();
      _logger.info('Preferences service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize preferences service', e, stackTrace);
      rethrow;
    }
  }

  // String preferences

  /// Get a string preference with reactive signal
  Signal<String?> getString(String key, {String? defaultValue}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final currentValue = prefs.getString(key) ?? defaultValue;
      _signals[key] = signal<String?>(currentValue);
    }

    return _signals[key] as Signal<String?>;
  }

  /// Set a string preference
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();

    try {
      final success = await prefs.setString(key, value);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<String?>).value = value;
      }
      _logger.fine('Set string preference: $key = $value');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set string preference: $key', e, stackTrace);
      return false;
    }
  }

  // Boolean preferences

  /// Get a boolean preference with reactive signal
  Signal<bool> getBool(String key, {bool defaultValue = false}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final currentValue = prefs.getBool(key) ?? defaultValue;
      _signals[key] = signal<bool>(currentValue);
    }

    return _signals[key] as Signal<bool>;
  }

  /// Set a boolean preference
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();

    try {
      final success = await prefs.setBool(key, value);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<bool>).value = value;
      }
      _logger.fine('Set bool preference: $key = $value');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set bool preference: $key', e, stackTrace);
      return false;
    }
  }

  // Integer preferences

  /// Get an integer preference with reactive signal
  Signal<int> getInt(String key, {int defaultValue = 0}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final currentValue = prefs.getInt(key) ?? defaultValue;
      _signals[key] = signal<int>(currentValue);
    }

    return _signals[key] as Signal<int>;
  }

  /// Set an integer preference
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();

    try {
      final success = await prefs.setInt(key, value);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<int>).value = value;
      }
      _logger.fine('Set int preference: $key = $value');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set int preference: $key', e, stackTrace);
      return false;
    }
  }

  // Double preferences

  /// Get a double preference with reactive signal
  Signal<double> getDouble(String key, {double defaultValue = 0.0}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final currentValue = prefs.getDouble(key) ?? defaultValue;
      _signals[key] = signal<double>(currentValue);
    }

    return _signals[key] as Signal<double>;
  }

  /// Set a double preference
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();

    try {
      final success = await prefs.setDouble(key, value);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<double>).value = value;
      }
      _logger.fine('Set double preference: $key = $value');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set double preference: $key', e, stackTrace);
      return false;
    }
  }

  // List preferences

  /// Get a string list preference with reactive signal
  Signal<List<String>> getStringList(String key,
      {List<String> defaultValue = const []}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final currentValue = prefs.getStringList(key) ?? defaultValue;
      _signals[key] = signal<List<String>>(currentValue);
    }

    return _signals[key] as Signal<List<String>>;
  }

  /// Set a string list preference
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();

    try {
      final success = await prefs.setStringList(key, value);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<List<String>>).value = value;
      }
      _logger.fine('Set string list preference: $key = $value');
      return success;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to set string list preference: $key', e, stackTrace);
      return false;
    }
  }

  // JSON object preferences

  /// Get a JSON object preference with reactive signal
  Signal<Map<String, dynamic>?> getJson(String key,
      {Map<String, dynamic>? defaultValue}) {
    _ensureInitialized();

    if (!_signals.containsKey(key)) {
      final jsonString = prefs.getString(key);
      Map<String, dynamic>? currentValue;

      if (jsonString != null) {
        try {
          currentValue = jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          _logger.warning('Failed to decode JSON for key $key: $e');
          currentValue = defaultValue;
        }
      } else {
        currentValue = defaultValue;
      }

      _signals[key] = signal<Map<String, dynamic>?>(currentValue);
    }

    return _signals[key] as Signal<Map<String, dynamic>?>;
  }

  /// Set a JSON object preference
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    _ensureInitialized();

    try {
      final jsonString = jsonEncode(value);
      final success = await prefs.setString(key, jsonString);
      if (success && _signals.containsKey(key)) {
        (_signals[key] as Signal<Map<String, dynamic>?>).value = value;
      }
      _logger.fine('Set JSON preference: $key');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set JSON preference: $key', e, stackTrace);
      return false;
    }
  }

  // Utility methods

  /// Check if a preference exists
  bool contains(String key) {
    _ensureInitialized();
    return prefs.containsKey(key);
  }

  /// Remove a preference
  Future<bool> remove(String key) async {
    _ensureInitialized();

    try {
      final success = await prefs.remove(key);
      if (success && _signals.containsKey(key)) {
        _signals.remove(key);
      }
      _logger.fine('Removed preference: $key');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to remove preference: $key', e, stackTrace);
      return false;
    }
  }

  /// Clear all preferences
  Future<bool> clear() async {
    _ensureInitialized();

    try {
      final success = await prefs.clear();
      if (success) {
        _signals.clear();
      }
      _logger.fine('Cleared all preferences');
      return success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear preferences', e, stackTrace);
      return false;
    }
  }

  /// Get all preference keys
  Set<String> getKeys() {
    _ensureInitialized();
    return prefs.getKeys();
  }

  /// Reload preferences from disk
  Future<void> reload() async {
    _ensureInitialized();

    try {
      await prefs.reload();

      // Update all signals with current values
      for (final key in _signals.keys.toList()) {
        final signal = _signals[key]!;

        if (signal is Signal<String?>) {
          signal.value = prefs.getString(key);
        } else if (signal is Signal<bool>) {
          signal.value = prefs.getBool(key) ?? false;
        } else if (signal is Signal<int>) {
          signal.value = prefs.getInt(key) ?? 0;
        } else if (signal is Signal<double>) {
          signal.value = prefs.getDouble(key) ?? 0.0;
        } else if (signal is Signal<List<String>>) {
          signal.value = prefs.getStringList(key) ?? [];
        } else if (signal is Signal<Map<String, dynamic>?>) {
          final jsonString = prefs.getString(key);
          if (jsonString != null) {
            try {
              signal.value = jsonDecode(jsonString) as Map<String, dynamic>;
            } catch (e) {
              signal.value = null;
            }
          } else {
            signal.value = null;
          }
        }
      }

      _logger.fine('Reloaded preferences');
    } catch (e, stackTrace) {
      _logger.severe('Failed to reload preferences', e, stackTrace);
      rethrow;
    }
  }

  /// Get preferences statistics
  PreferencesStats getStats() {
    _ensureInitialized();

    final keys = getKeys();
    var stringCount = 0;
    var boolCount = 0;
    var intCount = 0;
    var doubleCount = 0;
    var listCount = 0;

    for (final key in keys) {
      final value = prefs.get(key);
      if (value is String) {
        stringCount++;
      } else if (value is bool) {
        boolCount++;
      } else if (value is int) {
        intCount++;
      } else if (value is double) {
        doubleCount++;
      } else if (value is List<String>) {
        listCount++;
      }
    }

    return PreferencesStats(
      totalKeys: keys.length,
      stringKeys: stringCount,
      boolKeys: boolCount,
      intKeys: intCount,
      doubleKeys: doubleCount,
      listKeys: listCount,
      reactiveSignals: _signals.length,
    );
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
          'PreferencesService not initialized. Call initialize() first.');
    }
  }
}

/// Preferences statistics
class PreferencesStats {
  final int totalKeys;
  final int stringKeys;
  final int boolKeys;
  final int intKeys;
  final int doubleKeys;
  final int listKeys;
  final int reactiveSignals;

  PreferencesStats({
    required this.totalKeys,
    required this.stringKeys,
    required this.boolKeys,
    required this.intKeys,
    required this.doubleKeys,
    required this.listKeys,
    required this.reactiveSignals,
  });

  @override
  String toString() {
    return 'PreferencesStats(total: $totalKeys, strings: $stringKeys, bools: $boolKeys, ints: $intKeys, doubles: $doubleKeys, lists: $listKeys, signals: $reactiveSignals)';
  }
}
