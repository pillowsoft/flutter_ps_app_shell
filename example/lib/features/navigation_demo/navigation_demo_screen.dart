import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:go_router/go_router.dart';
import 'detail_screen.dart';
import 'nested_screen.dart';

class NavigationDemoScreen extends StatefulWidget {
  const NavigationDemoScreen({super.key});

  @override
  State<NavigationDemoScreen> createState() => _NavigationDemoScreenState();
}

class _NavigationDemoScreenState extends State<NavigationDemoScreen> {
  int _pushCount = 0;

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final nav = getIt<NavigationService>();
    final canPop = GoRouter.of(context).canPop();
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final useMobileDrawer = !isWideScreen && _getRouteCount() > 5;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ui.pageTitle('Navigation Demo'),

        const SizedBox(height: 16),

        // Navigation State Section
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Navigation State',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildStateRow(
                  ui,
                  'Can Pop Navigation:',
                  canPop ? 'Yes (Back Button)' : 'No (Root Screen)',
                  canPop ? Colors.green : Colors.orange,
                  canPop ? Icons.arrow_back : Icons.home,
                ),
                const SizedBox(height: 8),
                _buildStateRow(
                  ui,
                  'Screen Width:',
                  '${MediaQuery.of(context).size.width.toInt()}px',
                  isWideScreen ? Colors.blue : Colors.purple,
                  isWideScreen ? Icons.desktop_windows : Icons.phone_android,
                ),
                const SizedBox(height: 8),
                _buildStateRow(
                  ui,
                  'Navigation Mode:',
                  useMobileDrawer
                      ? 'Mobile Drawer'
                      : (isWideScreen ? 'Desktop/Rail' : 'Bottom Nav'),
                  useMobileDrawer ? Colors.red : Colors.blue,
                  useMobileDrawer
                      ? Icons.menu
                      : (isWideScreen ? Icons.view_sidebar : Icons.navigation),
                ),
                const SizedBox(height: 8),
                _buildStateRow(
                  ui,
                  'App Bar Leading:',
                  _getLeadingButtonType(canPop, useMobileDrawer),
                  canPop ? Colors.green : Colors.orange,
                  canPop ? Icons.arrow_back : Icons.menu,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Push Navigation Examples
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Push Navigation (Creates Back Button)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ui.buttonWithIcon(
                  onPressed: () => _pushDetailScreen(),
                  icon: const Icon(Icons.open_in_new),
                  label: 'Push Detail Screen',
                ),
                const SizedBox(height: 12),
                ui.buttonWithIcon(
                  onPressed: () => _pushMultipleScreens(),
                  icon: const Icon(Icons.layers),
                  label: 'Push Multiple Screens (Stack)',
                ),
                const SizedBox(height: 12),
                ui.outlinedButtonWithIcon(
                  onPressed: () => _pushAndReplace(),
                  icon: const Icon(Icons.swap_horizontal_circle),
                  label: 'Push + Replace (No Back)',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // GoRouter Navigation Examples
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('GoRouter Navigation (Replaces Route)',
                    style: Theme.of(context).textTheme.titleMedium),
                ui.text('These will show drawer button, not back button',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ui.outlinedButtonWithIcon(
                        onPressed: () => nav.go('/dashboard'),
                        icon: const Icon(Icons.dashboard),
                        label: 'Go to Dashboard',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ui.outlinedButtonWithIcon(
                        onPressed: () => nav.go('/settings'),
                        icon: const Icon(Icons.settings),
                        label: 'Go to Settings',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Modal Navigation Examples
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Modal Navigation (Preserves Back Button)',
                    style: Theme.of(context).textTheme.titleMedium),
                ui.text(
                    'Modals appear over current screen without affecting navigation state',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ui.button(
                        onPressed: () => _showBottomSheet(ui),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.vertical_align_bottom),
                            const SizedBox(width: 8),
                            ui.text('Show Bottom Sheet'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ui.button(
                        onPressed: () => _showDialog(ui),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline),
                            const SizedBox(width: 8),
                            ui.text('Show Dialog'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Deep Navigation Example
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Deep Navigation Testing',
                    style: Theme.of(context).textTheme.titleMedium),
                ui.text(
                    'Navigate through multiple levels to test back button behavior',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        )),
                const SizedBox(height: 16),
                ui.buttonWithIcon(
                  onPressed: () => _startDeepNavigation(),
                  icon: const Icon(Icons.account_tree),
                  label: 'Start Deep Navigation Flow',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Instructions
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('How to Test',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildInstructionItem(ui, '1.',
                    'Resize window to see mobile/desktop navigation modes'),
                _buildInstructionItem(
                    ui, '2.', 'Push screens to see back button appear'),
                _buildInstructionItem(ui, '3.',
                    'Use "Go" navigation to see drawer button return'),
                _buildInstructionItem(ui, '4.',
                    'Test across Material, Cupertino, and ForUI themes'),
                _buildInstructionItem(
                    ui, '5.', 'Try deep navigation to test navigation stack'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStateRow(AdaptiveWidgetFactory ui, String label, String value,
      Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        ui.text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: ui.text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(
      AdaptiveWidgetFactory ui, String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: ui.text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ui.text(instruction,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _getLeadingButtonType(bool canPop, bool useMobileDrawer) {
    if (!useMobileDrawer) return 'Sidebar/Rail Toggle';
    if (canPop) return 'Back Button';
    return 'Drawer/Hamburger Menu';
  }

  int _getRouteCount() {
    // This is a rough estimate - the actual app has ~17 routes
    return 17;
  }

  void _pushDetailScreen() {
    final path = '/navigation/detail/1';
    AppShellLogger.i('NavigationDemo: Attempting to push to: $path');
    try {
      context.push(path);
      AppShellLogger.i('NavigationDemo: Successfully pushed to: $path');
    } catch (e) {
      AppShellLogger.e('NavigationDemo: Failed to push to $path: $e');
    }
  }

  void _pushMultipleScreens() {
    final path = '/navigation/detail/1?autoAdvance=true';
    AppShellLogger.i(
        'NavigationDemo: Attempting to push multiple screens to: $path');
    try {
      context.push(path);
      AppShellLogger.i('NavigationDemo: Successfully pushed to: $path');
    } catch (e) {
      AppShellLogger.e('NavigationDemo: Failed to push to $path: $e');
    }
  }

  void _pushAndReplace() {
    context.go('/navigation/detail/1?replace=true');
  }

  void _startDeepNavigation() {
    final path = '/navigation/nested/1';
    AppShellLogger.i(
        'NavigationDemo: Attempting to start deep navigation to: $path');
    try {
      context.push(path);
      AppShellLogger.i('NavigationDemo: Successfully pushed to: $path');
    } catch (e) {
      AppShellLogger.e('NavigationDemo: Failed to push to $path: $e');
    }
  }

  void _showBottomSheet(AdaptiveWidgetFactory ui) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ui.text('Modal Bottom Sheet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ui.text(
                'This modal preserves the navigation state behind it. The back button should still work as expected after closing this sheet.'),
            const SizedBox(height: 24),
            ui.button(
              onPressed: () => Navigator.of(context).pop(),
              child: ui.text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(AdaptiveWidgetFactory ui) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ui.text('Navigation Dialog'),
        content: ui.text(
            'This dialog appears over the current screen without affecting the navigation stack. Back button behavior is preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: ui.text('Close'),
          ),
        ],
      ),
    );
  }
}
