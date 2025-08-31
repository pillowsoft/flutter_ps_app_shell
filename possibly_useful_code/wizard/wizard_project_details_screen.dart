import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../ui/adaptive/adaptive_widgets.dart';
import '../../core/di/service_locator.dart';
import '../../services/wizard_state_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/wizard/wizard_navigation_bar.dart';

class WizardProjectDetailsScreen extends HookWidget {
  const WizardProjectDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final wizardService = getIt<WizardStateService>();
    final settingsService = getIt<SettingsService>();
    final theme = Theme.of(context);

    // Form controllers
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final cameraController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Initialize with wizard state or defaults
    useEffect(() {
      // Load from wizard state if available
      if (wizardService.projectTitle.value.isNotEmpty) {
        titleController.text = wizardService.projectTitle.value;
      } else if (!settingsService.wizardShowProjectForm.value) {
        // Use default values with date substitution
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        titleController.text = settingsService.wizardDefaultProjectTitle.value
            .replaceAll('\${date}', dateStr);
      }

      if (wizardService.projectDescription.value.isNotEmpty) {
        descriptionController.text = wizardService.projectDescription.value;
      } else if (!settingsService.wizardShowProjectForm.value) {
        descriptionController.text =
            settingsService.wizardDefaultProjectDescription.value;
      }

      if (wizardService.cameraDescription.value.isNotEmpty) {
        cameraController.text = wizardService.cameraDescription.value;
      } else if (!settingsService.wizardShowProjectForm.value) {
        cameraController.text =
            settingsService.wizardDefaultCameraDescription.value;
      }

      return null;
    }, []);

    // Update wizard state on changes
    void updateWizardState() {
      wizardService.updateProjectTitle(titleController.text);
      wizardService.updateProjectDescription(descriptionController.text);
      wizardService.updateCameraDescription(cameraController.text);
    }

    return Watch((context) {
      final showForm = settingsService.wizardShowProjectForm.value;

      return ui.scaffold(
        appBar: ui.appBar(
          title: const Text('Project Details'),
          leading: ui.iconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _exitWizard(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: wizardService.progress.value,
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ui.form(
                    formKey: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showForm) ...[
                          // Title
                          Text(
                            'Set up your project',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            'Enter details about your recording project',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Project title field
                          ui.textField(
                            controller: titleController,
                            labelText: 'Project Title',
                            hintText: 'Enter a title for your recording',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a project title';
                              }
                              return null;
                            },
                            onChanged: (_) => updateWizardState(),
                          ),

                          const SizedBox(height: 20),

                          // Project description field
                          ui.textField(
                            controller: descriptionController,
                            labelText: 'Project Description',
                            hintText: 'Describe what you\'re recording',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                            onChanged: (_) => updateWizardState(),
                          ),

                          const SizedBox(height: 20),

                          // Camera description field
                          ui.textField(
                            controller: cameraController,
                            labelText: 'Camera Description',
                            hintText: 'e.g., Main camera, Side angle',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe this camera\'s role';
                              }
                              return null;
                            },
                            onChanged: (_) => updateWizardState(),
                          ),
                        ] else ...[
                          // Show current values when form is disabled
                          Text(
                            'Project Details',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 32),

                          _buildDetailCard(
                            ui: ui,
                            theme: theme,
                            label: 'Title',
                            value: titleController.text,
                          ),

                          const SizedBox(height: 16),

                          _buildDetailCard(
                            ui: ui,
                            theme: theme,
                            label: 'Description',
                            value: descriptionController.text,
                          ),

                          const SizedBox(height: 16),

                          _buildDetailCard(
                            ui: ui,
                            theme: theme,
                            label: 'Camera',
                            value: cameraController.text,
                          ),

                          const SizedBox(height: 32),

                          // Info card
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
                                    'Using default values from settings. You can customize these in Wizard Settings.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Navigation bar
              WizardNavigationBar(
                canGoBack: true,
                canProceed: showForm ? wizardService.canProceed.value : true,
                onBack: () {
                  if (settingsService.guidedModeEnabled.value) {
                    // In guided mode, go back to home screen
                    wizardService.exitWizard();
                    context.go('/guided-home');
                  } else {
                    // Standard wizard flow
                    wizardService.goToPreviousStep();
                    context.go('/wizard/start');
                  }
                },
                onNext: () {
                  if (showForm) {
                    if (formKey.currentState?.validate() ?? false) {
                      updateWizardState();
                      _proceedToNext(context);
                    }
                  } else {
                    // Already updated state from useEffect
                    updateWizardState();
                    _proceedToNext(context);
                  }
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDetailCard({
    required AdaptiveWidgetFactory ui,
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return ui.card(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _proceedToNext(BuildContext context) {
    final wizardService = getIt<WizardStateService>();
    wizardService.goToNextStep();
    context.go('/wizard/invite');
  }

  void _exitWizard(BuildContext context) {
    final wizardService = getIt<WizardStateService>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ui = getAdaptiveFactory(dialogContext);

        return AlertDialog(
          title: const Text('Exit Wizard?'),
          content:
              const Text('Your project details will be lost. Are you sure?'),
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
