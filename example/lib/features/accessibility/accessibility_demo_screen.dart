import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'dart:math';

/// Comprehensive accessibility demo with keyboard navigation and screen reader support
class AccessibilityDemoScreen extends StatefulWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  State<AccessibilityDemoScreen> createState() =>
      _AccessibilityDemoScreenState();
}

class _AccessibilityDemoScreenState extends State<AccessibilityDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();

  // Accessibility settings
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReaderMode = false;
  double _textScale = 1.0;
  FocusNode? _lastFocusedNode;

  // Demo data
  List<AccessibleItem> _items = [];
  int _selectedIndex = -1;
  String _announcement = '';

  // Navigation
  final Map<LogicalKeySet, Intent> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.tab): NextFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift):
        PreviousFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): _MoveUpIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): _MoveDownIntent(),
    LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.space): ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): _EscapeIntent(),
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAccessibilitySettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: _reduceMotion ? 0 : 600),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _checkAccessibilitySettings() {
    // Check system accessibility settings
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      _highContrast = mediaQuery.highContrast;
      _reduceMotion = mediaQuery.disableAnimations;
      _textScale = mediaQuery.textScaler.scale(16) / 16;
    });
  }

  void _generateItems() {
    final random = Random();
    _items = List.generate(20, (index) {
      return AccessibleItem(
        id: index,
        title: 'Item ${index + 1}',
        description: _getDescription(index, random),
        category:
            ItemCategory.values[random.nextInt(ItemCategory.values.length)],
        isCompleted: random.nextBool(),
        priority: random.nextInt(5) + 1,
        dueDate: DateTime.now().add(Duration(days: random.nextInt(30))),
      );
    });
  }

  String _getDescription(int index, Random random) {
    final descriptions = [
      'Important task that requires immediate attention and careful review',
      'Standard workflow item for processing and approval',
      'Research and analysis project with detailed documentation',
      'Customer support ticket needing prompt response',
      'Development task involving complex implementation',
      'Meeting preparation with agenda and materials',
      'Quality assurance testing for new features',
      'Budget review and financial analysis report',
    ];
    return descriptions[random.nextInt(descriptions.length)];
  }

  void _announceToScreenReader(String message) {
    setState(() => _announcement = message);

    // Clear announcement after a short delay to allow multiple announcements
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _announcement = '');
      }
    });
  }

  void _selectItem(int index) {
    setState(() => _selectedIndex = index);

    final item = _items[index];
    _announceToScreenReader('Selected ${item.title}. ${item.description}. '
        'Priority ${item.priority}. ${item.isCompleted ? 'Completed' : 'Not completed'}.');
  }

  void _toggleItemCompletion(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
    });

    final item = _items[index];
    _announceToScreenReader(
        '${item.title} marked as ${item.isCompleted ? 'completed' : 'incomplete'}');

    HapticFeedback.lightImpact();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _announceToScreenReader('Form submitted successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Thank you for your feedback, ${_nameController.text}!'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _feedbackController.clear();

      HapticFeedback.mediumImpact();
    } else {
      _announceToScreenReader('Please fix the errors in the form');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final theme = _getAccessibleTheme(context);
      final ui = getAdaptiveFactory(context);

      return Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: {
            _MoveUpIntent: CallbackAction<_MoveUpIntent>(
              onInvoke: (_) => _moveFocus(-1),
            ),
            _MoveDownIntent: CallbackAction<_MoveDownIntent>(
              onInvoke: (_) => _moveFocus(1),
            ),
            _EscapeIntent: CallbackAction<_EscapeIntent>(
              onInvoke: (_) => _handleEscape(),
            ),
          },
          child: Scaffold(
            key: ValueKey('accessibility_scaffold_$uiSystem'),
            appBar: AppBar(
              title: const Text('Accessibility Demo'),
              backgroundColor: theme.appBarTheme.backgroundColor,
              foregroundColor: theme.appBarTheme.foregroundColor,
              actions: [
                IconButton(
                  icon: Icon(_screenReaderMode
                      ? Icons.accessibility
                      : Icons.accessibility_outlined),
                  onPressed: () {
                    setState(() => _screenReaderMode = !_screenReaderMode);
                    _announceToScreenReader(_screenReaderMode
                        ? 'Screen reader mode enabled'
                        : 'Screen reader mode disabled');
                  },
                  tooltip: 'Toggle screen reader optimization',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Accessibility Settings',
                  onSelected: _handleSettingsAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'contrast',
                      child: Row(
                        children: [
                          Icon(
                            _highContrast
                                ? Icons.contrast
                                : Icons.contrast_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('High Contrast'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'motion',
                      child: Row(
                        children: [
                          Icon(
                            _reduceMotion
                                ? Icons.motion_photos_off
                                : Icons.motion_photos_on,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Reduce Motion'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'textsize',
                      child: Row(
                        children: [
                          const Icon(Icons.text_fields, size: 20),
                          const SizedBox(width: 8),
                          const Text('Text Size'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Accessibility status bar
                  _buildAccessibilityStatusBar(theme),

                  // Live region for announcements
                  if (_announcement.isNotEmpty)
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: theme.colorScheme.primaryContainer,
                        width: double.infinity,
                        child: Text(
                          _announcement,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 16 * _textScale,
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Accessibility features demo
                            _buildFeaturesList(theme, ui),

                            const SizedBox(height: 32),

                            // Interactive items list
                            _buildItemsList(theme, ui),

                            const SizedBox(height: 32),

                            // Accessible form
                            _buildAccessibleForm(theme, ui),

                            const SizedBox(height: 32),

                            // Keyboard navigation help
                            _buildKeyboardHelp(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  ThemeData _getAccessibleTheme(BuildContext context) {
    final baseTheme = Theme.of(context);

    if (!_highContrast) return baseTheme;

    // High contrast theme
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: Colors.grey[200],
        onSurfaceVariant: Colors.black87,
        outline: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
        fontSizeFactor: _textScale,
      ),
    );
  }

  Widget _buildAccessibilityStatusBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          if (_screenReaderMode) ...[
            Icon(Icons.accessibility, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text('Screen Reader', style: TextStyle(fontSize: 12 * _textScale)),
            const SizedBox(width: 12),
          ],
          if (_highContrast) ...[
            Icon(Icons.contrast, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('High Contrast', style: TextStyle(fontSize: 12 * _textScale)),
            const SizedBox(width: 12),
          ],
          if (_reduceMotion) ...[
            Icon(Icons.motion_photos_off, size: 16, color: Colors.purple),
            const SizedBox(width: 4),
            Text('Reduced Motion', style: TextStyle(fontSize: 12 * _textScale)),
            const SizedBox(width: 12),
          ],
          if (_textScale != 1.0) ...[
            Icon(Icons.text_fields, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text('${(_textScale * 100).toInt()}%',
                style: TextStyle(fontSize: 12 * _textScale)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesList(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility Features',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24 * _textScale,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.keyboard,
          title: 'Keyboard Navigation',
          description:
              'Full keyboard support with tab, arrow keys, enter, and escape',
          isEnabled: true,
          theme: theme,
        ),
        _buildFeatureCard(
          icon: Icons.record_voice_over,
          title: 'Screen Reader Support',
          description: 'Semantic markup and live region announcements',
          isEnabled: _screenReaderMode,
          theme: theme,
        ),
        _buildFeatureCard(
          icon: Icons.contrast,
          title: 'High Contrast Mode',
          description: 'Enhanced color contrast for better visibility',
          isEnabled: _highContrast,
          theme: theme,
        ),
        _buildFeatureCard(
          icon: Icons.text_fields,
          title: 'Text Scaling',
          description: 'Respects system text size preferences',
          isEnabled: _textScale != 1.0,
          theme: theme,
        ),
        _buildFeatureCard(
          icon: Icons.motion_photos_off,
          title: 'Motion Reduction',
          description: 'Reduces animations for motion sensitivity',
          isEnabled: _reduceMotion,
          theme: theme,
        ),
        _buildFeatureCard(
          icon: Icons.vibration,
          title: 'Haptic Feedback',
          description: 'Tactile feedback for important interactions',
          isEnabled: true,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16 * _textScale,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14 * _textScale,
                  ),
                ),
              ],
            ),
          ),
          if (isEnabled)
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
              semanticLabel: 'Feature enabled',
            ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interactive Items List',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24 * _textScale,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use arrow keys to navigate, space or enter to toggle completion',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14 * _textScale,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          return _buildAccessibleListItem(item, index, theme);
        }),
      ],
    );
  }

  Widget _buildAccessibleListItem(
      AccessibleItem item, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: true,
      onTap: () => _selectItem(index),
      onIncrease: item.isCompleted ? null : () => _toggleItemCompletion(index),
      onDecrease: item.isCompleted ? () => _toggleItemCompletion(index) : null,
      label: '${item.title}. ${item.description}. Priority ${item.priority}. '
          '${item.isCompleted ? 'Completed' : 'Not completed'}. '
          'Double tap to toggle completion.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectItem(index),
            onDoubleTap: () => _toggleItemCompletion(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Completion checkbox
                  Semantics(
                    label: item.isCompleted ? 'Completed' : 'Not completed',
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: item.isCompleted
                          ? Icon(
                              Icons.check,
                              color: theme.colorScheme.onPrimary,
                              size: 16,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.category.icon,
                      color: item.category.color,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16 * _textScale,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            // Priority indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(item.priority)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'P${item.priority}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getPriorityColor(item.priority),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12 * _textScale,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14 * _textScale,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${_formatDate(item.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12 * _textScale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibleForm(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessible Form Example',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24 * _textScale,
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Name field
              Semantics(
                label: 'Full Name',
                textField: true,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    helperText: 'This field is required',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 16 * _textScale),
                ),
              ),

              const SizedBox(height: 16),

              // Email field
              Semantics(
                label: 'Email Address',
                textField: true,
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    hintText: 'Enter your email address',
                    helperText: 'We will never share your email',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 16 * _textScale),
                ),
              ),

              const SizedBox(height: 16),

              // Feedback field
              Semantics(
                label: 'Feedback',
                textField: true,
                multiline: true,
                child: TextFormField(
                  controller: _feedbackController,
                  decoration: InputDecoration(
                    labelText: 'Feedback',
                    hintText:
                        'Tell us what you think about our accessibility features',
                    helperText: 'Optional field for additional comments',
                    prefixIcon: const Icon(Icons.message),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(fontSize: 16 * _textScale),
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Submit feedback form',
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.send),
                    label: Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16 * _textScale),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardHelp(ThemeData theme) {
    final shortcuts = [
      ('Tab', 'Navigate forward'),
      ('Shift + Tab', 'Navigate backward'),
      ('Arrow Keys', 'Navigate list items'),
      ('Enter / Space', 'Activate focused element'),
      ('Escape', 'Cancel or go back'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keyboard Shortcuts',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24 * _textScale,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: shortcuts.map((shortcut) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shortcut.$1,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12 * _textScale,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shortcut.$2,
                        style: TextStyle(fontSize: 14 * _textScale),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _moveFocus(int direction) {
    if (_selectedIndex == -1) {
      _selectItem(0);
    } else {
      final newIndex = (_selectedIndex + direction).clamp(0, _items.length - 1);
      if (newIndex != _selectedIndex) {
        _selectItem(newIndex);
      }
    }
  }

  void _handleEscape() {
    if (_selectedIndex != -1) {
      setState(() => _selectedIndex = -1);
      _announceToScreenReader('Selection cleared');
    }
  }

  void _handleSettingsAction(String action) {
    switch (action) {
      case 'contrast':
        setState(() => _highContrast = !_highContrast);
        _announceToScreenReader(
            _highContrast ? 'High contrast enabled' : 'High contrast disabled');
        break;
      case 'motion':
        setState(() => _reduceMotion = !_reduceMotion);
        _announceToScreenReader(_reduceMotion
            ? 'Motion reduction enabled'
            : 'Motion reduction disabled');
        // Update animation duration
        _animationController.duration =
            Duration(milliseconds: _reduceMotion ? 0 : 600);
        break;
      case 'textsize':
        _showTextSizeDialog();
        break;
    }
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current size: ${(_textScale * 100).toInt()}%'),
            const SizedBox(height: 16),
            Slider(
              value: _textScale,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${(_textScale * 100).toInt()}%',
              onChanged: (value) {
                setState(() => _textScale = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0) return 'In $diff days';
    return '${-diff} days ago';
  }
}

// Supporting classes

class AccessibleItem {
  final int id;
  final String title;
  final String description;
  final ItemCategory category;
  final bool isCompleted;
  final int priority;
  final DateTime dueDate;

  AccessibleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.priority,
    required this.dueDate,
  });

  AccessibleItem copyWith({
    int? id,
    String? title,
    String? description,
    ItemCategory? category,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
  }) {
    return AccessibleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

enum ItemCategory {
  work,
  personal,
  health,
  finance,
  education;

  IconData get icon {
    switch (this) {
      case ItemCategory.work:
        return Icons.work;
      case ItemCategory.personal:
        return Icons.person;
      case ItemCategory.health:
        return Icons.favorite;
      case ItemCategory.finance:
        return Icons.attach_money;
      case ItemCategory.education:
        return Icons.school;
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.work:
        return Colors.blue;
      case ItemCategory.personal:
        return Colors.purple;
      case ItemCategory.health:
        return Colors.red;
      case ItemCategory.finance:
        return Colors.green;
      case ItemCategory.education:
        return Colors.orange;
    }
  }
}

// Custom intents for keyboard navigation
class _MoveUpIntent extends Intent {}

class _MoveDownIntent extends Intent {}

class _EscapeIntent extends Intent {}
