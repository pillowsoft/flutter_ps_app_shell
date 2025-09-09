import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class ResponsiveNavigationDemoScreen extends StatefulWidget {
  const ResponsiveNavigationDemoScreen({super.key});

  @override
  State<ResponsiveNavigationDemoScreen> createState() =>
      _ResponsiveNavigationDemoScreenState();
}

class _ResponsiveNavigationDemoScreenState
    extends State<ResponsiveNavigationDemoScreen> {
  bool _showHiddenRoute = true;

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final isVeryWideScreen = screenWidth > 1200;

    // Calculate what navigation type should be shown
    final visibleRoutes =
        _getExampleRoutes().where((route) => route.showInNavigation).toList();
    String expectedNavType;
    if (isVeryWideScreen) {
      expectedNavType = "Sidebar (Desktop)";
    } else if (isWideScreen) {
      expectedNavType = "Navigation Rail (Tablet)";
    } else if (visibleRoutes.length <= 5) {
      expectedNavType = "Bottom Navigation (Mobile ≤5 routes)";
    } else {
      expectedNavType = "Drawer Navigation (Mobile >5 routes)";
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ui.pageTitle('Responsive Navigation Demo'),
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Navigation Analysis',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                    context, 'Screen Width', '${screenWidth.toInt()}px'),
                _buildInfoRow(
                    context,
                    'Screen Type',
                    isVeryWideScreen
                        ? 'Desktop (>1200px)'
                        : isWideScreen
                            ? 'Tablet (600-1200px)'
                            : 'Mobile (<600px)'),
                _buildInfoRow(
                    context, 'Total Routes', '${_getExampleRoutes().length}'),
                _buildInfoRow(
                    context, 'Visible Routes', '${visibleRoutes.length}'),
                _buildInfoRow(context, 'Expected Navigation', expectedNavType),
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
                  'Navigation Logic',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Responsive Breakpoints:',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('• Desktop (>1200px): Sidebar with collapse/expand'),
                      Text('• Tablet (600-1200px): Navigation rail'),
                      Text(
                          '• Mobile (<600px) + ≤5 visible routes: Bottom tabs'),
                      Text('• Mobile (<600px) + >5 visible routes: Drawer'),
                      const SizedBox(height: 12),
                      Text(
                        'Key: Only routes with showInNavigation: true count toward the 5-route threshold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
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
                  'Hidden Routes Demo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Some routes should be accessible via code but not appear in navigation. '
                  'Perfect for workflow screens like camera, checkout, or onboarding.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Show "Workflow Route" in navigation:'),
                    ),
                    Switch(
                      value: _showHiddenRoute,
                      onChanged: (value) {
                        setState(() {
                          _showHiddenRoute = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example Implementation:',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '''AppRoute(
  title: 'Camera',
  path: '/camera',
  icon: Icons.camera,
  builder: (context, state) => CameraScreen(),
  showInNavigation: false, // Hidden from navigation
)

// Still accessible via code:
context.push('/camera');''',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ),
                    ],
                  ),
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
                  'Test Different Screen Sizes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Resize your browser window or rotate your device to see the navigation adapt automatically.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton(context, 'Mobile View', '400px', () {
                      // This is just informational - can't actually resize window
                      _showTestInfo(context, 'Mobile View',
                          'Resize window to <600px width to see mobile navigation');
                    }),
                    _buildTestButton(context, 'Tablet View', '800px', () {
                      _showTestInfo(context, 'Tablet View',
                          'Resize window to 600-1200px width to see navigation rail');
                    }),
                    _buildTestButton(context, 'Desktop View', '1400px', () {
                      _showTestInfo(context, 'Desktop View',
                          'Resize window to >1200px width to see sidebar');
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, String title, String size, VoidCallback onPressed) {
    final ui = getAdaptiveFactory(context);
    return ui.outlinedButton(
      label: '$title ($size)',
      onPressed: onPressed,
    );
  }

  void _showTestInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<AppRoute> _getExampleRoutes() {
    return [
      AppRoute(
        title: 'Home',
        path: '/home',
        icon: Icons.home,
        builder: (context, state) => const SizedBox(),
        showInNavigation: true,
      ),
      AppRoute(
        title: 'Profile',
        path: '/profile',
        icon: Icons.person,
        builder: (context, state) => const SizedBox(),
        showInNavigation: true,
      ),
      AppRoute(
        title: 'Settings',
        path: '/settings',
        icon: Icons.settings,
        builder: (context, state) => const SizedBox(),
        showInNavigation: true,
      ),
      AppRoute(
        title: 'About',
        path: '/about',
        icon: Icons.info,
        builder: (context, state) => const SizedBox(),
        showInNavigation: true,
      ),
      AppRoute(
        title: 'Workflow Route',
        path: '/workflow',
        icon: Icons.camera,
        builder: (context, state) => const SizedBox(),
        showInNavigation: _showHiddenRoute, // This toggles based on demo
      ),
    ];
  }
}
