import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

/// Demo screen specifically for the high-priority button components
/// that were mentioned as missing: buttonWithIcon, outlinedButton, outlinedButtonWithIcon
class ButtonDemoScreen extends StatefulWidget {
  const ButtonDemoScreen({super.key});

  @override
  State<ButtonDemoScreen> createState() => _ButtonDemoScreenState();
}

class _ButtonDemoScreenState extends State<ButtonDemoScreen> {
  String _lastActionLog = 'No actions yet';
  final List<String> _actionHistory = [];

  void _logAction(String action) {
    setState(() {
      _lastActionLog = action;
      _actionHistory.insert(
          0, '$action at ${DateTime.now().toString().substring(11, 19)}');
      if (_actionHistory.length > 10) {
        _actionHistory.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return Scaffold(
        key: ValueKey('button_demo_scaffold_$uiSystem'),
        appBar: AppBar(
          title: const Text('Button Components Demo'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Adaptive Button Components',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These are the high-priority button methods that were requested. All work consistently across Material, Cupertino, and ForUI design systems.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Primary Buttons with Icons
              _buildButtonSection(
                title: 'Primary Buttons with Icons',
                description:
                    'buttonWithIcon() - Primary action buttons with icon + text',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ui.buttonWithIcon(
                            icon: const Icon(Icons.videocam),
                            label: 'Start Recording',
                            onPressed: () => _logAction('Started Recording'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.buttonWithIcon(
                            icon: const Icon(Icons.photo_camera),
                            label: 'Take Photo',
                            onPressed: () => _logAction('Took Photo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ui.buttonWithIcon(
                            icon: const Icon(Icons.save),
                            label: 'Save Project',
                            onPressed: () => _logAction('Saved Project'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.buttonWithIcon(
                            icon: const Icon(Icons.share),
                            label: 'Share',
                            onPressed: () => _logAction('Shared Content'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Outlined Buttons
              _buildButtonSection(
                title: 'Outlined Buttons',
                description:
                    'outlinedButton() - Secondary actions with less emphasis',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ui.outlinedButton(
                            label: 'Cancel',
                            onPressed: () => _logAction('Cancelled Action'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.outlinedButton(
                            label: 'Reset',
                            onPressed: () => _logAction('Reset Form'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ui.outlinedButton(
                            label: 'Preview',
                            onPressed: () => _logAction('Opened Preview'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.outlinedButton(
                            label: 'Draft',
                            onPressed: () => _logAction('Saved as Draft'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Outlined Buttons with Icons
              _buildButtonSection(
                title: 'Outlined Buttons with Icons',
                description:
                    'outlinedButtonWithIcon() - Secondary actions with icon context',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ui.outlinedButtonWithIcon(
                            icon: const Icon(Icons.file_upload),
                            label: 'Export Video',
                            onPressed: () => _logAction('Exported Video'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.outlinedButtonWithIcon(
                            icon: const Icon(Icons.download),
                            label: 'Download',
                            onPressed: () => _logAction('Downloaded File'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ui.outlinedButtonWithIcon(
                            icon: const Icon(Icons.edit),
                            label: 'Edit Settings',
                            onPressed: () => _logAction('Opened Edit Settings'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ui.outlinedButtonWithIcon(
                            icon: const Icon(Icons.history),
                            label: 'View History',
                            onPressed: () => _logAction('Opened History'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Additional UI Components Demo
              _buildButtonSection(
                title: 'Additional UI Components',
                description:
                    'Other adaptive components: divider, progress indicators, chips, badges',
                child: Column(
                  children: [
                    // Dividers
                    Text(
                      'Adaptive Dividers',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ui.divider(),
                    const SizedBox(height: 8),
                    ui.divider(thickness: 2, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),

                    // Progress Indicators
                    Text(
                      'Progress Indicators',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ui.linearProgressIndicator(
                      value: 0.7,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ui.circularProgressIndicator(
                          value: 0.8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        ui.circularProgressIndicator(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chips
                    Text(
                      'Adaptive Chips',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ui.chip(
                          label: const Text('Video'),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                        ui.chip(
                          label: const Text('Photo'),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                        ),
                        ui.chip(
                          label: const Text('Audio'),
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          onDeleted: () => _logAction('Deleted Audio chip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badges
                    Text(
                      'Adaptive Badges',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ui.badge(
                          label: const Text('3'),
                          backgroundColor: theme.colorScheme.error,
                          textColor: theme.colorScheme.onError,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        const SizedBox(width: 24),
                        ui.badge(
                          label: const Text('NEW'),
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                          child: const Icon(Icons.message_outlined),
                        ),
                        const SizedBox(width: 24),
                        ui.badge(
                          backgroundColor: theme.colorScheme.error,
                          child: const Icon(Icons.favorite_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Log
              _buildButtonSection(
                title: 'Action Log',
                description:
                    'See how button interactions work across all UI systems',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Action:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lastActionLog,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_actionHistory.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Recent Actions:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._actionHistory.take(5).map((action) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $action',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ui.outlinedButton(
                      label: 'Clear Log',
                      onPressed: () {
                        setState(() {
                          _lastActionLog = 'Log cleared';
                          _actionHistory.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Usage Examples
              _buildButtonSection(
                title: 'Usage Examples',
                description: 'Code examples for implementing these components',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example Usage:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCodeExample(
                        'Primary Button with Icon:',
                        '''ui.buttonWithIcon(
  icon: const Icon(Icons.videocam),
  label: 'Start Recording',
  onPressed: () => startRecording(),
)''',
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildCodeExample(
                        'Outlined Button:',
                        '''ui.outlinedButton(
  label: 'Cancel',
  onPressed: () => cancelAction(),
)''',
                        theme,
                      ),
                      const SizedBox(height: 12),
                      _buildCodeExample(
                        'Outlined Button with Icon:',
                        '''ui.outlinedButtonWithIcon(
  icon: const Icon(Icons.file_upload),
  label: 'Export Video',
  onPressed: () => exportVideo(),
)''',
                        theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildButtonSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildCodeExample(String title, String code, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            code,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
