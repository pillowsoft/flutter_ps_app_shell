import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/di/service_locator.dart';
import '../../services/settings_service.dart';
import '../../ui/adaptive/adaptive_widgets.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late final SettingsService _settingsService;
  late PrivacySettings _settings;

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<SettingsService>();
    _settings = _settingsService.privacySettings.value;
  }

  void _updateSettings(PrivacySettings Function(PrivacySettings) update) {
    setState(() {
      _settings = update(_settings);
    });
    _settingsService.updatePrivacySettings(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final platformStyle = _settingsService.platformStyle.value;

    // Determine if we should use iOS styling
    final bool useIOSStyling = platformStyle == 'cupertino' ||
        (platformStyle == 'adaptive' &&
            (Theme.of(context).platform == TargetPlatform.iOS ||
                Theme.of(context).platform == TargetPlatform.macOS));

    if (useIOSStyling) {
      return _buildCupertinoScreen(context, ui);
    } else {
      return _buildMaterialScreen(context, ui);
    }
  }

  Widget _buildCupertinoScreen(BuildContext context, AdaptiveWidgetFactory ui) {
    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: const Text('Privacy'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              ui.listSection(
                header: const Text('Location'),
                children: [
                  ui.listTile(
                    title: const Text('Save Location Data'),
                    subtitle: const Text('Store GPS coordinates with videos'),
                    trailing: ui.switch_(
                      value: _settings.saveLocationData,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              saveLocationData: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('High Accuracy'),
                    subtitle:
                        const Text('Use precise location (uses more battery)'),
                    trailing: ui.switch_(
                      value: _settings.useHighAccuracyLocation,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              useHighAccuracyLocation: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Share Location in Metadata'),
                    subtitle:
                        const Text('Include location when sharing videos'),
                    trailing: ui.switch_(
                      value: _settings.shareLocationInMetadata,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              shareLocationInMetadata: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Analytics & Diagnostics
              ui.listSection(
                header: const Text('Analytics & Diagnostics'),
                children: [
                  ui.listTile(
                    title: const Text('Usage Analytics'),
                    subtitle:
                        const Text('Help improve the app with anonymous data'),
                    trailing: ui.switch_(
                      value: _settings.enableAnalytics,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              enableAnalytics: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Crash Reports'),
                    subtitle: const Text('Automatically send crash logs'),
                    trailing: ui.switch_(
                      value: _settings.sendCrashReports,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              sendCrashReports: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Performance Monitoring'),
                    subtitle: const Text('Track app performance metrics'),
                    trailing: ui.switch_(
                      value: _settings.enablePerformanceMonitoring,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              enablePerformanceMonitoring: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Data Retention
              ui.listSection(
                header: const Text('Data Retention'),
                children: [
                  ui.listTile(
                    title: const Text('Auto-delete Old Videos'),
                    subtitle: Text(_settings.autoDeleteAfterDays > 0
                        ? 'Delete after ${_settings.autoDeleteAfterDays} days'
                        : 'Never delete automatically'),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () {
                      _showRetentionPicker(context, ui);
                    },
                  ),
                  ui.listTile(
                    title: const Text('Delete Metadata with Video'),
                    subtitle:
                        const Text('Remove all associated data when deleting'),
                    trailing: ui.switch_(
                      value: _settings.deleteMetadataWithVideo,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              deleteMetadataWithVideo: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Collaboration
              ui.listSection(
                header: const Text('Collaboration'),
                children: [
                  ui.listTile(
                    title: const Text('Share Device Name'),
                    subtitle:
                        const Text('Show your device name to collaborators'),
                    trailing: ui.switch_(
                      value: _settings.shareDeviceName,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              shareDeviceName: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Allow Anonymous Join'),
                    subtitle: const Text(
                        'Let users join sessions without signing in'),
                    trailing: ui.switch_(
                      value: _settings.allowAnonymousJoin,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              allowAnonymousJoin: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialScreen(BuildContext context, AdaptiveWidgetFactory ui) {
    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('Privacy Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            _buildMaterialSection(
              'Location',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Save Location Data'),
                    subtitle: const Text('Store GPS coordinates with videos'),
                    value: _settings.saveLocationData,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            saveLocationData: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('High Accuracy'),
                    subtitle:
                        const Text('Use precise location (uses more battery)'),
                    value: _settings.useHighAccuracyLocation,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            useHighAccuracyLocation: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Share Location in Metadata'),
                    subtitle:
                        const Text('Include location when sharing videos'),
                    value: _settings.shareLocationInMetadata,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            shareLocationInMetadata: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Analytics & Diagnostics
            _buildMaterialSection(
              'Analytics & Diagnostics',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Usage Analytics'),
                    subtitle:
                        const Text('Help improve the app with anonymous data'),
                    value: _settings.enableAnalytics,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            enableAnalytics: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Crash Reports'),
                    subtitle: const Text('Automatically send crash logs'),
                    value: _settings.sendCrashReports,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            sendCrashReports: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Performance Monitoring'),
                    subtitle: const Text('Track app performance metrics'),
                    value: _settings.enablePerformanceMonitoring,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            enablePerformanceMonitoring: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data Retention
            _buildMaterialSection(
              'Data Retention',
              Column(
                children: [
                  ListTile(
                    title: const Text('Auto-delete Old Videos'),
                    subtitle: Text(_settings.autoDeleteAfterDays > 0
                        ? 'Delete after ${_settings.autoDeleteAfterDays} days'
                        : 'Never delete automatically'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showRetentionPicker(context, ui);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Delete Metadata with Video'),
                    subtitle:
                        const Text('Remove all associated data when deleting'),
                    value: _settings.deleteMetadataWithVideo,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            deleteMetadataWithVideo: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Collaboration
            _buildMaterialSection(
              'Collaboration',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Share Device Name'),
                    subtitle:
                        const Text('Show your device name to collaborators'),
                    value: _settings.shareDeviceName,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            shareDeviceName: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Allow Anonymous Join'),
                    subtitle: const Text(
                        'Let users join sessions without signing in'),
                    value: _settings.allowAnonymousJoin,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            allowAnonymousJoin: value,
                          ));
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

  Widget _buildMaterialSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _showRetentionPicker(BuildContext context, AdaptiveWidgetFactory ui) {
    final options = [0, 7, 30, 90, 365]; // 0 = never, others = days

    ui.showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto-delete Videos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ui.listSection(
                children: options.map((days) {
                  final title = days == 0 ? 'Never' : 'After $days days';
                  final isSelected = _settings.autoDeleteAfterDays == days;

                  return ui.listTile(
                    title: Text(title),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () {
                      _updateSettings((s) => s.copyWith(
                            autoDeleteAfterDays: days,
                          ));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
