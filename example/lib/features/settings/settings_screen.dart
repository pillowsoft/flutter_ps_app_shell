import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to use as key for forcing rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);
      return ListView(
        key: ValueKey('settings_list_$uiSystem'),
        padding: const EdgeInsets.all(16),
        children: [
          ui.pageTitle('Settings'),
          const SizedBox(height: 24),

          // Appearance Section
          ui.listSection(
            header: const Text('Appearance'),
            children: [
              Watch((context) {
                final themeMode = settingsStore.themeMode.value;
                return ui.listTile(
                  leading: Icon(ui.getIcon('palette')),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeText(themeMode)),
                  trailing: Icon(ui.getIcon('chevron_right')),
                  onTap: () => _showThemeModeDialog(context, settingsStore),
                );
              }),
              Watch((context) {
                final uiSystem = settingsStore.uiSystem.value;
                return ui.listTile(
                  leading: Icon(ui.getIcon('settings')),
                  title: const Text('UI System'),
                  subtitle: Text(_getUiSystemText(uiSystem)),
                  trailing: Icon(ui.getIcon('chevron_right')),
                  onTap: () => _showUiSystemDialog(context, settingsStore),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Navigation Section
          ui.listSection(
            header: const Text('Navigation'),
            children: [
              Watch((context) {
                final showLabels = settingsStore.showNavigationLabels.value;
                return ui.listTile(
                  leading: Icon(ui.getIcon('folder')),
                  title: const Text('Show Navigation Labels'),
                  subtitle: const Text('Display labels in navigation rail'),
                  trailing: ui.switch_(
                    value: showLabels,
                    onChanged: (value) {
                      settingsStore.showNavigationLabels.value = value;
                    },
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Window Section (Desktop only)
          if (!kIsWeb &&
              (Platform.isMacOS || Platform.isWindows || Platform.isLinux))
            _buildWindowSection(context, ui),

          if (!kIsWeb &&
              (Platform.isMacOS || Platform.isWindows || Platform.isLinux))
            const SizedBox(height: 24),

          // Developer Section
          ui.listSection(
            header: const Text('Developer'),
            children: [
              Watch((context) {
                final debugMode = settingsStore.debugMode.value;
                return ui.listTile(
                  leading: Icon(ui.getIcon('settings')),
                  title: const Text('Debug Mode'),
                  subtitle: const Text('Enable debug features and logging'),
                  trailing: ui.switch_(
                    value: debugMode,
                    onChanged: (value) {
                      settingsStore.debugMode.value = value;
                    },
                  ),
                );
              }),
              Watch((context) {
                final logLevel = settingsStore.logLevel.value;
                return ui.listTile(
                  leading: Icon(ui.getIcon('settings')),
                  title: const Text('Log Level'),
                  subtitle: Text(logLevel.toUpperCase()),
                  trailing: Icon(ui.getIcon('chevron_right')),
                  onTap: () => _showLogLevelDialog(context, settingsStore),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          ui.button(
            label: 'Reset to Defaults',
            onPressed: () {
              settingsStore.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  // Removed _buildPageTitle - now using ui.pageTitle() helper

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getUiSystemText(String system) {
    switch (system) {
      case 'material':
        return 'Material Design';
      case 'cupertino':
        return 'Cupertino (iOS)';
      case 'forui':
        return 'ForUI';
      default:
        return 'Material Design';
    }
  }

  void _showThemeModeDialog(BuildContext context, AppShellSettingsStore store) {
    // Get the factory fresh each time dialog is shown
    final ui = getAdaptiveFactory(context);
    ui.showDialog(
      context: context,
      title: const Text('Theme Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeMode.values.map((mode) {
          return ui.radioListTile<ThemeMode>(
            title: Text(_getThemeModeText(mode)),
            value: mode,
            groupValue: store.themeMode.value,
            onChanged: (value) {
              if (value != null) {
                store.setThemeMode(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _showUiSystemDialog(BuildContext context, AppShellSettingsStore store) {
    // Get the factory fresh each time dialog is shown
    final ui = getAdaptiveFactory(context);
    ui.showDialog(
      context: context,
      title: const Text('UI System'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ui.radioListTile<String>(
            title: const Text('Material Design'),
            value: 'material',
            groupValue: store.uiSystem.value,
            onChanged: (value) {
              if (value != null) {
                // Change UI system immediately, then close dialog
                store.setUiSystem(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
          ui.radioListTile<String>(
            title: const Text('Cupertino (iOS)'),
            value: 'cupertino',
            groupValue: store.uiSystem.value,
            onChanged: (value) {
              if (value != null) {
                // Change UI system immediately, then close dialog
                store.setUiSystem(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
          ui.radioListTile<String>(
            title: const Text('ForUI'),
            subtitle: const Text('Modern design system'),
            value: 'forui',
            groupValue: store.uiSystem.value,
            onChanged: (value) {
              if (value != null) {
                // Change UI system immediately, then close dialog
                store.setUiSystem(value);
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
        ],
      ),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _showLogLevelDialog(BuildContext context, AppShellSettingsStore store) {
    final levels = ['debug', 'info', 'warning', 'error'];
    // Get the factory fresh each time dialog is shown
    final ui = getAdaptiveFactory(context);
    ui.showDialog(
      context: context,
      title: const Text('Log Level'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: levels.map((level) {
          return ui.radioListTile<String>(
            title: Text(level.toUpperCase()),
            value: level,
            groupValue: store.logLevel.value,
            onChanged: (value) {
              if (value != null) {
                store.logLevel.value = value;
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  Widget _buildWindowSection(BuildContext context, AdaptiveWidgetFactory ui) {
    return ui.listSection(
      header: const Text('Window'),
      children: [
        Watch((context) {
          try {
            final windowStateService = getIt<WindowStateService>();
            final rememberState = windowStateService.rememberWindowState.value;
            return ui.listTile(
              leading: Icon(ui.getIcon('settings')),
              title: const Text('Remember Window State'),
              subtitle:
                  const Text('Restore window position and size on startup'),
              trailing: ui.switch_(
                value: rememberState,
                onChanged: (value) async {
                  await windowStateService.updateSettings(rememberState: value);
                },
              ),
            );
          } catch (e) {
            return ui.listTile(
              leading: Icon(ui.getIcon('settings')),
              title: const Text('Remember Window State'),
              subtitle: const Text('Window service not available'),
              trailing: ui.switch_(
                value: false,
                onChanged: (value) {},
              ),
            );
          }
        }),
        Watch((context) {
          try {
            final windowStateService = getIt<WindowStateService>();
            final startMaximized = windowStateService.startMaximized.value;
            return ui.listTile(
              leading: Icon(ui.getIcon('settings')),
              title: const Text('Start Maximized'),
              subtitle: const Text('Always start with maximized window'),
              trailing: ui.switch_(
                value: startMaximized,
                onChanged: (value) async {
                  await windowStateService.updateSettings(
                      startMaximizedValue: value);
                },
              ),
            );
          } catch (e) {
            return ui.listTile(
              leading: Icon(ui.getIcon('settings')),
              title: const Text('Start Maximized'),
              subtitle: const Text('Window service not available'),
              trailing: ui.switch_(
                value: false,
                onChanged: (value) {},
              ),
            );
          }
        }),
        ui.listTile(
          leading: Icon(ui.getIcon('settings')),
          title: const Text('Reset Window Position'),
          subtitle: const Text('Center window with default size'),
          trailing: Icon(ui.getIcon('chevron_right')),
          onTap: () async {
            try {
              final windowStateService = getIt<WindowStateService>();
              await windowStateService.resetWindowPosition();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Window position reset'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Window service not available'),
                ),
              );
            }
          },
        ),
        ui.listTile(
          leading: Icon(ui.getIcon('settings')),
          title: const Text('Test Save Window State'),
          subtitle: const Text('Manually save current window state'),
          trailing: Icon(ui.getIcon('chevron_right')),
          onTap: () async {
            try {
              final windowStateService = getIt<WindowStateService>();
              await windowStateService.testSaveCurrentState();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Window state saved manually'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Save failed - check logs'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
