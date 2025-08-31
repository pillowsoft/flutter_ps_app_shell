import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:get_it/get_it.dart';
import 'features/home/home_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/adaptive_demo/adaptive_demo_screen.dart';
import 'features/services_demo/services_demo_screen.dart';
import 'features/service_inspector/service_inspector_screen.dart';
import 'features/wizard_demo/wizard_demo_screen.dart';
import 'features/cloud_sync/cloud_sync_demo_screen.dart';
// import 'features/tasks/task_management_screen.dart';
import 'features/performance/performance_demo_screen.dart';
import 'features/accessibility/accessibility_demo_screen.dart';
// import 'features/error_handling/error_demo_screen.dart';
import 'features/adaptive_components/adaptive_components_demo_screen.dart';
import 'features/plugin_demo/plugin_demo_screen.dart';
import 'features/button_demo/button_demo_screen.dart';
import 'features/large_title_demo/large_title_demo_screen.dart';
import 'features/popup_inkwell_demo/popup_inkwell_demo_screen.dart';
import 'features/auth_demo/auth_demo_screen.dart';
import 'features/cloudflare_demo/cloudflare_demo_screen.dart';
import 'features/navigation_demo/navigation_demo_screen.dart';
import 'features/navigation_demo/detail_screen.dart';
import 'features/navigation_demo/nested_screen.dart';

/// UI System selector widget for the app bar
class UISystemSelector extends StatelessWidget {
  const UISystemSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = GetIt.I<AppShellSettingsStore>();

    return Tooltip(
      message: 'Change UI System',
      child: IconButton(
        icon: const Icon(Icons.palette),
        onPressed: () {
          _showUISystemSelector(context, settingsStore);
        },
      ),
    );
  }

  void _showUISystemSelector(
      BuildContext context, AppShellSettingsStore settingsStore) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + buttonSize.height,
        offset.dx + buttonSize.width,
        offset.dy + buttonSize.height + 200, // Adjust height as needed
      ),
      items: [
        _buildMenuItem(
          context: context,
          value: 'material',
          icon: Icons.android,
          label: 'Material',
          isSelected: settingsStore.uiSystem.value == 'material',
        ),
        _buildMenuItem(
          context: context,
          value: 'cupertino',
          icon: Icons.phone_iphone,
          label: 'Cupertino',
          isSelected: settingsStore.uiSystem.value == 'cupertino',
        ),
        _buildMenuItem(
          context: context,
          value: 'forui',
          icon: Icons.design_services,
          label: 'ForUI',
          isSelected: settingsStore.uiSystem.value == 'forui',
        ),
      ],
    ).then((selectedValue) {
      if (selectedValue != null) {
        // Change UI system immediately without delay
        try {
          settingsStore.setUiSystem(selectedValue);
          AppShellLogger.i('UI System changed to: $selectedValue');
        } catch (e) {
          AppShellLogger.e('Error changing UI system: $e');
        }
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem({
    required BuildContext context,
    required String value,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? primaryColor : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, color: primaryColor, size: 16),
          ],
        ],
      ),
    );
  }
}

