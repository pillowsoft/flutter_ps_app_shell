import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class LargeTitleDemoScreen extends StatelessWidget {
  const LargeTitleDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ui.sliverScaffold(
      largeTitle: const Text('Large Title Demo'),
      actions: [
        ui.iconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog(context),
          tooltip: 'About Large Titles',
        ),
      ],
      slivers: [
        // Page title for non-iOS platforms
        SliverToBoxAdapter(
          child: ui.pageTitle('Large Title Demo'),
        ),

        // Demo content explaining the feature
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iOS Large Title Behavior',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'On iOS (Cupertino mode), this screen uses CupertinoSliverNavigationBar '
                      'to provide the native iOS large title experience. The title collapses '
                      'as you scroll, providing more space for content.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Material & ForUI Behavior',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'On Material and ForUI platforms, this uses SliverAppBar with '
                      'FlexibleSpaceBar to provide a similar collapsing header effect. '
                      'The pageTitle() method provides platform-appropriate headers.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Scrollable content to demonstrate collapsing behavior
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return ui.card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ui.listTile(
                  title: Text('List Item ${index + 1}'),
                  subtitle: Text(
                      'This is item number ${index + 1} in the scrollable list. '
                      'Scroll up to see the large title collapse!'),
                  leading: Icon(
                    Icons.list_alt,
                    color: Theme.of(context).primaryColor,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showItemDetail(context, index + 1),
                ),
              );
            },
            childCount: 20,
          ),
        ),

        // Code examples
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Examples',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildCodeExample(
                      context,
                      '1. Large Title AppBar',
                      '''ui.scaffold(
  appBar: ui.appBar(
    title: const Text('Settings'),
    largeTitle: true,  // Enable iOS large title
  ),
  body: // your content
)''',
                    ),
                    const SizedBox(height: 16),
                    _buildCodeExample(
                      context,
                      '2. Page Title Helper',
                      '''// Material/ForUI: Shows prominent header
// Cupertino: Returns SizedBox.shrink()
ui.pageTitle('Settings')''',
                    ),
                    const SizedBox(height: 16),
                    _buildCodeExample(
                      context,
                      '3. Sliver Scaffold',
                      '''ui.sliverScaffold(
  largeTitle: const Text('Settings'),
  slivers: [
    SliverToBoxAdapter(
      child: ui.pageTitle('Settings'),
    ),
    // Your content slivers here
  ],
)''',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildCodeExample(BuildContext context, String title, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            code,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    ui.showDialog(
      context: context,
      title: const Text('Large Title Feature'),
      content: const Text(
        'This feature provides native iOS large title behavior when using '
        'Cupertino mode, while gracefully adapting to Material and ForUI '
        'design systems with equivalent collapsing header functionality.\n\n'
        'The sliverScaffold automatically handles sliver integration and '
        'provides consistent behavior across all UI systems.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _showItemDetail(BuildContext context, int itemNumber) {
    final ui = getAdaptiveFactory(context);

    ui.showDialog(
      context: context,
      title: Text('Item $itemNumber'),
      content: Text('You tapped on list item number $itemNumber!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
