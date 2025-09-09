import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:go_router/go_router.dart';

class ActionNavigationDemoScreen extends StatelessWidget {
  const ActionNavigationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ui.pageTitle('App Bar Action Navigation'),
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigation Patterns',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app bar demonstrates different AppShellAction navigation patterns:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildPatternExample(
                  context,
                  icon: Icons.settings,
                  title: 'Declarative Route Navigation',
                  description:
                      'Settings button uses AppShellAction.route() for simple navigation to /settings',
                  codeExample: '''AppShellAction.route(
  icon: Icons.settings,
  tooltip: 'Settings',
  route: '/settings',
)''',
                ),
                const SizedBox(height: 16),
                _buildPatternExample(
                  context,
                  icon: Icons.person,
                  title: 'Context-Aware Navigation',
                  description:
                      'Profile button uses context for conditional navigation with onNavigate callback',
                  codeExample: '''AppShellAction.navigate(
  icon: Icons.person,
  tooltip: 'Profile',
  onNavigate: (context) {
    context.go('/profile');
  },
)''',
                ),
                const SizedBox(height: 16),
                _buildPatternExample(
                  context,
                  icon: Icons.info,
                  title: 'Push Navigation',
                  description:
                      'Inspector button uses context.push() to stack screens',
                  codeExample: '''AppShellAction.navigate(
  icon: Icons.info,
  tooltip: 'Inspector',
  onNavigate: (context) {
    context.push('/inspector');
  },
)''',
                ),
                const SizedBox(height: 16),
                _buildPatternExample(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Traditional Callback (Backward Compatible)',
                  description:
                      'Notifications button uses traditional VoidCallback for non-navigation actions',
                  codeExample: '''AppShellAction.callback(
  icon: Icons.notifications,
  tooltip: 'Notifications',
  onPressed: () {
    // Non-navigation action
  },
)''',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Navigation Examples',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Try these interactive navigation examples:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Interactive examples
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ui.button(
                      label: 'Go to Settings',
                      onPressed: () => context.go('/settings'),
                    ),
                    ui.button(
                      label: 'Push Inspector',
                      onPressed: () => context.push('/inspector'),
                    ),
                    ui.outlinedButton(
                      label: 'Navigate to Profile',
                      onPressed: () => context.go('/profile'),
                    ),
                    ui.outlinedButton(
                      label: 'Push Dashboard',
                      onPressed: () => context.push('/dashboard'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Replace Navigation Example',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Replace navigation removes the current screen from the stack:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ui.button(
                  label: 'Replace with Home (No Back Button)',
                  onPressed: () => context.replace('/'),
                ),
                ui.button(
                  label: 'Hidden Route Demo',
                  onPressed: () => context.push('/responsive-navigation'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Migration Guide',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildMigrationExample(
                  context,
                  title: 'Before (Required Service Locator)',
                  code: '''AppShellAction(
  icon: Icons.settings,
  tooltip: 'Settings',
  onPressed: () {
    final nav = GetIt.I<NavigationService>();
    nav.go('/settings');
  },
)''',
                  isOld: true,
                ),
                const SizedBox(height: 16),
                _buildMigrationExample(
                  context,
                  title: 'After (Clean & Direct)',
                  code: '''AppShellAction.route(
  icon: Icons.settings,
  tooltip: 'Settings',
  route: '/settings',
)''',
                  isOld: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternExample(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String codeExample,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codeExample,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationExample(
    BuildContext context, {
    required String title,
    required String code,
    required bool isOld,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isOld
              ? Colors.red.withOpacity(0.5)
              : Colors.green.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(8),
        color: (isOld ? Colors.red : Colors.green).withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOld ? Icons.close : Icons.check,
                color: isOld ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOld ? Colors.red : Colors.green,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
