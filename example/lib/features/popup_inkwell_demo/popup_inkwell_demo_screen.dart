import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class PopupInkwellDemoScreen extends StatefulWidget {
  const PopupInkwellDemoScreen({super.key});

  @override
  State<PopupInkwellDemoScreen> createState() => _PopupInkwellDemoScreenState();
}

class _PopupInkwellDemoScreenState extends State<PopupInkwellDemoScreen> {
  final _selectedAction = signal<String?>(null);
  final _tapCount = signal<int>(0);
  final _longPressCount = signal<int>(0);
  final _doubleTapCount = signal<int>(0);

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ui.pageTitle('Popup Menu & InkWell Demo'),
          const SizedBox(height: 24),

          // Popup Menu Button Section
          _buildSection(
            title: 'Popup Menu Button',
            description:
                'Platform-adaptive popup menus that prevent "No Material widget found" errors.',
            child: Column(
              children: [
                // Basic popup menu
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Basic Actions'),
                        ui.popupMenuButton<String>(
                          items: [
                            AdaptivePopupMenuItem(
                              value: 'edit',
                              leading: const Icon(Icons.edit),
                              child: const Text('Edit'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'duplicate',
                              leading: const Icon(Icons.copy),
                              child: const Text('Duplicate'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'share',
                              leading: const Icon(Icons.share),
                              child: const Text('Share'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'delete',
                              leading: const Icon(Icons.delete),
                              child: const Text('Delete'),
                              destructive: true,
                            ),
                          ],
                          onSelected: (value) {
                            _selectedAction.value = value;
                            ui.showSnackBar(context, 'Selected: $value');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom icon popup menu
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Custom Icon'),
                        ui.popupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          items: [
                            AdaptivePopupMenuItem(
                              value: 'settings',
                              leading: const Icon(Icons.settings),
                              child: const Text('Settings'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'help',
                              leading: const Icon(Icons.help),
                              child: const Text('Help'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'about',
                              leading: const Icon(Icons.info),
                              child: const Text('About'),
                            ),
                          ],
                          onSelected: (value) {
                            _selectedAction.value = value;
                            ui.showSnackBar(context, 'Selected: $value');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom child popup menu
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Custom Child'),
                        ui.popupMenuButton<String>(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Options'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          items: [
                            AdaptivePopupMenuItem(
                              value: 'option1',
                              child: const Text('Option 1'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'option2',
                              child: const Text('Option 2'),
                            ),
                            AdaptivePopupMenuItem(
                              value: 'disabled',
                              child: const Text('Disabled Option'),
                              enabled: false,
                            ),
                          ],
                          onSelected: (value) {
                            _selectedAction.value = value;
                            ui.showSnackBar(context, 'Selected: $value');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status display
                Watch((context) => Card(
                      color: _selectedAction.value != null
                          ? Colors.green.shade50
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 8),
                            Text(
                              _selectedAction.value != null
                                  ? 'Last selected: ${_selectedAction.value}'
                                  : 'No action selected yet',
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // InkWell Section
          _buildSection(
            title: 'InkWell Gesture Wrapper',
            description:
                'Platform-adaptive gesture handling with proper feedback that prevents Material widget errors.',
            child: Column(
              children: [
                // Basic tap example
                Card(
                  child: ui.inkWell(
                    onTap: () {
                      _tapCount.value++;
                      ui.showSnackBar(
                          context, 'Tapped! Count: ${_tapCount.value}');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.touch_app, size: 48),
                          SizedBox(height: 8),
                          Text('Tap me!',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Watch for platform-appropriate feedback'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-gesture example
                Card(
                  child: ui.inkWell(
                    onTap: () {
                      _tapCount.value++;
                    },
                    onLongPress: () {
                      _longPressCount.value++;
                      ui.showSnackBar(context,
                          'Long pressed! Count: ${_longPressCount.value}');
                    },
                    onDoubleTap: () {
                      _doubleTapCount.value++;
                      ui.showSnackBar(context,
                          'Double tapped! Count: ${_doubleTapCount.value}');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.touch_app, size: 48),
                          SizedBox(height: 8),
                          Text('Multi-Gesture',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Tap, Long Press, or Double Tap'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gesture counts display
                Watch((context) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Gesture Counts:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCountChip(
                                    'Taps', _tapCount.value, Icons.touch_app),
                                _buildCountChip('Long Press',
                                    _longPressCount.value, Icons.timer),
                                _buildCountChip('Double Tap',
                                    _doubleTapCount.value, Icons.double_arrow),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),

                // Complex content example
                Card(
                  child: ui.inkWell(
                    onTap: () {
                      ui.showSnackBar(context, 'Complex content tapped!');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child:
                                const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Complex Content',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    'This demonstrates InkWell working with complex layouts'),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    Icon(Icons.star_outline, size: 16),
                                    SizedBox(width: 8),
                                    Text('4/5'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Platform-specific notes
          _buildSection(
            title: 'Platform Behavior',
            description: 'How these components adapt across UI systems:',
            child: Column(
              children: [
                _buildPlatformNote(
                  'Material Design',
                  'PopupMenuButton: Native Material popup with ripple effects\nInkWell: Material wrapper prevents "No Material widget found" errors',
                  Icons.android,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildPlatformNote(
                  'Cupertino (iOS)',
                  'PopupMenuButton: CupertinoActionSheet from bottom of screen\nInkWell: GestureDetector with subtle visual feedback',
                  CupertinoIcons.device_phone_portrait,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildPlatformNote(
                  'ForUI',
                  'PopupMenuButton: Clean, flat popup menu with ForUI styling\nInkWell: Material wrapper with ForUI color scheme',
                  Icons.design_services,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildCountChip(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ],
      ),
    );
  }

  Widget _buildPlatformNote(
      String platform, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
