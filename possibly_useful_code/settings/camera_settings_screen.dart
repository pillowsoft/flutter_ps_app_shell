import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/di/service_locator.dart';
import '../../services/settings_service.dart';
import '../../services/camera/camera_interface.dart' as camera;
import '../../ui/adaptive/adaptive_widgets.dart';

class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  late camera.CameraSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = const camera.CameraSettings(); // Default settings
  }

  void _updateSettings(
      camera.CameraSettings Function(camera.CameraSettings) update) {
    setState(() {
      _settings = update(_settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final settingsService = getIt<SettingsService>();
    final platformStyle = settingsService.platformStyle.value;

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
        middle: const Text('Camera'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resolution
              ui.listSection(
                header: const Text('Resolution'),
                children: camera.CameraResolution.values.map((resolution) {
                  final name = resolution.name;
                  final displayName = name[0].toUpperCase() + name.substring(1);
                  final description = _getResolutionDescription(resolution);
                  final isSelected = _settings.resolution == resolution;

                  return ui.listTile(
                    title: Text(displayName),
                    subtitle: Text(description),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.check_mark,
                            color: CupertinoColors.systemBlue)
                        : null,
                    onTap: () {
                      _updateSettings((s) => s.copyWith(
                            resolution: resolution,
                          ));
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Recording Quality
              ui.listSection(
                header: const Text('Recording Quality'),
                children: [
                  ui.listTile(
                    title: const Text('High Quality'),
                    subtitle: const Text('Better quality, larger file size'),
                    trailing: ui.switch_(
                      value: _settings.resolution ==
                          camera.CameraResolution.veryHigh,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              resolution: value
                                  ? camera.CameraResolution.veryHigh
                                  : camera.CameraResolution.high,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Frame Rate'),
                    subtitle: const Text('30 fps'),
                    trailing: Text(
                      '30 fps',
                      style: TextStyle(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Camera Features
              ui.listSection(
                header: const Text('Camera Features'),
                children: [
                  ui.listTile(
                    title: const Text('Stabilization'),
                    subtitle: const Text('Reduce camera shake'),
                    trailing: ui.switch_(
                      value: _settings.stabilizationEnabled,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              stabilizationEnabled: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Auto Focus'),
                    subtitle: const Text('Continuous autofocus'),
                    trailing: ui.switch_(
                      value: _settings.autoFocus,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              autoFocus: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('HDR'),
                    subtitle: const Text('High dynamic range (if available)'),
                    trailing: ui.switch_(
                      value: false, // HDR not implemented yet
                      onChanged: (value) {
                        // HDR not implemented yet
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Low Light Enhancement'),
                    subtitle: const Text('Improve visibility in dark scenes'),
                    trailing: ui.switch_(
                      value: false, // Low light enhancement not implemented yet
                      onChanged: (value) {
                        // Low light enhancement not implemented yet
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Default Camera
              ui.listSection(
                header: const Text('Default Camera'),
                children: [
                  ui.listTile(
                    title: const Text('Back Camera'),
                    subtitle: const Text('Main camera (default)'),
                    trailing: const Icon(CupertinoIcons.check_mark,
                        color: CupertinoColors.systemGreen),
                  ),
                  ui.listTile(
                    title: const Text('Front Camera'),
                    subtitle: const Text('Selfie camera'),
                    trailing: const Icon(CupertinoIcons.info),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Composition Guides
              ui.listSection(
                header: const Text('Composition Guides'),
                children: [
                  ui.listTile(
                    title: const Text('Grid'),
                    subtitle: const Text('Rule of thirds grid'),
                    trailing: ui.switch_(
                      value: false, // Grid not implemented yet
                      onChanged: (value) {
                        // Grid not implemented yet
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Level Indicator'),
                    subtitle: const Text('Show if camera is level'),
                    trailing: ui.switch_(
                      value: false, // Level indicator not implemented yet
                      onChanged: (value) {
                        // Level indicator not implemented yet
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
        title: const Text('Camera Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resolution
            _buildMaterialSection(
              'Resolution',
              Column(
                children: camera.CameraResolution.values.map((resolution) {
                  final name = resolution.name;
                  final displayName = name[0].toUpperCase() + name.substring(1);

                  return RadioListTile<camera.CameraResolution>(
                    title: Text(displayName),
                    subtitle: Text(_getResolutionDescription(resolution)),
                    value: resolution,
                    groupValue: _settings.resolution,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            resolution: value,
                          ));
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Quality
            _buildMaterialSection(
              'Recording Quality',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('High Quality'),
                    subtitle: const Text('Better quality, larger file size'),
                    value: _settings.resolution ==
                        camera.CameraResolution.veryHigh,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            resolution: value
                                ? camera.CameraResolution.veryHigh
                                : camera.CameraResolution.high,
                          ));
                    },
                  ),
                  ListTile(
                    title: const Text('Frame Rate'),
                    subtitle: const Text('30 fps'), // Fixed FPS for now
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: 30.0, // Fixed FPS for now
                        min: 24,
                        max: 60,
                        divisions: 3,
                        label: '30 fps', // Fixed FPS for now
                        onChanged: null, // FPS adjustment disabled for now
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features
            _buildMaterialSection(
              'Camera Features',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Stabilization'),
                    subtitle: const Text('Reduce camera shake'),
                    value: _settings.stabilizationEnabled,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            stabilizationEnabled: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto Focus'),
                    subtitle: const Text('Continuous autofocus'),
                    value: _settings.autoFocus,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            autoFocus: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('HDR'),
                    subtitle: const Text('High dynamic range (if available)'),
                    value: false, // HDR not implemented yet
                    onChanged: (value) {
                      // HDR not implemented yet
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Low Light Enhancement'),
                    subtitle: const Text('Improve visibility in dark scenes'),
                    value: false, // Low light enhancement not implemented yet
                    onChanged: (value) {
                      // Low light enhancement not implemented yet
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Default Camera
            _buildMaterialSection(
              'Default Camera',
              Column(
                children: [
                  const ListTile(
                    title: Text('Back Camera'),
                    subtitle: Text('Main camera (default)'),
                    trailing: Icon(Icons.check, color: Colors.green),
                  ),
                  const ListTile(
                    title: Text('Front Camera'),
                    subtitle: Text('Selfie camera'),
                    trailing: Icon(Icons.info_outline),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grid & Guides
            _buildMaterialSection(
              'Composition Guides',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Grid'),
                    subtitle: const Text('Rule of thirds grid'),
                    value: false, // Grid not implemented yet
                    onChanged: (value) {
                      // Grid not implemented yet
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Level Indicator'),
                    subtitle: const Text('Show if camera is level'),
                    value: false, // Level indicator not implemented yet
                    onChanged: (value) {
                      // Level indicator not implemented yet
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

  Widget _buildMaterialSection(String title, Widget content) {
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
        content,
      ],
    );
  }

  String _getResolutionDescription(camera.CameraResolution resolution) {
    switch (resolution) {
      case camera.CameraResolution.low:
        return '480p - Smallest file size';
      case camera.CameraResolution.medium:
        return '720p - Good balance';
      case camera.CameraResolution.high:
        return '1080p - High quality';
      case camera.CameraResolution.veryHigh:
        return '4K - Best quality (if available)';
    }
  }
}
