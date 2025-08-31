import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final styles = context.adaptiveStyle;

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return Center(
        key: ValueKey('profile_center_$uiSystem'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    ui.avatar(
                      radius: 60,
                      backgroundColor: styles.primaryContainer,
                      foregroundColor: styles.onPrimaryContainer,
                      text: 'JD',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'John Doe',
                      style: styles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'john.doe@example.com',
                      style: styles.bodyLarge.copyWith(
                        color: styles.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ui.buttonWithIcon(
                          onPressed: () {},
                          icon: Icon(ui.getIcon('settings')),
                          label: 'Edit Profile',
                        ),
                        const SizedBox(width: 12),
                        ui.outlinedButtonWithIcon(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                          label: 'Share',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              ui.divider(),
              const SizedBox(height: 32),

              // Stats Section
              Text(
                'Statistics',
                style: styles.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      ui,
                      styles,
                      'Projects',
                      '12',
                      ui.getIcon('folder'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      ui,
                      styles,
                      'Tasks',
                      '48',
                      Icons.task,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      ui,
                      styles,
                      'Hours',
                      '320',
                      Icons.timer,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Activity
              Text(
                'Recent Activity',
                style: styles.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._buildActivityItems(context, ui, styles),

              const SizedBox(height: 32),

              // Actions
              ui.card(
                child: Column(
                  children: [
                    ui.listTile(
                      leading: Icon(ui.getIcon('settings')),
                      title: const Text('Account Settings'),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () {},
                    ),
                    ui.divider(height: 1),
                    ui.listTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Privacy & Security'),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () {},
                    ),
                    ui.divider(height: 1),
                    ui.listTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      trailing: Icon(ui.getIcon('chevron_right')),
                      onTap: () {},
                    ),
                    ui.divider(height: 1),
                    ui.listTile(
                      leading: Icon(
                        Icons.logout,
                        color: styles.error,
                      ),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: styles.error,
                        ),
                      ),
                      onTap: () {},
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

  Widget _buildStatCard(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    String label,
    String value,
    IconData icon,
  ) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: styles.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: styles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: styles.bodySmall.copyWith(
              color: styles.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityItems(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
  ) {
    final activities = [
      (
        'Completed project setup',
        '2 hours ago',
        Icons.check_circle,
        Colors.green
      ),
      (
        'Updated dashboard',
        '5 hours ago',
        ui.getIcon('dashboard'),
        Colors.blue
      ),
      ('Added new feature', 'Yesterday', ui.getIcon('add'), Colors.orange),
      ('Fixed critical bug', '2 days ago', Icons.bug_report, Colors.red),
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ui.card(
          child: ui.listTile(
            leading: ui.avatar(
              backgroundColor: activity.$4.withValues(alpha: 0.1),
              child: Icon(
                activity.$3,
                color: activity.$4,
                size: 20,
              ),
            ),
            title: Text(activity.$1),
            subtitle: Text(activity.$2),
          ),
        ),
      );
    }).toList();
  }
}
