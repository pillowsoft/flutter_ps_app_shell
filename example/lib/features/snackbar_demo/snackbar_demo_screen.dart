import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

/// Comprehensive demo of platform-adaptive snackbar notifications
class SnackBarDemoScreen extends StatefulWidget {
  const SnackBarDemoScreen({super.key});

  @override
  State<SnackBarDemoScreen> createState() => _SnackBarDemoScreenState();
}

class _SnackBarDemoScreenState extends State<SnackBarDemoScreen> {
  // Track active snackbar controller for programmatic dismissal demo
  ScaffoldFeatureController? _activeController;

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      final currentSystem = settingsStore.uiSystem.value;

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Page Title
          _buildPageTitle(context, 'SnackBar Demo'),
          const SizedBox(height: 8),
          _buildPageSubtitle(context,
              'Platform-adaptive notifications that respect each UI system'),
          const SizedBox(height: 24),

          // Platform Behavior Info
          ui.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                    context, 'Current: ${_getSystemName(currentSystem)}'),
                const SizedBox(height: 8),
                Text(
                  _getPlatformBehavior(currentSystem),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (currentSystem == 'cupertino') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Try swiping up on the notification to dismiss!',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Basic SnackBars
          ui.listSection(
            header: const Text('Basic SnackBars'),
            children: [
              ui.card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ui.button(
                      label: 'Simple Message',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'This is a simple snackbar message',
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.button(
                      label: 'With Action',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'Message with an action button',
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              ui.showSnackBar(
                                context,
                                'Action was pressed!',
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.outlinedButton(
                      label: 'Long Duration (10s)',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'This snackbar will stay visible for 10 seconds',
                          duration: const Duration(seconds: 10),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Styled SnackBars
          ui.listSection(
            header: const Text('Styled SnackBars'),
            children: [
              ui.card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ui.button(
                      label: '✅ Success Message',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'Operation completed successfully!',
                          backgroundColor: Colors.green.shade600,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.button(
                      label: '❌ Error Message',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'An error occurred. Please try again.',
                          backgroundColor: Colors.red.shade600,
                          action: SnackBarAction(
                            label: 'RETRY',
                            textColor: Colors.white,
                            onPressed: () {
                              ui.showSnackBar(
                                context,
                                'Retrying operation...',
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.button(
                      label: 'ℹ️ Info Message',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'New update available. Tap to learn more.',
                          backgroundColor: Colors.blue.shade600,
                          duration: const Duration(seconds: 6),
                          action: SnackBarAction(
                            label: 'VIEW',
                            textColor: Colors.white,
                            onPressed: () {
                              ui.showSnackBar(
                                context,
                                'Opening update details...',
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.outlinedButton(
                      label: '⚠️ Warning Message',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'Your session will expire in 5 minutes',
                          backgroundColor: Colors.orange.shade700,
                          duration: const Duration(seconds: 5),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Advanced Examples
          ui.listSection(
            header: const Text('Advanced Examples'),
            children: [
              ui.card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ui.button(
                      label: 'Sequential Messages',
                      onPressed: () async {
                        ui.showSnackBar(
                          context,
                          'First message (3 seconds)',
                          duration: const Duration(seconds: 3),
                        );

                        await Future.delayed(
                            const Duration(seconds: 3, milliseconds: 500));

                        ui.showSnackBar(
                          context,
                          'Second message (3 seconds)',
                          backgroundColor: Colors.purple.shade600,
                          duration: const Duration(seconds: 3),
                        );

                        await Future.delayed(
                            const Duration(seconds: 3, milliseconds: 500));

                        ui.showSnackBar(
                          context,
                          'Third and final message!',
                          backgroundColor: Colors.green.shade600,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.button(
                      label: 'Programmatic Dismissal',
                      onPressed: () {
                        _activeController = ui.showSnackBar(
                          context,
                          'This can be dismissed programmatically',
                          duration: const Duration(minutes: 1), // Long duration
                          backgroundColor: Colors.indigo.shade600,
                        );

                        // Show another snackbar with dismiss button
                        Future.delayed(const Duration(seconds: 2), () {
                          ui.showSnackBar(
                            context,
                            'Tap to dismiss the previous snackbar',
                            action: SnackBarAction(
                              label: 'DISMISS',
                              onPressed: () {
                                _activeController?.close();
                                _activeController = null;
                              },
                            ),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ui.outlinedButton(
                      label: 'Multiple Actions Demo',
                      onPressed: () {
                        ui.showSnackBar(
                          context,
                          'Item deleted',
                          duration: const Duration(seconds: 6),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              ui.showSnackBar(
                                context,
                                'Delete undone - item restored',
                                backgroundColor: Colors.green.shade600,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Usage Guide
          ui.listSection(
            header: const Text('Usage Guide'),
            children: [
              ui.card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCodeExample(
                      context,
                      title: 'Basic Usage:',
                      code: '''final ui = getAdaptiveFactory(context);

ui.showSnackBar(
  context: context,
  message: 'Your message here',
);''',
                    ),
                    const SizedBox(height: 16),
                    _buildCodeExample(
                      context,
                      title: 'With Action:',
                      code: '''ui.showSnackBar(
  context: context,
  message: 'Item deleted',
  action: SnackBarAction(
    label: 'UNDO',
    onPressed: () => restoreItem(),
  ),
);''',
                    ),
                    const SizedBox(height: 16),
                    _buildCodeExample(
                      context,
                      title: 'Custom Styling:',
                      code: '''ui.showSnackBar(
  context: context,
  message: 'Success!',
  backgroundColor: Colors.green,
  duration: const Duration(seconds: 5),
);''',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPageTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildPageSubtitle(BuildContext context, String subtitle) {
    return Text(
      subtitle,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCodeExample(
    BuildContext context, {
    required String title,
    required String code,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _getSystemName(String system) {
    switch (system) {
      case 'material':
        return 'Material Design';
      case 'cupertino':
        return 'Cupertino (iOS)';
      case 'forui':
        return 'ForUI';
      default:
        return system;
    }
  }

  String _getPlatformBehavior(String system) {
    switch (system) {
      case 'material':
        return 'Snackbars appear at the bottom of the screen with Material Design styling. They slide up from the bottom and support actions.';
      case 'cupertino':
        return '✨ NEW: iOS-style notifications slide down from the top with a blur effect background. Swipe up to dismiss or wait for auto-dismiss.';
      case 'forui':
        return 'Clean, flat design snackbars appear at the bottom with ForUI\'s minimalist styling and zinc color palette.';
      default:
        return 'Platform-adaptive snackbar behavior';
    }
  }
}