void main() {
  // Load example plugins for testing
  final examplePlugins = getExamplePlugins();

  runShellApp(
    () async {
      return AppConfig(
        title: 'Flutter App Shell Demo',
        routes: [
          AppRoute(
            title: 'Home',
            path: '/',
            icon: Icons.home,
            builder: (context, state) => const HomeScreen(),
          ),
          AppRoute(
            title: 'Dashboard',
            path: '/dashboard',
            icon: Icons.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          AppRoute(
            title: 'Settings',
            path: '/settings',
            icon: Icons.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          AppRoute(
            title: 'Profile',
            path: '/profile',
            icon: Icons.person,
            builder: (context, state) => const ProfileScreen(),
          ),
          AppRoute(
            title: 'Adaptive UI',
            path: '/adaptive',
            icon: Icons.palette,
            builder: (context, state) => const AdaptiveDemoScreen(),
          ),
          AppRoute(
            title: 'Services',
            path: '/services',
            icon: Icons.build,
            builder: (context, state) => const ServicesDemoScreen(),
          ),
          AppRoute(
            title: 'Authentication',
            path: '/auth',
            icon: Icons.lock,
            builder: (context, state) => const AuthDemoScreen(),
          ),
          AppRoute(
            title: 'Navigation',
            path: '/navigation',
            icon: Icons.navigation,
            builder: (context, state) => const NavigationDemoScreen(),
            subRoutes: [
              AppRoute(
                title: 'Detail Screen',
                path: 'detail/:level',
                icon: Icons.layers,
                builder: (context, state) {
                  final level =
                      int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
                  final autoAdvance =
                      state.uri.queryParameters['autoAdvance'] == 'true';
                  final replace =
                      state.uri.queryParameters['replace'] == 'true';
                  return DetailScreen(
                    title:
                        replace ? 'Replaced Screen (No Back)' : 'Level $level',
                    level: level,
                    canPushMore: level < 4,
                    autoAdvance: autoAdvance,
                  );
                },
                showInNavigation: false,
              ),
              AppRoute(
                title: 'Deep Navigation',
                path: 'nested/:level',
                icon: Icons.account_tree,
                builder: (context, state) {
                  final level =
                      int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
                  return NestedScreen(
                    level: level,
                    maxLevels: 4,
                    subtitle:
                        level > 1 ? 'Pushed from Level ${level - 1}' : null,
                  );
                },
                showInNavigation: false,
              ),
            ],
          ),
          AppRoute(
            title: 'Inspector',
            path: '/inspector',
            icon: Icons.developer_board,
            builder: (context, state) => const ServiceInspectorScreen(),
          ),
          AppRoute(
            title: 'Wizard',
            path: '/wizard',
            icon: Icons.auto_stories,
            builder: (context, state) => const WizardDemoScreen(),
          ),
          AppRoute(
            title: 'Cloud Sync',
            path: '/cloud-sync',
            icon: Icons.cloud_sync,
            builder: (context, state) => const CloudSyncDemoScreen(),
          ),
          // Temporarily disabled due to ButtonVariant issues
          // AppRoute(
          //   title: 'Task Manager',
          //   path: '/tasks',
          //   icon: Icons.task_alt,
          //   builder: (context, state) => const TaskManagementScreen(),
          // ),
          AppRoute(
            title: 'Performance',
            path: '/performance',
            icon: Icons.speed,
            builder: (context, state) => const PerformanceDemoScreen(),
          ),
          AppRoute(
            title: 'Accessibility',
            path: '/accessibility',
            icon: Icons.accessibility,
            builder: (context, state) => const AccessibilityDemoScreen(),
          ),
          // Temporarily disabled due to compilation issues
          // AppRoute(
          //   title: 'Error Handling',
          //   path: '/error-demo',
          //   icon: Icons.error_outline,
          //   builder: (context, state) => const ErrorHandlingDemoScreen(),
          // ),
          AppRoute(
            title: 'Components',
            path: '/components',
            icon: Icons.widgets,
            builder: (context, state) => const AdaptiveComponentsDemoScreen(),
          ),
          AppRoute(
            title: 'Buttons',
            path: '/buttons',
            icon: Icons.smart_button,
            builder: (context, state) => const ButtonDemoScreen(),
          ),
          AppRoute(
            title: 'Large Title',
            path: '/large-title',
            icon: Icons.title,
            builder: (context, state) => const LargeTitleDemoScreen(),
          ),
          AppRoute(
            title: 'Popup & InkWell',
            path: '/popup-inkwell',
            icon: Icons.touch_app,
            builder: (context, state) => const PopupInkwellDemoScreen(),
          ),
          AppRoute(
            title: 'Plugins',
            path: '/plugins',
            icon: Icons.extension,
            builder: (context, state) => const PluginDemoScreen(),
          ),
          AppRoute(
            title: 'Cloudflare',
            path: '/cloudflare',
            icon: Icons.cloud,
            builder: (context, state) => const CloudflareDemoScreen(),
          ),
        ],
        actions: [
          AppShellAction(
            icon: Icons.palette,
            tooltip: 'UI System',
            onPressed: () {
              // This will be handled by the custom widget
            },
            customWidget: const UISystemSelector(),
          ),
          AppShellAction(
            icon: Icons.notifications_outlined,
            tooltip: 'Notifications',
            onPressed: () {
              AppShellLogger.i('Notifications clicked');
            },
          ),
          AppShellAction(
            icon: Icons.search,
            tooltip: 'Search',
            onPressed: () {
              AppShellLogger.i('Search clicked');
            },
          ),
        ],
        themeExtensions: (theme) {
          // Custom theme extensions can be added here
          return theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.blue,
              secondary: Colors.teal,
            ),
          );
        },
      );
    },
    // Enable plugins and pass the example plugins
    enablePlugins: true,
    pluginConfiguration: {
      'manualPlugins': examplePlugins,
    },
  );
}
