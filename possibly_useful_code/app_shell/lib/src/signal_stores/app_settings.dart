import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

class AppShellSettingsStore {
  final SharedPreferencesWithCache _prefs;

  // Signals for all the settings
  final onboardingSeen = Signal<bool>(false);
  final windowTop = Signal<double?>(null);
  final windowLeft = Signal<double?>(null);
  final windowWidth = Signal<double?>(null);
  final windowHeight = Signal<double?>(null);
  final brightness = Signal<Brightness>(Brightness.dark);
  final themeMode = Signal<ThemeMode>(ThemeMode.system);

  // Computed values
  late final ReadonlySignal<Brightness> effectiveBrightness = computed(() {
    switch (themeMode.value) {
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
    }
  });

  late final ReadonlySignal<Rect> windowPlacement = computed(() {
    if (windowLeft.value != null &&
        windowTop.value != null &&
        windowWidth.value != null &&
        windowHeight.value != null) {
      return Rect.fromLTWH(
        windowLeft.value!,
        windowTop.value!,
        windowWidth.value!,
        windowHeight.value!,
      );
    }
    return const Rect.fromLTWH(0, 0, 800, 600);
  });

  AppShellSettingsStore(this._prefs) {
    _loadSettings();
  }

  Future<void> toggleTheme() async {
    final newBrightness = brightness.value == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    await setBrightness(newBrightness);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode.value = value;
    await _prefs.setInt('themeMode', value.index);
    // Update brightness based on theme mode
    if (value != ThemeMode.system) {
      await setBrightness(
          value == ThemeMode.dark ? Brightness.dark : Brightness.light);
    }
  }

  Future<void> _setNullableValue<T>(
      String key, T? value, Future<void> Function(String, T) setter) async {
    if (value != null) {
      await setter(key, value);
    } else {
      await _prefs.remove(key);
    }
  }

  Future<void> setOnboardingSeen(bool value) async {
    onboardingSeen.value = value;
    await _prefs.setBool('onboardingSeen', value);
  }

  Future<void> setWindowTop(double? value) async {
    windowTop.value = value;
    await _setNullableValue('window_top', value, _prefs.setDouble);
  }

  Future<void> setWindowLeft(double? value) async {
    windowLeft.value = value;
    await _setNullableValue('window_left', value, _prefs.setDouble);
  }

  Future<void> setWindowWidth(double? value) async {
    windowWidth.value = value;
    await _setNullableValue('window_width', value, _prefs.setDouble);
  }

  Future<void> setWindowHeight(double? value) async {
    windowHeight.value = value;
    await _setNullableValue('window_height', value, _prefs.setDouble);
  }

  Future<void> setBrightness(Brightness value) async {
    brightness.value = value;
    await _prefs.setInt('brightness', value.index);
  }

  Future<void> saveWindowBounds(Rect bounds) async {
    await setWindowLeft(bounds.left);
    await setWindowTop(bounds.top);
    await setWindowWidth(bounds.width);
    await setWindowHeight(bounds.height);
  }

  Future<void> _loadSettings() async {
    onboardingSeen.value = _prefs.getBool('onboardingSeen') ?? false;
    windowTop.value = _prefs.getDouble('window_top');
    windowLeft.value = _prefs.getDouble('window_left');
    windowWidth.value = _prefs.getDouble('window_width');
    windowHeight.value = _prefs.getDouble('window_height');

    brightness.value =
        Brightness.values[_prefs.getInt('brightness') ?? Brightness.dark.index];
    themeMode.value =
        ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.system.index];
  }
}

// // Usage example in a widget:
// class SettingsWidget extends StatelessWidget {
//   final AppShellSettingsStore settings;

//   const SettingsWidget({super.key, required this.settings});

//   @override
//   Widget build(BuildContext context) {
//     return Watch((context) {
//       return Column(
//         children: [
//           // Theme toggle
//           SwitchListTile(
//             title: const Text('Dark Mode'),
//             value: settings.brightness.value == Brightness.dark,
//             onChanged: (value) => settings.toggleTheme(),
//           ),

//           // Theme mode selector
//           DropdownButton<ThemeMode>(
//             value: settings.themeMode.value,
//             onChanged: (value) {
//               if (value != null) settings.setThemeMode(value);
//             },
//             items: ThemeMode.values
//                 .map((mode) => DropdownMenuItem(
//                       value: mode,
//                       child: Text(mode.toString().split('.').last),
//                     ))
//                 .toList(),
//           ),

//           // Window placement info
//           Text('Window Position: ${settings.windowPlacement.value}'),

//           // Effective brightness display
//           Text('Current Theme: ${settings.effectiveBrightness.value}'),
//         ],
//       );
//     });
//   }
// }
