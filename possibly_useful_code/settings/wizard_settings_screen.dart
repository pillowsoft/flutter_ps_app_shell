import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:signals/signals_flutter.dart';
import '../../ui/adaptive/adaptive_widgets.dart';
import '../../core/di/service_locator.dart';
import '../../services/settings_service.dart';

/// Settings screen for configuring guided mode (wizard) options
class WizardSettingsScreen extends StatelessWidget {
  const WizardSettingsScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = getIt<SettingsService>();

    return Watch((context) {
      final ui = getAdaptiveFactory(context);
      final showProjectForm = settingsService.wizardShowProjectForm.value;
      final showExtendedOptions =
          settingsService.wizardShowExtendedOptions.value;
      final recordControllerCamera =
          settingsService.wizardRecordControllerCamera.value;

      return ui.scaffold(
        appBar: ui.appBar(
          title: const Text('Wizard Settings'),
          automaticallyImplyLeading: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interface Options
              ui.listSection(
                header: const Text('INTERFACE OPTIONS'),
                children: [
                  ui.listTile(
                    title: const Text('Show Extended Options'),
                    subtitle: const Text(
                        'Display recent projects and gallery in home screen'),
                    leading: const Icon(Icons.view_list),
                    trailing: ui.switch_(
                      value: showExtendedOptions,
                      onChanged: (value) async {
                        await settingsService
                            .setWizardShowExtendedOptions(value);
                        if (context.mounted) {
                          _showMessage(
                            context,
                            value
                                ? 'Extended options enabled - Recent projects and gallery will be shown'
                                : 'Minimal mode enabled - Only essential buttons will be shown',
                          );
                        }
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              // Project Defaults
              ui.listSection(
                header: const Text('PROJECT DEFAULTS'),
                children: [
                  ui.listTile(
                    title: const Text('Show Project Form'),
                    subtitle:
                        const Text('Ask for project details or use defaults'),
                    leading: const Icon(Icons.edit_note),
                    trailing: ui.switch_(
                      value: showProjectForm,
                      onChanged: (value) async {
                        await settingsService.setWizardShowProjectForm(value);
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                  if (!showProjectForm) ...[
                    ui.listTile(
                      title: const Text('Default Project Title'),
                      subtitle:
                          Text(settingsService.wizardDefaultProjectTitle.value),
                      leading: const Icon(Icons.title),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () => _showEditDialog(
                        context,
                        ui,
                        'Default Project Title',
                        settingsService.wizardDefaultProjectTitle.value,
                        (value) =>
                            settingsService.setWizardDefaultProjectTitle(value),
                      ),
                    ),
                    ui.listTile(
                      title: const Text('Default Project Description'),
                      subtitle: Text(settingsService
                          .wizardDefaultProjectDescription.value),
                      leading: const Icon(Icons.description),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () => _showEditDialog(
                        context,
                        ui,
                        'Default Project Description',
                        settingsService.wizardDefaultProjectDescription.value,
                        (value) => settingsService
                            .setWizardDefaultProjectDescription(value),
                      ),
                    ),
                    ui.listTile(
                      title: const Text('Default Camera Description'),
                      subtitle: Text(
                          settingsService.wizardDefaultCameraDescription.value),
                      leading: const Icon(Icons.camera_alt),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () => _showEditDialog(
                        context,
                        ui,
                        'Default Camera Description',
                        settingsService.wizardDefaultCameraDescription.value,
                        (value) => settingsService
                            .setWizardDefaultCameraDescription(value),
                      ),
                    ),
                  ],
                ],
              ),

              // Recording Options
              ui.listSection(
                header: const Text('RECORDING OPTIONS'),
                children: [
                  ui.listTile(
                    title: const Text('Record Controller Camera'),
                    subtitle:
                        const Text('Include device controlling the recording'),
                    leading: const Icon(Icons.phone_android),
                    trailing: ui.switch_(
                      value: recordControllerCamera,
                      onChanged: (value) async {
                        await settingsService
                            .setWizardRecordControllerCamera(value);
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),

              // Help Text
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Wizard Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wizard mode provides a simplified, step-by-step interface for recording projects. '
                      'These settings let you customize the default behavior to match your workflow.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tips:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Use \${date} in titles for automatic date substitution\n'
                      '• Disable "Show Extended Options" for the simplest interface\n'
                      '• Turn off "Show Project Form" to skip the details step',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showEditDialog(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    String title,
    String currentValue,
    Future<void> Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter value',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  await onSave(value);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
