import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:go_router/go_router.dart';

class NestedScreen extends StatelessWidget {
  final int level;
  final int maxLevels;
  final String? subtitle;

  const NestedScreen({
    super.key,
    required this.level,
    this.maxLevels = 4,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final nav = getIt<NavigationService>();
    final canPop = GoRouter.of(context).canPop();
    final isLastLevel = level >= maxLevels;
    final progress = level / maxLevels;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Progress indicator
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ui.text('Navigation Progress',
                        style: Theme.of(context).textTheme.titleMedium),
                    ui.text('$level / $maxLevels',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                )),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  ui.text(subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          )),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Current level info
        ui.card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  _getLevelIcon(level),
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                ui.text(
                  'Level $level',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ui.text(
                  _getLevelDescription(level),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Navigation state
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Navigation State Analysis',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildStateItem(ui, 'Current Level', '$level',
                    Icons.location_on, Colors.blue),
                _buildStateItem(
                    ui,
                    'Can Pop Back',
                    canPop ? 'Yes' : 'No',
                    canPop ? Icons.check_circle : Icons.cancel,
                    canPop ? Colors.green : Colors.red),
                _buildStateItem(
                    ui,
                    'Back Button Shown',
                    canPop ? 'Yes' : 'No (Drawer)',
                    canPop ? Icons.arrow_back : Icons.menu,
                    canPop ? Colors.green : Colors.orange),
                _buildStateItem(ui, 'Progress', '${(progress * 100).toInt()}%',
                    Icons.trending_up, Colors.purple),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('Navigation Actions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                if (!isLastLevel) ...[
                  ui.buttonWithIcon(
                    onPressed: () => _goDeeper(context),
                    icon: const Icon(Icons.arrow_downward),
                    label: 'Go Deeper (Level ${level + 1})',
                  ),
                  const SizedBox(height: 12),
                ],
                if (canPop) ...[
                  ui.outlinedButtonWithIcon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_upward),
                    label: 'Go Back (Level ${level - 1})',
                  ),
                  const SizedBox(height: 12),
                ],
                ui.outlinedButtonWithIcon(
                  onPressed: () => _popToRoot(context),
                  icon: const Icon(Icons.home),
                  label: 'Pop to Root',
                ),
                const SizedBox(height: 12),
                ui.button(
                  onPressed: () => nav.go('/'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz),
                      const SizedBox(width: 8),
                      ui.text('Replace with Home (No Back)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isLastLevel) ...[
          const SizedBox(height: 24),
          ui.card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  ui.text(
                    'Maximum Depth Reached!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  ui.text(
                    'You\'ve navigated through $level levels. Notice how the back button consistently appears at each level.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Instructions
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ui.text('What This Demonstrates',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildDemoPoint(
                    ui,
                    'Back Button Priority',
                    'At every level, the back button appears instead of the drawer/hamburger menu',
                    context),
                _buildDemoPoint(
                    ui,
                    'Navigation Stack',
                    'Each "Go Back" action pops one level from the navigation stack',
                    context),
                _buildDemoPoint(
                    ui,
                    'UI System Support',
                    'Works consistently across Material, Cupertino, and ForUI themes',
                    context),
                _buildDemoPoint(
                    ui,
                    'Mobile UX Standard',
                    'Follows iOS/Android conventions where back buttons take precedence over drawer access',
                    context),
                _buildDemoPoint(
                    ui,
                    'Pop to Root',
                    'Can jump back to the beginning while preserving proper navigation state',
                    context),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStateItem(AdaptiveWidgetFactory ui, String label, String value,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: ui.text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
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
      ),
    );
  }

  Widget _buildDemoPoint(AdaptiveWidgetFactory ui, String title,
      String description, BuildContext context) {
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
              color: Colors.green,
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

  IconData _getLevelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      case 4:
        return Icons.looks_4;
      case 5:
        return Icons.looks_5;
      case 6:
        return Icons.looks_6;
      default:
        return Icons.more_horiz;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'First level of deep navigation. Back button should appear.';
      case 2:
        return 'Second level. Notice the back button is still present.';
      case 3:
        return 'Third level. Navigation stack is building up.';
      case 4:
        return 'Final level. You can navigate back through all levels.';
      default:
        return 'Deep navigation level $level';
    }
  }

  void _goDeeper(BuildContext context) {
    context.push('/navigation/nested/${level + 1}');
  }

  void _popToRoot(BuildContext context) {
    // Go back to the navigation demo root
    context.go('/navigation');
  }
}
