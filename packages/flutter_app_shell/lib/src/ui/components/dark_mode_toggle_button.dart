import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import '../../state/app_shell_settings_store.dart';

class DarkModeToggleButton extends StatelessWidget {
  const DarkModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();

    return Watch(
      (context) {
        // Use getCurrentBrightness to account for system mode
        final currentBrightness = settingsStore.getCurrentBrightness(context);
        final isDarkMode = currentBrightness == Brightness.dark;

        return IconButton(
          onPressed: () {
            // Toggle between light and dark theme modes
            settingsStore.setThemeMode(
              isDarkMode ? ThemeMode.light : ThemeMode.dark,
            );
          },
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 20,
          ),
        );
      },
    );
  }
}
