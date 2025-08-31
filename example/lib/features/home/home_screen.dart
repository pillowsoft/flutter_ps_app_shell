import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final styles = context.adaptiveStyle;

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return Center(
        key: ValueKey('home_center_$uiSystem'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ui.getIcon('auto_fix'),
              size: 80,
              color: styles.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Flutter App Shell',
              style: styles.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Rapid app development made easy',
              style: styles.bodyLarge.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            ui.buttonWithIcon(
              onPressed: () {
                final nav = getIt<NavigationService>();
                nav.go('/dashboard');
              },
              icon: Icon(ui.getIcon('dashboard')),
              label: 'Go to Dashboard',
            ),
            const SizedBox(height: 16),
            ui.outlinedButtonWithIcon(
              onPressed: () {
                final nav = getIt<NavigationService>();
                nav.go('/settings');
              },
              icon: Icon(ui.getIcon('settings')),
              label: 'Configure Settings',
            ),
          ],
        ),
      );
    });
  }
}
