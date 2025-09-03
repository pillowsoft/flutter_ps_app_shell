import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class AdaptiveDemoScreen extends StatefulWidget {
  const AdaptiveDemoScreen({super.key});

  @override
  State<AdaptiveDemoScreen> createState() => _AdaptiveDemoScreenState();
}

class _AdaptiveDemoScreenState extends State<AdaptiveDemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _switchValue = false;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      final ui = getAdaptiveFactory(context);
      final currentSystem = settingsStore.uiSystem.value;

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPageTitle(context, 'Adaptive UI Demo'),
          const SizedBox(height: 8),
          _buildPageSubtitle(
              context, 'See how components adapt to different UI systems'),
          const SizedBox(height: 32),

          // UI System Selector
          ui.listSection(
            header: const Text('UI System'),
            children: [
              ui.card(
                child: Column(
                  children: [
                    ui.radioListTile<String>(
                      title: const Text('Material Design'),
                      subtitle: const Text('Google\'s design system'),
                      value: 'material',
                      groupValue: currentSystem,
                      onChanged: (value) {
                        if (value != null) {
                          settingsStore.setUiSystem(value);
                        }
                      },
                    ),
                    ui.radioListTile<String>(
                      title: const Text('Cupertino (iOS)'),
                      subtitle: const Text('Apple\'s design system'),
                      value: 'cupertino',
                      groupValue: currentSystem,
                      onChanged: (value) {
                        if (value != null) {
                          settingsStore.setUiSystem(value);
                        }
                      },
                    ),
                    ui.radioListTile<String>(
                      title: const Text('ForUI'),
                      subtitle: const Text('Modern design system'),
                      value: 'forui',
                      groupValue: currentSystem,
                      onChanged: (value) {
                        if (value != null) {
                          settingsStore.setUiSystem(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Component Showcase
          ui.listSection(
            header: const Text('Component Showcase'),
            children: [
              ui.card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Buttons'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ui.button(
                          label: 'Primary Button',
                          onPressed: () {
                            _showAdaptiveDialog(context, ui);
                          },
                        ),
                        ui.textButton(
                          label: 'Text Button',
                          onPressed: () {
                            ui.showSnackBar(
                              context,
                              'Text button pressed!',
                            );
                          },
                        ),
                        ui.iconButton(
                          icon: Icon(ui.getIcon('add')),
                          onPressed: () {
                            _showAdaptiveBottomSheet(context, ui);
                          },
                          tooltip: 'Add Item',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ui.card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Form Components'),
                    const SizedBox(height: 16),
                    ui.form(
                      formKey: _formKey,
                      child: Column(
                        children: [
                          ui.textField(
                            controller: _textController,
                            labelText: 'Search Field',
                            hintText: 'Search for something...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _textController.clear(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ui.textField(
                            labelText: 'Email Address',
                            hintText: 'user@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            suffixIcon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          ui.textField(
                            labelText: 'Password',
                            hintText: 'Enter your password...',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            obscureText: !_passwordVisible,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ui.switch_(
                                value: _switchValue,
                                onChanged: (value) {
                                  setState(() {
                                    _switchValue = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Toggle this switch'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ui.card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'List Items'),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        ui.listTile(
                          leading: Icon(ui.getIcon('home')),
                          title: const Text('Home'),
                          subtitle: const Text('Go to home screen'),
                          trailing: Icon(ui.getIcon('chevron_right')),
                          onTap: () {
                            final nav = getIt<NavigationService>();
                            nav.go('/');
                          },
                        ),
                        const Divider(height: 1),
                        ui.listTile(
                          leading: Icon(ui.getIcon('settings')),
                          title: const Text('Settings'),
                          subtitle: const Text('Configure your preferences'),
                          trailing: Icon(ui.getIcon('chevron_right')),
                          onTap: () {
                            final nav = getIt<NavigationService>();
                            nav.go('/settings');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Current System Info
          _buildInfoCard(context, currentSystem),
        ],
      );
    });
  }

  Widget _buildPageTitle(BuildContext context, String title) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final uiSystem = settingsStore.uiSystem.value;

    late TextStyle style;
    switch (uiSystem) {
      case 'forui':
        style = const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.2,
        );
        break;
      case 'cupertino':
        style = const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000), // black
        );
        break;
      default: // material
        style = Theme.of(context).textTheme.headlineLarge ?? const TextStyle();
    }

    return Text(title, style: style);
  }

  Widget _buildPageSubtitle(BuildContext context, String subtitle) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final uiSystem = settingsStore.uiSystem.value;

    late TextStyle style;
    switch (uiSystem) {
      case 'forui':
        style = const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF71717A), // zinc-500
          height: 1.5,
        );
        break;
      case 'cupertino':
        style = const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8E8E93), // systemGray
        );
        break;
      default: // material
        style = Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ) ??
            const TextStyle();
    }

    return Text(subtitle, style: style);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final uiSystem = settingsStore.uiSystem.value;

    late TextStyle style;
    switch (uiSystem) {
      case 'forui':
        style = const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF020817), // zinc-950
          height: 1.3,
        );
        break;
      case 'cupertino':
        style = const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000), // black
        );
        break;
      default: // material
        style = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    }

    return Text(title, style: style);
  }

  Widget _buildInfoCard(BuildContext context, String currentSystem) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final uiSystem = settingsStore.uiSystem.value;

    late Color backgroundColor;
    late Color foregroundColor;
    late IconData iconData;

    switch (uiSystem) {
      case 'forui':
        backgroundColor = const Color(0xFFF4F4F5); // zinc-100
        foregroundColor = const Color(0xFF71717A); // zinc-500
        iconData = Icons.info_outline;
        break;
      case 'cupertino':
        backgroundColor = const Color(0xFFF2F2F7); // systemGray6
        foregroundColor = const Color(0xFF8E8E93); // systemGray
        iconData = Icons.info_outline;
        break;
      default: // material
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
        iconData = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(iconData, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current UI System: ${_getSystemDisplayName(currentSystem)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Components automatically adapt their appearance and behavior',
                  style: TextStyle(
                    fontSize: 12,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSystemDisplayName(String system) {
    switch (system) {
      case 'material':
        return 'Material Design';
      case 'cupertino':
        return 'Cupertino (iOS)';
      case 'forui':
        return 'ForUI';
      default:
        return 'Material Design';
    }
  }

  void _showAdaptiveDialog(BuildContext context, AdaptiveWidgetFactory ui) {
    // Use the adaptive factory for all UI systems
    ui.showDialog(
      context: context,
      title: const Text('Adaptive Dialog'),
      content: const Text('This dialog adapts to the current UI system.'),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        ui.textButton(
          label: 'OK',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _showAdaptiveBottomSheet(
      BuildContext context, AdaptiveWidgetFactory ui) {
    ui.showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adaptive Bottom Sheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('This bottom sheet adapts to the current UI system.'),
            const SizedBox(height: 24),
            ui.button(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
