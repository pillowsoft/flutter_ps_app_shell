import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals/signals_flutter.dart';
import 'package:flutter_vizi_camera_app/core/di/service_locator.dart';
import 'package:flutter_vizi_camera_app/managers/settings_manager.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsManager = getIt<SettingsManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Recording Settings
            _buildSectionHeader('Recording'),
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Watch((context) {
                    final videoQuality =
                        settingsManager.getSetting('video_quality', 'high');

                    return ListTile(
                      leading: const Icon(Icons.video_settings),
                      title: const Text('Video Quality'),
                      subtitle: Text(_getVideoQualityText(videoQuality)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showVideoQualityDialog(context, settingsManager),
                    );
                  }),
                  const Divider(),
                  Watch((context) {
                    final audioEnabled =
                        settingsManager.getSetting('audio_enabled', true);

                    return SwitchListTile(
                      secondary: const Icon(Icons.mic),
                      title: const Text('Audio Recording'),
                      subtitle: const Text('Record audio with video'),
                      value: audioEnabled,
                      onChanged: (value) {
                        settingsManager.updateSetting('audio_enabled', value);
                      },
                    );
                  }),
                  const Divider(),
                  Watch((context) {
                    final stabilization =
                        settingsManager.getSetting('stabilization', 'standard');

                    return ListTile(
                      leading: const Icon(Icons.center_focus_weak),
                      title: const Text('Stabilization'),
                      subtitle: Text(_getStabilizationText(stabilization)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showStabilizationDialog(context, settingsManager),
                    );
                  }),
                ],
              ),
            ),

            // Camera Settings
            _buildSectionHeader('Camera'),
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Watch((context) {
                    final flashEnabled =
                        settingsManager.getSetting('flash_enabled', false);

                    return SwitchListTile(
                      secondary: const Icon(Icons.flash_on),
                      title: const Text('Flash'),
                      subtitle: const Text('Enable flash by default'),
                      value: flashEnabled,
                      onChanged: (value) {
                        settingsManager.updateSetting('flash_enabled', value);
                      },
                    );
                  }),
                  const Divider(),
                  Watch((context) {
                    final gridEnabled =
                        settingsManager.getSetting('grid_enabled', true);

                    return SwitchListTile(
                      secondary: const Icon(Icons.grid_on),
                      title: const Text('Grid Lines'),
                      subtitle: const Text('Show composition grid'),
                      value: gridEnabled,
                      onChanged: (value) {
                        settingsManager.updateSetting('grid_enabled', value);
                      },
                    );
                  }),
                ],
              ),
            ),

            // App Settings
            _buildSectionHeader('App'),
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage notification settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open notification settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Storage'),
                    subtitle: const Text('Manage storage and cache'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open storage settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy'),
                    subtitle: const Text('Privacy and data settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open privacy settings
                    },
                  ),
                ],
              ),
            ),

            // About
            _buildSectionHeader('About'),
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open help
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open terms
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getVideoQualityText(String quality) {
    switch (quality) {
      case 'low':
        return '720p';
      case 'medium':
        return '1080p';
      case 'high':
        return '4K';
      default:
        return '1080p';
    }
  }

  String _getStabilizationText(String stabilization) {
    switch (stabilization) {
      case 'off':
        return 'Off';
      case 'standard':
        return 'Standard';
      case 'cinematic':
        return 'Cinematic';
      default:
        return 'Standard';
    }
  }

  void _showVideoQualityDialog(
      BuildContext context, SettingsManager settingsManager) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Video Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('720p'),
                value: 'low',
                groupValue: settingsManager.getSetting('video_quality', 'high'),
                onChanged: (value) {
                  settingsManager.updateSetting('video_quality', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('1080p'),
                value: 'medium',
                groupValue: settingsManager.getSetting('video_quality', 'high'),
                onChanged: (value) {
                  settingsManager.updateSetting('video_quality', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('4K'),
                value: 'high',
                groupValue: settingsManager.getSetting('video_quality', 'high'),
                onChanged: (value) {
                  settingsManager.updateSetting('video_quality', value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStabilizationDialog(
      BuildContext context, SettingsManager settingsManager) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stabilization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Off'),
                value: 'off',
                groupValue:
                    settingsManager.getSetting('stabilization', 'standard'),
                onChanged: (value) {
                  settingsManager.updateSetting('stabilization', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Standard'),
                value: 'standard',
                groupValue:
                    settingsManager.getSetting('stabilization', 'standard'),
                onChanged: (value) {
                  settingsManager.updateSetting('stabilization', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Cinematic'),
                value: 'cinematic',
                groupValue:
                    settingsManager.getSetting('stabilization', 'standard'),
                onChanged: (value) {
                  settingsManager.updateSetting('stabilization', value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
