import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This line is necessary for code-generation to work
part 'settings_store.g.dart';

// ignore: library_private_types_in_public_api
class SettingsStore = _SettingsStore with _$SettingsStore;

abstract class _SettingsStore with Store {
  final SharedPreferencesWithCache _prefs;

  _SettingsStore(this._prefs) {
    _loadSettings();
  }

  @observable
  bool onboardingSeen = false;

  @observable
  double? windowTop;

  @observable
  double? windowLeft;

  @observable
  double? windowWidth;

  @observable
  double? windowHeight;

  @observable
  Brightness brightness = Brightness.dark;

  @observable
  ThemeMode themeMode = ThemeMode.system;

  @computed
  Rect get windowPlacement {
    if (windowLeft != null &&
        windowTop != null &&
        windowWidth != null &&
        windowHeight != null) {
      return Rect.fromLTWH(
          windowLeft!, windowTop!, windowWidth!, windowHeight!);
    }
    return const Rect.fromLTWH(0, 0, 800, 600);
  }

  Future<void> _setNullableValue<T>(
      String key, T? value, Future<void> Function(String, T) setter) async {
    if (value != null) {
      await setter(key, value);
    } else {
      await _prefs.remove(key);
    }
  }

  @action
  Future<void> setOnboardingSeen(bool value) async {
    onboardingSeen = value;
    await _prefs.setBool('onboardingSeen', value);
  }

  @action
  Future<void> setWindowTop(double? value) async {
    windowTop = value;
    await _setNullableValue('window_top', value, _prefs.setDouble);
  }

  @action
  Future<void> setWindowLeft(double? value) async {
    windowLeft = value;
    await _setNullableValue('window_left', value, _prefs.setDouble);
  }

  @action
  Future<void> setWindowWidth(double? value) async {
    windowWidth = value;
    await _setNullableValue('window_width', value, _prefs.setDouble);
  }

  @action
  Future<void> setWindowHeight(double? value) async {
    windowHeight = value;
    await _setNullableValue('window_height', value, _prefs.setDouble);
  }

  @action
  Future<void> setBrightness(Brightness value) async {
    brightness = value;
    await _prefs.setInt('brightness', value.index);
  }

  @action
  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _prefs.setInt('themeMode', value.index);
  }

  Future<void> saveWindowBounds(Rect bounds) async {
    await setWindowLeft(bounds.left);
    await setWindowTop(bounds.top);
    await setWindowWidth(bounds.width);
    await setWindowHeight(bounds.height);
  }

  Future<void> _loadSettings() async {
    onboardingSeen = _prefs.getBool('onboardingSeen') ?? false;
    windowTop = _prefs.getDouble('window_top');
    windowLeft = _prefs.getDouble('window_left');
    windowWidth = _prefs.getDouble('window_width');
    windowHeight = _prefs.getDouble('window_height');

    brightness =
        Brightness.values[_prefs.getInt('brightness') ?? Brightness.dark.index];
    themeMode =
        ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index];
    // logger.i('settings loaded...');
    // logger.i('brightness: $brightness');
    // logger.i('themeMode: $themeMode');
    // logger.i('window bounds: $windowPlacement');
  }
}
