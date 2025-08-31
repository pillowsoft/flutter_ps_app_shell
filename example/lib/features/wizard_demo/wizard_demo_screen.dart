import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class WizardDemoScreen extends StatelessWidget {
  const WizardDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);
      final styles = context.adaptiveStyle;

      return ui.scaffold(
        key: ValueKey('wizard_demo_scaffold_$uiSystem'),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 32,
                    color: styles.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wizard Navigation System',
                          style: styles.headlineLarge,
                        ),
                        Text(
                          'Step-by-step flows for onboarding, forms, and configuration',
                          style: styles.bodyMedium.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Wizard Examples Grid
              Expanded(
                child: _buildWizardGrid(context, ui, styles),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWizardGrid(BuildContext context, AdaptiveWidgetFactory ui,
      AdaptiveStyleProvider styles) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridCount(screenWidth);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildWizardCard(
          context,
          ui,
          styles,
          title: 'User Onboarding',
          description: 'Welcome flow with profile setup',
          icon: Icons.person_add,
          color: Colors.blue,
          onTap: () => _startOnboardingWizard(context),
        ),
        _buildWizardCard(
          context,
          ui,
          styles,
          title: 'App Configuration',
          description: 'Settings and preferences setup',
          icon: Icons.settings_suggest,
          color: Colors.green,
          onTap: () => _startConfigWizard(context),
        ),
        _buildWizardCard(
          context,
          ui,
          styles,
          title: 'Survey Form',
          description: 'Multi-step data collection',
          icon: Icons.quiz,
          color: Colors.orange,
          onTap: () => _startSurveyWizard(context),
        ),
        _buildWizardCard(
          context,
          ui,
          styles,
          title: 'Progress Styles',
          description: 'Different progress indicators',
          icon: Icons.timeline,
          color: Colors.purple,
          onTap: () => _startProgressStyleWizard(context),
        ),
      ],
    );
  }

  int _getGridCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildWizardCard(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ui.card(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),

          const Spacer(),

          // Title
          Text(
            title,
            style: styles.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: styles.bodyMedium.copyWith(
              color: styles.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Action indicator
          Row(
            children: [
              Text(
                'Try it out',
                style: styles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: color,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startOnboardingWizard(BuildContext context) {
    final prefsService = getIt<PreferencesService>();

    final wizardFlow = WizardFlow(
      id: 'user_onboarding',
      title: 'Welcome to Our App!',
      description: 'Let\'s get you set up with a personalized experience',
      showProgress: true,
      progressStyle: WizardProgressStyle.steps,
      steps: [
        // Welcome step
        WizardStep(
          id: 'welcome',
          title: 'Welcome!',
          subtitle: 'We\'re excited to have you here',
          icon: Icons.waving_hand,
          builder: (context, controller) {
            final styles = context.adaptiveStyle;
            return WizardInfoStep(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thank you for choosing our app! This quick setup will help us personalize your experience.',
                    style: styles.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: styles.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: styles.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This should only take about 2-3 minutes to complete.',
                            style: styles.bodyMedium.copyWith(
                              color: styles.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Profile step
        WizardStep(
          id: 'profile',
          title: 'Tell us about yourself',
          subtitle: 'Basic information to personalize your experience',
          icon: Icons.person,
          validator: (controller) {
            final name = controller.getData<String>('name');
            if (name == null || name.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
          builder: (context, controller) {
            return Column(
              children: [
                WizardTextInputStep(
                  controller: controller,
                  dataKey: 'name',
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  required: true,
                ),
                const SizedBox(height: 16),
                WizardTextInputStep(
                  controller: controller,
                  dataKey: 'email',
                  label: 'Email Address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ],
            );
          },
        ),

        // Preferences step
        WizardStep(
          id: 'preferences',
          title: 'Your preferences',
          subtitle: 'Choose what matters most to you',
          icon: Icons.tune,
          builder: (context, controller) {
            return WizardChoiceStep(
              controller: controller,
              dataKey: 'interests',
              title: 'What are you interested in?',
              multiSelect: true,
              choices: const [
                WizardChoice(
                  value: 'technology',
                  title: 'Technology',
                  subtitle: 'Latest tech news and updates',
                  icon: Icons.computer,
                ),
                WizardChoice(
                  value: 'business',
                  title: 'Business',
                  subtitle: 'Business insights and trends',
                  icon: Icons.business,
                ),
                WizardChoice(
                  value: 'design',
                  title: 'Design',
                  subtitle: 'UI/UX and creative content',
                  icon: Icons.palette,
                ),
                WizardChoice(
                  value: 'productivity',
                  title: 'Productivity',
                  subtitle: 'Tips for getting things done',
                  icon: Icons.trending_up,
                ),
              ],
            );
          },
        ),

        // Summary step
        WizardStep(
          id: 'summary',
          title: 'Almost done!',
          subtitle: 'Review your information',
          icon: Icons.check_circle_outline,
          builder: (context, controller) {
            return WizardSummaryStep(
              controller: controller,
              title: 'Your Profile Summary',
              fields: const [
                WizardSummaryField(
                  key: 'name',
                  label: 'Name',
                  icon: Icons.person,
                ),
                WizardSummaryField(
                  key: 'email',
                  label: 'Email',
                  icon: Icons.email,
                ),
                WizardSummaryField(
                  key: 'interests',
                  label: 'Interests',
                  icon: Icons.favorite,
                  formatter: _formatInterests,
                ),
              ],
            );
          },
        ),
      ],
      onComplete: (controller) async {
        AppShellLogger.i(
            'Onboarding completed with data: ${controller.getAllData()}');
        // In a real app, you would save this data to your backend
      },
    );

    final controller = WizardController(
      flow: wizardFlow,
      preferencesService: prefsService,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WizardScreen(
          controller: controller,
          onCancel: () {
            controller.dispose();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startConfigWizard(BuildContext context) {
    final prefsService = getIt<PreferencesService>();

    final wizardFlow = WizardFlow(
      id: 'app_configuration',
      title: 'App Configuration',
      description: 'Customize your app experience',
      showProgress: true,
      progressStyle: WizardProgressStyle.numbered,
      steps: [
        // Theme selection
        WizardStep(
          id: 'theme',
          title: 'Choose your theme',
          subtitle: 'Select your preferred visual style',
          icon: Icons.palette,
          builder: (context, controller) {
            return WizardChoiceStep(
              controller: controller,
              dataKey: 'theme_mode',
              choices: const [
                WizardChoice(
                  value: 'system',
                  title: 'System Default',
                  subtitle: 'Follow your device settings',
                  icon: Icons.auto_mode,
                ),
                WizardChoice(
                  value: 'light',
                  title: 'Light Theme',
                  subtitle: 'Bright and clean interface',
                  icon: Icons.light_mode,
                ),
                WizardChoice(
                  value: 'dark',
                  title: 'Dark Theme',
                  subtitle: 'Easy on the eyes',
                  icon: Icons.dark_mode,
                ),
              ],
            );
          },
        ),

        // UI System selection
        WizardStep(
          id: 'ui_system',
          title: 'UI Style',
          subtitle: 'Choose your preferred interface style',
          icon: Icons.design_services,
          builder: (context, controller) {
            return WizardChoiceStep(
              controller: controller,
              dataKey: 'ui_system',
              choices: const [
                WizardChoice(
                  value: 'material',
                  title: 'Material Design',
                  subtitle: 'Google\'s design language',
                  icon: Icons.android,
                ),
                WizardChoice(
                  value: 'cupertino',
                  title: 'Cupertino',
                  subtitle: 'iOS-style interface',
                  icon: Icons.phone_iphone,
                ),
                WizardChoice(
                  value: 'forui',
                  title: 'ForUI',
                  subtitle: 'Minimal and modern design',
                  icon: Icons.straighten,
                ),
              ],
            );
          },
        ),

        // Notifications
        WizardStep(
          id: 'notifications',
          title: 'Notification preferences',
          subtitle: 'Choose what you want to be notified about',
          icon: Icons.notifications,
          builder: (context, controller) {
            return WizardChoiceStep(
              controller: controller,
              dataKey: 'notification_types',
              title: 'Enable notifications for:',
              multiSelect: true,
              choices: const [
                WizardChoice(
                  value: 'updates',
                  title: 'App Updates',
                  subtitle: 'New features and improvements',
                  icon: Icons.system_update,
                ),
                WizardChoice(
                  value: 'tips',
                  title: 'Tips & Tricks',
                  subtitle: 'Helpful usage tips',
                  icon: Icons.lightbulb,
                ),
                WizardChoice(
                  value: 'news',
                  title: 'News & Announcements',
                  subtitle: 'Important news and updates',
                  icon: Icons.newspaper,
                ),
              ],
            );
          },
        ),
      ],
      onComplete: (controller) async {
        final data = controller.getAllData();
        AppShellLogger.i('Configuration completed: $data');

        // Apply the settings
        final settingsStore = getIt<AppShellSettingsStore>();

        final themeMode = data['theme_mode'] as String?;
        if (themeMode != null) {
          switch (themeMode) {
            case 'light':
              settingsStore.setThemeMode(ThemeMode.light);
              break;
            case 'dark':
              settingsStore.setThemeMode(ThemeMode.dark);
              break;
            case 'system':
              settingsStore.setThemeMode(ThemeMode.system);
              break;
          }
        }

        final uiSystem = data['ui_system'] as String?;
        if (uiSystem != null) {
          settingsStore.setUiSystem(uiSystem);
        }
      },
    );

    final controller = WizardController(
      flow: wizardFlow,
      preferencesService: prefsService,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WizardScreen(
          controller: controller,
          onCancel: () {
            controller.dispose();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startSurveyWizard(BuildContext context) {
    final wizardFlow = WizardFlow(
      id: 'user_survey',
      title: 'User Feedback Survey',
      description: 'Help us improve your experience',
      showProgress: true,
      progressStyle: WizardProgressStyle.linear,
      steps: [
        WizardStep(
          id: 'rating',
          title: 'How would you rate our app?',
          icon: Icons.star,
          builder: (context, controller) {
            return WizardChoiceStep(
              controller: controller,
              dataKey: 'rating',
              choices: const [
                WizardChoice(value: '5', title: '⭐⭐⭐⭐⭐ Excellent'),
                WizardChoice(value: '4', title: '⭐⭐⭐⭐ Good'),
                WizardChoice(value: '3', title: '⭐⭐⭐ Average'),
                WizardChoice(value: '2', title: '⭐⭐ Poor'),
                WizardChoice(value: '1', title: '⭐ Very Poor'),
              ],
            );
          },
        ),
        WizardStep(
          id: 'feedback',
          title: 'Additional feedback',
          subtitle: 'Tell us what we can improve (optional)',
          canSkip: true,
          icon: Icons.feedback,
          builder: (context, controller) {
            return WizardTextInputStep(
              controller: controller,
              dataKey: 'feedback',
              label: 'Your feedback',
              hint: 'What can we do better?',
              maxLines: 4,
            );
          },
        ),
      ],
      onComplete: (controller) async {
        AppShellLogger.i('Survey completed: ${controller.getAllData()}');
      },
    );

    final controller = WizardController(flow: wizardFlow);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WizardScreen(
          controller: controller,
          onCancel: () {
            controller.dispose();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _startProgressStyleWizard(BuildContext context) {
    final progressStyles = [
      WizardProgressStyle.linear,
      WizardProgressStyle.circular,
      WizardProgressStyle.steps,
      WizardProgressStyle.numbered,
    ];

    int currentStyleIndex = 0;

    void showNextStyle() {
      if (currentStyleIndex >= progressStyles.length) return;

      final style = progressStyles[currentStyleIndex];
      final styleName = style.name.toUpperCase();

      final wizardFlow = WizardFlow(
        id: 'progress_demo_${style.name}',
        title: '$styleName Progress Demo',
        description: 'Demonstrating $styleName progress indicator',
        showProgress: true,
        progressStyle: style,
        steps: List.generate(
          4,
          (index) => WizardStep(
            id: 'step_${index + 1}',
            title: 'Step ${index + 1}',
            subtitle: 'This is step ${index + 1} of 4',
            icon: Icons.looks_one,
            builder: (context, controller) {
              final styles = context.adaptiveStyle;
              return WizardInfoStep(
                controller: controller,
                child: Column(
                  children: [
                    Text(
                      'This wizard uses the $styleName progress style.',
                      style: styles.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: styles.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Progress: ${((index + 1) / 4 * 100).round()}%',
                        style: styles.titleMedium,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        onComplete: (controller) async {
          currentStyleIndex++;
          if (currentStyleIndex < progressStyles.length) {
            // Show next style
            Future.delayed(const Duration(milliseconds: 500), showNextStyle);
          }
        },
      );

      final controller = WizardController(flow: wizardFlow);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WizardScreen(
            controller: controller,
            onCancel: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }

    showNextStyle();
  }

  static String _formatInterests(dynamic value) {
    if (value is List<String>) {
      if (value.isEmpty) return 'None selected';
      return value.join(', ');
    }
    return value?.toString() ?? 'None';
  }
}
