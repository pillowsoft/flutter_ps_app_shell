import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import '../../ui/adaptive/adaptive_widgets.dart';
import '../../core/di/service_locator.dart';
import '../../services/wizard_state_service.dart';

class WizardStartScreen extends StatelessWidget {
  const WizardStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final wizardService = getIt<WizardStateService>();
    final theme = Theme.of(context);

    return Watch((context) {
      return ui.scaffold(
        appBar: ui.appBar(
          title: const Text('Start Recording'),
          leading: ui.iconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _exitWizard(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  'How would you like to record?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Choose whether you want to start a new recording or join an existing one',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Start option
                _buildOptionCard(
                  context: context,
                  ui: ui,
                  icon: Icons.add_circle_outline,
                  title: 'Start Recording',
                  subtitle:
                      'Create a new recording project where others can join',
                  onTap: () {
                    wizardService.setWizardMode(WizardMode.master);
                    wizardService.goToNextStep();
                    context.go('/wizard/project-details');
                  },
                ),

                const SizedBox(height: 16),

                // Collaborate option
                _buildOptionCard(
                  context: context,
                  ui: ui,
                  icon: Icons.people_outline,
                  title: 'Join Recording',
                  subtitle: 'Join an existing recording project',
                  onTap: () {
                    wizardService.setWizardMode(WizardMode.collaborate);
                    // For collaborate mode, we'll implement join screen later
                    // For now, just show a message
                    ui.showDialog(
                      context: context,
                      title: const Text('Join Recording'),
                      content: const Text(
                          'This feature will allow you to scan a QR code or enter a project ID to join an existing recording.'),
                      actions: [
                        ui.textButton(
                          label: 'OK',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(),

                // Help text
                ui.card(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can change between guided and standard mode in Settings',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required AdaptiveWidgetFactory ui,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ui.card(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  void _exitWizard(BuildContext context) {
    final wizardService = getIt<WizardStateService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ui = getAdaptiveFactory(dialogContext);

        return AlertDialog(
          title: const Text('Exit Wizard?'),
          content: const Text(
              'Are you sure you want to exit? Your progress will be lost.'),
          actions: [
            ui.textButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ui.textButton(
              label: 'Exit',
              onPressed: () {
                Navigator.of(dialogContext).pop();
                wizardService.exitWizard();
                context.go('/settings');
              },
            ),
          ],
        );
      },
    );
  }
}
