import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:flutter_app_shell/src/ui/adaptive/components/adaptive_dialog_models.dart';
import 'package:signals/signals_flutter.dart';

class DialogDemoScreen extends StatefulWidget {
  const DialogDemoScreen({super.key});

  @override
  State<DialogDemoScreen> createState() => _DialogDemoScreenState();
}

class _DialogDemoScreenState extends State<DialogDemoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _enableFeature = signal(false);
  final _selectedPriority = signal('medium');
  final _dialogResults = signal<List<String>>([]);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addResult(String result) {
    _dialogResults.value = [..._dialogResults.value, result];
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ui.pageTitle('Dialog Demos'),

        // Screen size indicator
        ui.card(
          child: ui.listTile(
            title: ui.text('Current Screen Size'),
            subtitle: ui.text(
                'Width: ${screenWidth.toStringAsFixed(0)}px - ${isMobile ? "Mobile" : screenWidth < 1200 ? "Tablet" : "Desktop"}'),
            leading: ui.avatar(
              child: Icon(isMobile
                  ? Icons.phone_android
                  : screenWidth < 1200
                      ? Icons.tablet
                      : Icons.desktop_windows),
            ),
          ),
        ),

        const SizedBox(height: 24),
        ui.text('Dialog Types',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Form Dialog Demo
        ui.card(
          child: ui.listTile(
            title: ui.text('Form Dialog'),
            subtitle:
                ui.text('Complex form with multiple inputs and custom width'),
            trailing: ui.button(
              label: 'Show Form',
              onPressed: () => _showFormDialog(context, ui),
            ),
            onTap: () => _showFormDialog(context, ui),
          ),
        ),

        const SizedBox(height: 8),

        // Page Modal Demo
        ui.card(
          child: ui.listTile(
            title: ui.text('Page Modal'),
            subtitle: ui.text('Full-screen on mobile, dialog on desktop'),
            trailing: ui.button(
              label: 'Show Page',
              onPressed: () => _showPageModal(context, ui),
            ),
            onTap: () => _showPageModal(context, ui),
          ),
        ),

        const SizedBox(height: 8),

        // Action Sheet Demo
        ui.card(
          child: ui.listTile(
            title: ui.text('Action Sheet'),
            subtitle: ui.text('Platform-specific option selection'),
            trailing: ui.button(
              label: 'Show Actions',
              onPressed: () => _showActionSheet(context, ui),
            ),
            onTap: () => _showActionSheet(context, ui),
          ),
        ),

        const SizedBox(height: 8),

        // Confirmation Dialog Demo
        ui.card(
          child: ui.listTile(
            title: ui.text('Confirmation Dialog'),
            subtitle: ui.text('Simple confirmation with destructive option'),
            trailing: ui.button(
              label: 'Show Confirm',
              onPressed: () => _showConfirmationDialog(context, ui),
            ),
            onTap: () => _showConfirmationDialog(context, ui),
          ),
        ),

        const SizedBox(height: 8),

        // Destructive Confirmation Demo
        ui.card(
          child: ui.listTile(
            title: ui.text('Destructive Action'),
            subtitle: ui.text('Delete confirmation with warning styling'),
            trailing: ui.button(
              label: 'Delete Item',
              onPressed: () => _showDestructiveDialog(context, ui),
            ),
            onTap: () => _showDestructiveDialog(context, ui),
          ),
        ),

        const SizedBox(height: 24),
        ui.text('Dialog Results',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Results display
        Watch(
          (context) {
            final results = _dialogResults.value;
            if (results.isEmpty) {
              return ui.card(
                child: ui.listTile(
                  title: ui.text('No results yet'),
                  subtitle:
                      ui.text('Interact with the dialogs above to see results'),
                  leading: ui.avatar(
                    child: const Icon(Icons.info_outline),
                  ),
                ),
              );
            }

            return Column(
              children: results.reversed.take(10).map((result) {
                return ui.card(
                  child: ui.listTile(
                    title: ui.text(result),
                    subtitle: ui.text(DateTime.now().toString()),
                    leading: ui.avatar(
                      child: const Icon(Icons.check_circle),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // Clear results button
        Center(
          child: ui.button(
            label: 'Clear Results',
            onPressed: () {
              _dialogResults.value = [];
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showFormDialog(
      BuildContext context, AdaptiveWidgetFactory ui) async {
    // Reset form fields
    _nameController.clear();
    _emailController.clear();
    _descriptionController.clear();
    _enableFeature.value = false;
    _selectedPriority.value = 'medium';

    final result = await ui.showFormDialog<bool>(
      context: context,
      title: ui.text('Create New Project'),
      width: 700, // Custom width for desktop
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ui.text('Fill in the project details below:'),
          const SizedBox(height: 16),
          ui.textField(
            controller: _nameController,
            label: 'Project Name',
            hintText: 'Enter project name',
          ),
          const SizedBox(height: 16),
          ui.textField(
            controller: _emailController,
            label: 'Contact Email',
            hintText: 'email@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          ui.textField(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'Enter project description',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Watch((context) => ui.listTile(
                title: ui.text('Enable Advanced Features'),
                trailing: ui.switch_(
                  value: _enableFeature.value,
                  onChanged: (value) => _enableFeature.value = value,
                ),
              )),
          const SizedBox(height: 16),
          ui.text('Priority Level:'),
          const SizedBox(height: 8),
          Watch((context) => Column(
                children: [
                  ui.radioListTile<String>(
                    value: 'low',
                    groupValue: _selectedPriority.value,
                    onChanged: (value) =>
                        _selectedPriority.value = value ?? 'medium',
                    title: ui.text('Low'),
                    subtitle: ui.text('Standard timeline'),
                  ),
                  ui.radioListTile<String>(
                    value: 'medium',
                    groupValue: _selectedPriority.value,
                    onChanged: (value) =>
                        _selectedPriority.value = value ?? 'medium',
                    title: ui.text('Medium'),
                    subtitle: ui.text('Accelerated timeline'),
                  ),
                  ui.radioListTile<String>(
                    value: 'high',
                    groupValue: _selectedPriority.value,
                    onChanged: (value) =>
                        _selectedPriority.value = value ?? 'medium',
                    title: ui.text('High'),
                    subtitle: ui.text('Urgent timeline'),
                  ),
                ],
              )),
        ],
      ),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ui.button(
          label: 'Create Project',
          onPressed: () {
            // Validate and submit
            if (_nameController.text.isNotEmpty) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
    );

    if (result == true) {
      _addResult(
          'Created project: ${_nameController.text} (Priority: ${_selectedPriority.value})');
    } else {
      _addResult('Form dialog cancelled');
    }
  }

  Future<void> _showPageModal(
      BuildContext context, AdaptiveWidgetFactory ui) async {
    final result = await ui.showPageModal<String>(
      context: context,
      title: 'Profile Settings',
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ui.card(
              child: Column(
                children: [
                  ui.listTile(
                    title: ui.text('Personal Information'),
                    subtitle: ui.text('Update your profile details'),
                    leading: const Icon(Icons.person),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  ui.divider(),
                  ui.listTile(
                    title: ui.text('Security'),
                    subtitle: ui.text('Password and authentication'),
                    leading: const Icon(Icons.security),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  ui.divider(),
                  ui.listTile(
                    title: ui.text('Privacy'),
                    subtitle: ui.text('Control your data'),
                    leading: const Icon(Icons.privacy_tip),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ui.card(
              child: Column(
                children: [
                  ui.listTile(
                    title: ui.text('Notifications'),
                    subtitle: ui.text('Email and push settings'),
                    leading: const Icon(Icons.notifications),
                    trailing: ui.switch_(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),
                  ui.divider(),
                  ui.listTile(
                    title: ui.text('Dark Mode'),
                    subtitle: ui.text('Use dark theme'),
                    leading: const Icon(Icons.dark_mode),
                    trailing: ui.switch_(
                      value: false,
                      onChanged: (value) {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ui.button(
              label: 'Save Changes',
              onPressed: () => Navigator.of(context).pop('saved'),
            ),
          ],
        );
      },
    );

    _addResult('Page modal result: ${result ?? "cancelled"}');
  }

  Future<void> _showActionSheet(
      BuildContext context, AdaptiveWidgetFactory ui) async {
    final result = await ui.showActionSheet<String>(
      context: context,
      title: ui.text('Share Project'),
      message: ui.text('Choose how you want to share this project'),
      actions: [
        AdaptiveActionSheetItem(
          value: 'email',
          label: 'Email',
          icon: Icons.email,
        ),
        AdaptiveActionSheetItem(
          value: 'link',
          label: 'Copy Link',
          icon: Icons.link,
          isDefault: true,
        ),
        AdaptiveActionSheetItem(
          value: 'social',
          label: 'Social Media',
          icon: Icons.share,
        ),
        AdaptiveActionSheetItem(
          value: 'delete',
          label: 'Delete Share',
          icon: Icons.delete,
          isDestructive: true,
        ),
      ],
    );

    if (result != null) {
      _addResult('Action selected: $result');
    } else {
      _addResult('Action sheet cancelled');
    }
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, AdaptiveWidgetFactory ui) async {
    final result = await ui.showConfirmationDialog(
      context: context,
      title: 'Enable Sync?',
      message:
          'This will sync your data across all devices. You can change this later in settings.',
      confirmText: 'Enable',
      cancelText: 'Not Now',
      icon: Icons.sync,
    );

    _addResult(
        'Confirmation result: ${result == true ? "Confirmed" : "Cancelled"}');
  }

  Future<void> _showDestructiveDialog(
      BuildContext context, AdaptiveWidgetFactory ui) async {
    final result = await ui.showConfirmationDialog(
      context: context,
      title: 'Delete Project?',
      message:
          'This action cannot be undone. All project data will be permanently deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_forever,
    );

    _addResult(
        'Delete confirmation: ${result == true ? "DELETED" : "Cancelled"}');
  }
}
