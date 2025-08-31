import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/di/service_locator.dart';
import '../../services/settings_service.dart';
import '../../ui/adaptive/adaptive_widgets.dart';

class RecordingSettingsScreen extends StatefulWidget {
  const RecordingSettingsScreen({super.key});

  @override
  State<RecordingSettingsScreen> createState() =>
      _RecordingSettingsScreenState();
}

class _RecordingSettingsScreenState extends State<RecordingSettingsScreen> {
  late final SettingsService _settingsService;
  late RecordingSettings _settings;

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<SettingsService>();
    _settings = _settingsService.recordingSettings.value;
  }

  void _updateSettings(RecordingSettings Function(RecordingSettings) update) {
    setState(() {
      _settings = update(_settings);
    });
    _settingsService.updateRecordingSettings(_settings);
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
        middle: const Text('Recording'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration Limits
              ui.listSection(
                header: const Text('Duration Limits'),
                children: [
                  ui.listTile(
                    title: const Text('Maximum Duration'),
                    subtitle: Text(_formatDuration(_settings.maxDuration)),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () => _showMaxDurationPicker(context, ui),
                  ),
                  ui.listTile(
                    title: const Text('Auto-stop at Limit'),
                    subtitle: const Text(
                        'Automatically stop recording at max duration'),
                    trailing: ui.switch_(
                      value: _settings.autoStopAtMaxDuration,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              autoStopAtMaxDuration: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recording Options
              ui.listSection(
                header: const Text('Recording Options'),
                children: [
                  ui.listTile(
                    title: const Text('Countdown Timer'),
                    subtitle: Text(_settings.countdownSeconds == 0
                        ? 'Off'
                        : '${_settings.countdownSeconds} seconds'),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () => _showCountdownPicker(context, ui),
                  ),
                  ui.listTile(
                    title: const Text('Auto-save'),
                    subtitle: const Text('Save recordings automatically'),
                    trailing: ui.switch_(
                      value: _settings.autoSave,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              autoSave: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Keep Screen On'),
                    subtitle:
                        const Text('Prevent screen timeout while recording'),
                    trailing: ui.switch_(
                      value: _settings.keepScreenOn,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              keepScreenOn: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Audio Settings
              ui.listSection(
                header: const Text('Audio'),
                children: [
                  ui.listTile(
                    title: const Text('Record Audio'),
                    subtitle: const Text('Include audio in recordings'),
                    trailing: ui.switch_(
                      value: _settings.recordAudio,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              recordAudio: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  if (_settings.recordAudio) ...[
                    ui.listTile(
                      title: const Text('Use External Microphone'),
                      subtitle: const Text('When available'),
                      trailing: ui.switch_(
                        value: _settings.useExternalMicrophone,
                        onChanged: (value) {
                          _updateSettings((s) => s.copyWith(
                                useExternalMicrophone: value,
                              ));
                        },
                        activeColor: CupertinoColors.systemBlue,
                      ),
                    ),
                    ui.listTile(
                      title: const Text('Audio Level Monitoring'),
                      subtitle: const Text('Show audio levels while recording'),
                      trailing: ui.switch_(
                        value: _settings.showAudioLevels,
                        onChanged: (value) {
                          _updateSettings((s) => s.copyWith(
                                showAudioLevels: value,
                              ));
                        },
                        activeColor: CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // File Management
              ui.listSection(
                header: const Text('File Management'),
                children: [
                  ui.listTile(
                    title: const Text('File Naming'),
                    subtitle:
                        Text(_getFileNamingText(_settings.fileNamingPattern)),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () => _showFileNamingPicker(context, ui),
                  ),
                  ui.listTile(
                    title: const Text('Generate Thumbnails'),
                    subtitle: const Text('Create preview images for videos'),
                    trailing: ui.switch_(
                      value: _settings.generateThumbnails,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              generateThumbnails: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Save to Camera Roll'),
                    subtitle: const Text('Also save to device photo library'),
                    trailing: ui.switch_(
                      value: _settings.saveToCameraRoll,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              saveToCameraRoll: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quality Monitoring
              ui.listSection(
                header: const Text('Quality Monitoring'),
                children: [
                  ui.listTile(
                    title: const Text('Motion Detection'),
                    subtitle: const Text('Monitor device stability'),
                    trailing: ui.switch_(
                      value: _settings.enableMotionDetection,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              enableMotionDetection: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Scene Analysis'),
                    subtitle: const Text('Analyze video content in real-time'),
                    trailing: ui.switch_(
                      value: _settings.enableSceneAnalysis,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              enableSceneAnalysis: value,
                            ));
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  ui.listTile(
                    title: const Text('Quality Warnings'),
                    subtitle: const Text('Alert when quality is poor'),
                    trailing: ui.switch_(
                      value: _settings.showQualityWarnings,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              showQualityWarnings: value,
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
        title: const Text('Recording Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration Limits
            _buildMaterialSection(
              'Duration Limits',
              Column(
                children: [
                  ListTile(
                    title: const Text('Maximum Duration'),
                    subtitle: Text(_formatDuration(_settings.maxDuration)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showMaxDurationPicker(context, ui),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-stop at Limit'),
                    subtitle: const Text(
                        'Automatically stop recording at max duration'),
                    value: _settings.autoStopAtMaxDuration,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            autoStopAtMaxDuration: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recording Options
            _buildMaterialSection(
              'Recording Options',
              Column(
                children: [
                  ListTile(
                    title: const Text('Countdown Timer'),
                    subtitle: Text(_settings.countdownSeconds == 0
                        ? 'Off'
                        : '${_settings.countdownSeconds} seconds'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCountdownPicker(context, ui),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-save'),
                    subtitle: const Text('Save recordings automatically'),
                    value: _settings.autoSave,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            autoSave: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Keep Screen On'),
                    subtitle:
                        const Text('Prevent screen timeout while recording'),
                    value: _settings.keepScreenOn,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            keepScreenOn: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Audio Settings
            _buildMaterialSection(
              'Audio',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Record Audio'),
                    subtitle: const Text('Include audio in recordings'),
                    value: _settings.recordAudio,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            recordAudio: value,
                          ));
                    },
                  ),
                  if (_settings.recordAudio) ...[
                    SwitchListTile(
                      title: const Text('Use External Microphone'),
                      subtitle: const Text('When available'),
                      value: _settings.useExternalMicrophone,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              useExternalMicrophone: value,
                            ));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Audio Level Monitoring'),
                      subtitle: const Text('Show audio levels while recording'),
                      value: _settings.showAudioLevels,
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(
                              showAudioLevels: value,
                            ));
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // File Management
            _buildMaterialSection(
              'File Management',
              Column(
                children: [
                  ListTile(
                    title: const Text('File Naming'),
                    subtitle:
                        Text(_getFileNamingText(_settings.fileNamingPattern)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFileNamingPicker(context, ui),
                  ),
                  SwitchListTile(
                    title: const Text('Generate Thumbnails'),
                    subtitle: const Text('Create preview images for videos'),
                    value: _settings.generateThumbnails,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            generateThumbnails: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Save to Camera Roll'),
                    subtitle: const Text('Also save to device photo library'),
                    value: _settings.saveToCameraRoll,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            saveToCameraRoll: value,
                          ));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quality Monitoring
            _buildMaterialSection(
              'Quality Monitoring',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Motion Detection'),
                    subtitle: const Text('Monitor device stability'),
                    value: _settings.enableMotionDetection,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            enableMotionDetection: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Scene Analysis'),
                    subtitle: const Text('Analyze video content in real-time'),
                    value: _settings.enableSceneAnalysis,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            enableSceneAnalysis: value,
                          ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Quality Warnings'),
                    subtitle: const Text('Alert when quality is poor'),
                    value: _settings.showQualityWarnings,
                    onChanged: (value) {
                      _updateSettings((s) => s.copyWith(
                            showQualityWarnings: value,
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (seconds == 0) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getFileNamingText(String pattern) {
    switch (pattern) {
      case 'datetime':
        return 'Date & Time';
      case 'project_date':
        return 'Project & Date';
      case 'sequential':
        return 'Sequential';
      default:
        return 'Date & Time';
    }
  }

  void _showMaxDurationPicker(BuildContext context, AdaptiveWidgetFactory ui) {
    final options = [1, 5, 10, 15, 30]; // minutes

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
                'Maximum Duration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ui.listSection(
                children: options.map((minutes) {
                  final duration = Duration(minutes: minutes);
                  final isSelected = _settings.maxDuration == duration;

                  return ui.listTile(
                    title: Text('$minutes minutes'),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () {
                      _updateSettings((s) => s.copyWith(
                            maxDuration: duration,
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

  void _showCountdownPicker(BuildContext context, AdaptiveWidgetFactory ui) {
    final options = [0, 3, 5, 10]; // seconds

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
                'Countdown Timer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ui.listSection(
                children: options.map((seconds) {
                  final title = seconds == 0 ? 'Off' : '$seconds seconds';
                  final isSelected = _settings.countdownSeconds == seconds;

                  return ui.listTile(
                    title: Text(title),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () {
                      _updateSettings((s) => s.copyWith(
                            countdownSeconds: seconds,
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

  void _showFileNamingPicker(BuildContext context, AdaptiveWidgetFactory ui) {
    final options = [
      {
        'value': 'datetime',
        'title': 'Date & Time',
        'subtitle': 'e.g., 2024_01_15_143052.mp4'
      },
      {
        'value': 'project_date',
        'title': 'Project & Date',
        'subtitle': 'e.g., MyProject_2024_01_15.mp4'
      },
      {
        'value': 'sequential',
        'title': 'Sequential',
        'subtitle': 'e.g., Recording_001.mp4'
      },
    ];

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
                'File Naming Pattern',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ui.listSection(
                children: options.map((option) {
                  final isSelected =
                      _settings.fileNamingPattern == option['value'];

                  return ui.listTile(
                    title: Text(option['title']!),
                    subtitle: Text(option['subtitle']!),
                    trailing: isSelected
                        ? const Icon(CupertinoIcons.check_mark)
                        : null,
                    onTap: () {
                      _updateSettings((s) => s.copyWith(
                            fileNamingPattern: option['value']!,
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
