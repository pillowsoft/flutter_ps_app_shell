import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:go_router/go_router.dart';

class DetailScreen extends StatefulWidget {
  final String title;
  final int level;
  final bool canPushMore;
  final bool autoAdvance;

  const DetailScreen({
    super.key,
    required this.title,
    required this.level,
    this.canPushMore = true,
    this.autoAdvance = false,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-advance to next level if requested (for multiple screen demo)
    if (widget.autoAdvance && widget.level < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _pushNextLevel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final nav = getIt<NavigationService>();
    final canPop = GoRouter.of(context).canPop();
    final navigationDepth = _estimateNavigationDepth();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Header with level info
        ui.card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.layers,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                ui.text(
                  'Navigation Level ${widget.level}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                ui.text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Navigation State Info
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Navigation State',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildInfoRow(
                    ui,
                    'Can Pop Back:',
                    canPop ? 'Yes' : 'No',
                    canPop ? Icons.check_circle : Icons.cancel,
                    canPop ? Colors.green : Colors.red),
                _buildInfoRow(ui, 'Estimated Depth:', '$navigationDepth levels',
                    Icons.layers, Colors.blue),
                _buildInfoRow(
                    ui,
                    'Back Button Shown:',
                    canPop ? 'Yes' : 'No (Drawer)',
                    canPop ? Icons.arrow_back : Icons.menu,
                    canPop ? Colors.green : Colors.orange),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Navigation Actions
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Navigation Actions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                if (widget.canPushMore && widget.level < 5) ...[
                  ui.buttonWithIcon(
                    onPressed: _pushNextLevel,
                    icon: const Icon(Icons.arrow_forward),
                    label: 'Push Next Level',
                  ),
                  const SizedBox(height: 12),
                ],
                if (canPop) ...[
                  ui.outlinedButtonWithIcon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: 'Go Back (Pop)',
                  ),
                  const SizedBox(height: 12),
                ],
                ui.outlinedButtonWithIcon(
                  onPressed: () => nav.go('/'),
                  icon: const Icon(Icons.home),
                  label: 'Go to Home (Replace)',
                ),
                const SizedBox(height: 12),
                ui.outlinedButtonWithIcon(
                  onPressed: () => _showModalDemo(ui),
                  icon: const Icon(Icons.layers),
                  label: 'Show Modal (Preserves Stack)',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Explanation
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('What to Notice',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildNoticeItem(
                    ui,
                    'App Bar',
                    canPop
                        ? 'Shows back button instead of drawer/hamburger menu'
                        : 'Shows drawer button (no navigation history)'),
                _buildNoticeItem(ui, 'Mobile Behavior',
                    'On small screens (${MediaQuery.of(context).size.width.toInt()}px), navigation prioritizes back button over drawer access'),
                _buildNoticeItem(ui, 'Back Action',
                    'Back button or gesture navigates to the previous screen in the stack'),
                _buildNoticeItem(ui, 'Go Navigation',
                    'Using "Go" actions will replace the current route and remove back button'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(AdaptiveWidgetFactory ui, String label, String value,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          ui.text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          ui.text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(
      AdaptiveWidgetFactory ui, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                ui.text(description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _estimateNavigationDepth() {
    // Estimate based on level and whether we can pop
    return GoRouter.of(context).canPop() ? widget.level + 1 : 1;
  }

  void _pushNextLevel() {
    final nextLevel = widget.level + 1;
    final autoAdvance = widget.autoAdvance && widget.level < 2;
    context.push(
        '/navigation/detail/$nextLevel${autoAdvance ? '?autoAdvance=true' : ''}');
  }

  void _showModalDemo(AdaptiveWidgetFactory ui) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ui.text('Modal at Level ${widget.level}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ui.text('This modal appears over the current navigation level.'),
            const SizedBox(height: 8),
            ui.text('Notice that:'),
            const SizedBox(height: 4),
            ui.text('• Back button behavior is preserved'),
            ui.text('• Navigation stack remains intact'),
            ui.text('• Modal has its own close action'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: ui.text('Close Modal'),
          ),
          if (GoRouter.of(context).canPop())
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Pop the screen
              },
              child: ui.text('Close & Go Back'),
            ),
        ],
      ),
    );
  }
}
