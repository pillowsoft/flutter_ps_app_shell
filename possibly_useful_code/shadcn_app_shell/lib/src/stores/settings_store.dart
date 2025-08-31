import 'package:flutter/material.dart';
import 'package:shadcn_app_shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

class Settings {
  Settings(this.prefs) {
    _initializeSettings();
  }

  final SharedPreferences prefs;
  final List<EffectCleanup> _cleanup = [];

  late Signal<bool> onboardingSeen;
  late Signal<double?> windowTop;
  late Signal<double?> windowLeft;
  late Signal<double?> windowWidth;
  late Signal<double?> windowHeight;
  late Signal<Brightness> brightness;
  late Signal<ThemeMode> themeMode;
  late Computed<Rect> windowPlacement;

  void _initializeSettings() {
    onboardingSeen = boolSetting('onboardingSeen');
    windowTop = doubleSetting('window_top');
    windowLeft = doubleSetting('window_left');
    windowWidth = doubleSetting('window_width');
    windowHeight = doubleSetting('window_height');

    brightness = _setting(
      'brightness',
      get: (key) =>
          Brightness.values[prefs.getInt(key) ?? Brightness.dark.index],
      set: (key, val) {
        if (val == null) {
          prefs.remove(key);
        } else {
          prefs.setInt(key, val.index);
        }
      },
    );

    themeMode = _setting(
      'theme-mode',
      get: (key) =>
          ThemeMode.values[prefs.getInt(key) ?? ThemeMode.system.index],
      set: (key, val) {
        if (val == null) {
          prefs.remove(key);
        } else {
          prefs.setInt(key, val.index);
        }
      },
    );

    windowPlacement = computed(() {
      final left = windowLeft();
      final top = windowTop();
      final width = windowWidth();
      final height = windowHeight();
      if (left != null && top != null && width != null && height != null) {
        return Rect.fromLTWH(left, top, width, height);
      }
      return const Rect.fromLTWH(0, 0, 800, 600);
    });
  }

  Signal<T> _setting<T>(
    String key, {
    required T Function(String) get,
    required void Function(String, T?) set,
  }) {
    final s = signal<T>(get(key));
    _cleanup.add(s.subscribe((val) => set(key, val)));
    return s;
  }

  Signal<bool> boolSetting(String key) => _setting(
        key,
        get: (key) => prefs.getBool(key) ?? false,
        set: (key, val) {
          if (val == null) {
            prefs.remove(key);
          } else {
            prefs.setBool(key, val);
          }
        },
      );

  Signal<String?> stringSetting(String key) => _setting(
        key,
        get: (key) => prefs.getString(key),
        set: (key, val) {
          if (val == null) {
            prefs.remove(key);
          } else {
            prefs.setString(key, val);
          }
        },
      );

  Signal<int?> intSetting(String key) => _setting(
        key,
        get: (key) => prefs.getInt(key),
        set: (key, val) {
          if (val == null) {
            prefs.remove(key);
          } else {
            prefs.setInt(key, val);
          }
        },
      );

  Signal<double?> doubleSetting(String key) => _setting(
        key,
        get: (key) {
          var value = prefs.getDouble(key);
          logger.i('Getting double $key is $value');
          return value;
        },
        set: (key, val) {
          if (val == null) {
            prefs.remove(key);
          } else {
            logger.i('Setting double $key to $val');
            prefs.setDouble(key, val);
            var regetValue = prefs.getDouble(key);
            logger.i('Re-Getting double $key is $regetValue');
          }
        },
      );

  void dispose() {
    for (final cb in _cleanup) {
      cb();
    }
  }
}

late final Signal<Settings> settings;
