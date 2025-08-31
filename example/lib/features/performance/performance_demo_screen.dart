import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'dart:math';
import 'dart:async';

/// Performance demonstration with large datasets and smooth animations
class PerformanceDemoScreen extends StatefulWidget {
  const PerformanceDemoScreen({super.key});

  @override
  State<PerformanceDemoScreen> createState() => _PerformanceDemoScreenState();
}

class _PerformanceDemoScreenState extends State<PerformanceDemoScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _metricsAnimationController;

  // Animations
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _listFade;
  late Animation<double> _metricsScale;

  // Performance metrics
  final List<FrameMetrics> _frameMetrics = [];
  Timer? _metricsTimer;
  double _averageFps = 60.0;
  double _memoryUsage = 0.0;
  int _renderObjects = 0;

  // Data generation
  List<PerformanceItem> _items = [];
  bool _isLoading = false;
  bool _isLargeDataset = false;
  int _currentDataSize = 1000;

  // UI State
  bool _showMetrics = true;
  ViewMode _viewMode = ViewMode.list;
  SortMode _sortMode = SortMode.none;
  String _searchQuery = '';
  List<PerformanceItem> _filteredItems = [];

  // Virtualization
  ScrollController _scrollController = ScrollController();
  double _itemHeight = 80.0;
  int _visibleItemCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateData(_currentDataSize);
    _startMetricsMonitoring();

    // Setup frame callback
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrameEnd);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateVisibleItems();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _metricsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    _listFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOut,
    ));

    _metricsScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _metricsAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _headerAnimationController.forward();
    _listAnimationController.forward();
    _metricsAnimationController.forward();
  }

  void _onFrameEnd(Duration timestamp) {
    if (!mounted) return;

    // Calculate FPS and other metrics
    final now = timestamp.inMilliseconds;
    if (_frameMetrics.isNotEmpty) {
      final recent = _frameMetrics
          .where((m) => now - m.timestamp.inMilliseconds < 1000)
          .toList();

      if (recent.isNotEmpty) {
        final fps = recent.length.toDouble();
        setState(() {
          _averageFps = fps;
        });
      }
    }
  }

  void _startMetricsMonitoring() {
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;

      setState(() {
        // Simulate memory usage calculation
        _memoryUsage =
            20.0 + (_items.length / 1000) * 5.0 + Random().nextDouble() * 10;
        _renderObjects = _visibleItemCount + 50 + Random().nextInt(20);
      });
    });
  }

  void _calculateVisibleItems() {
    final screenHeight = MediaQuery.of(context).size.height;
    _visibleItemCount = (screenHeight / _itemHeight).ceil() + 2;
  }

  Future<void> _generateData(int count, {bool append = false}) async {
    setState(() => _isLoading = true);

    // Simulate async data generation with progress
    final newItems = <PerformanceItem>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      // Add micro-delay for large datasets to show progress
      if (i % 100 == 0 && count > 1000) {
        await Future.delayed(const Duration(milliseconds: 1));
      }

      newItems.add(PerformanceItem(
        id: append ? _items.length + i : i,
        title: _generateTitle(random),
        subtitle: _generateSubtitle(random),
        value: random.nextDouble() * 1000,
        progress: random.nextDouble(),
        category: Category.values[random.nextInt(Category.values.length)],
        isImportant: random.nextBool(),
        timestamp: DateTime.now().subtract(Duration(
          minutes: random.nextInt(10080), // Up to 1 week ago
        )),
        metadata: _generateMetadata(random),
      ));
    }

    setState(() {
      if (append) {
        _items.addAll(newItems);
      } else {
        _items = newItems;
      }
      _currentDataSize = _items.length;
      _isLargeDataset = _items.length > 5000;
      _isLoading = false;
    });

    _applyFiltersAndSort();
    _animateListRefresh();
  }

  void _animateListRefresh() {
    _listAnimationController.reset();
    _listAnimationController.forward();
  }

  String _generateTitle(Random random) {
    final prefixes = [
      'Task',
      'Project',
      'Item',
      'Document',
      'Report',
      'Analysis',
      'Review'
    ];
    final suffixes = [
      'Alpha',
      'Beta',
      'Gamma',
      'Delta',
      'Prime',
      'Pro',
      'Advanced',
      'Standard'
    ];

    return '${prefixes[random.nextInt(prefixes.length)]} ${suffixes[random.nextInt(suffixes.length)]} ${random.nextInt(9999)}';
  }

  String _generateSubtitle(Random random) {
    final descriptions = [
      'High priority item requiring immediate attention',
      'Standard workflow item for processing',
      'Analysis result with detailed metrics',
      'Generated report for review and approval',
      'Automated process execution status',
      'User interaction data point',
      'System monitoring alert notification',
    ];

    return descriptions[random.nextInt(descriptions.length)];
  }

  Map<String, dynamic> _generateMetadata(Random random) {
    return {
      'source': ['API', 'Database', 'File', 'User'][random.nextInt(4)],
      'priority': random.nextInt(5) + 1,
      'tags': List.generate(random.nextInt(3), (i) => 'tag${i + 1}'),
      'version':
          '${random.nextInt(3) + 1}.${random.nextInt(10)}.${random.nextInt(10)}',
    };
  }

  void _applyFiltersAndSort() {
    List<PerformanceItem> filtered = List.from(_items);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((item) =>
              item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query))
          .toList();
    }

    // Apply sorting
    switch (_sortMode) {
      case SortMode.none:
        break;
      case SortMode.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.value:
        filtered.sort((a, b) => b.value.compareTo(a.value));
        break;
      case SortMode.date:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortMode.progress:
        filtered.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _metricsAnimationController.dispose();
    _scrollController.dispose();
    _metricsTimer?.cancel();

    // Frame callback cleanup - not needed in dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final theme = Theme.of(context);
      final ui = getAdaptiveFactory(context);

      return Scaffold(
        key: ValueKey('performance_scaffold_$uiSystem'),
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            // Performance metrics
            if (_showMetrics) _buildMetricsPanel(theme, ui),

            // Controls
            _buildControlsPanel(theme, ui),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingView(theme)
                  : _buildContentView(theme, ui),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingButtons(theme),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerFade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance Demo'),
              Text(
                '${_filteredItems.length} items',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_showMetrics ? Icons.analytics : Icons.analytics_outlined),
          onPressed: () {
            setState(() => _showMetrics = !_showMetrics);
            _metricsAnimationController.forward();
          },
          tooltip: 'Toggle Metrics',
        ),
        PopupMenuButton<ViewMode>(
          icon: const Icon(Icons.view_module),
          onSelected: (mode) => setState(() => _viewMode = mode),
          itemBuilder: (context) => ViewMode.values.map((mode) {
            return PopupMenuItem(
              value: mode,
              child: Row(
                children: [
                  Icon(mode.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(mode.label),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricsPanel(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ScaleTransition(
      scale: _metricsScale,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed,
                label: 'FPS',
                value: _averageFps.toStringAsFixed(1),
                color: _averageFps >= 55
                    ? Colors.green
                    : _averageFps >= 45
                        ? Colors.orange
                        : Colors.red,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.memory,
                label: 'Memory',
                value: '${_memoryUsage.toStringAsFixed(1)}MB',
                color: _memoryUsage < 50
                    ? Colors.green
                    : _memoryUsage < 100
                        ? Colors.orange
                        : Colors.red,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.widgets,
                label: 'Renders',
                value: _renderObjects.toString(),
                color: Colors.blue,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.dataset,
                label: 'Items',
                value: _items.length.toString(),
                color: _isLargeDataset ? Colors.purple : Colors.teal,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFiltersAndSort();
            },
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Control chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Dataset size controls
                _buildDatasetChip(
                  label: '1K Items',
                  isSelected: _currentDataSize == 1000,
                  onTap: () => _generateData(1000),
                ),
                const SizedBox(width: 8),
                _buildDatasetChip(
                  label: '5K Items',
                  isSelected: _currentDataSize == 5000,
                  onTap: () => _generateData(5000),
                ),
                const SizedBox(width: 8),
                _buildDatasetChip(
                  label: '10K Items',
                  isSelected: _currentDataSize == 10000,
                  onTap: () => _generateData(10000),
                ),
                const SizedBox(width: 16),

                // Sort controls
                PopupMenuButton<SortMode>(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort, size: 16),
                        const SizedBox(width: 4),
                        Text(_sortMode.label),
                      ],
                    ),
                  ),
                  onSelected: (mode) {
                    setState(() => _sortMode = mode);
                    _applyFiltersAndSort();
                  },
                  itemBuilder: (context) => SortMode.values.map((mode) {
                    return PopupMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            _sortMode == mode ? Icons.check : null,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(mode.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Generating ${_currentDataSize} items...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment for large datasets',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(ThemeData theme, AdaptiveWidgetFactory ui) {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or generate more data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    switch (_viewMode) {
      case ViewMode.list:
        return _buildListView(theme);
      case ViewMode.grid:
        return _buildGridView(theme);
      case ViewMode.table:
        return _buildTableView(theme);
    }
  }

  Widget _buildListView(ThemeData theme) {
    return FadeTransition(
      opacity: _listFade,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 100 + (index % 10) * 50),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, animation, child) {
              return Transform.translate(
                offset: Offset(50 * (1 - animation), 0),
                child: Opacity(
                  opacity: animation,
                  child: _buildListItem(item, index, theme),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListItem(PerformanceItem item, int index, ThemeData theme) {
    return Container(
      height: _itemHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: () => _showItemDetails(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category indicator
                Container(
                  width: 40,
                  height: 40,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isImportant)
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                        ],
                      ),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          // Progress bar
                          Expanded(
                            flex: 2,
                            child: LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation(item.category.color),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Value
                          Text(
                            '\$${item.value.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(ThemeData theme) {
    return FadeTransition(
      opacity: _listFade,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index % 6) * 100),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, animation, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * animation),
                child: Opacity(
                  opacity: animation,
                  child: _buildGridItem(item, theme),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGridItem(PerformanceItem item, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  const Spacer(),
                  if (item.isImportant)
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Progress
              LinearProgressIndicator(
                value: item.progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(item.category.color),
                minHeight: 6,
              ),

              const SizedBox(height: 8),

              // Value and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${item.value.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: item.category.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(ThemeData theme) {
    return FadeTransition(
      opacity: _listFade,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Value'), numeric: true),
            DataColumn(label: Text('Progress'), numeric: true),
            DataColumn(label: Text('Date')),
          ],
          rows: _filteredItems.take(100).map((item) {
            // Limit for performance
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      if (item.isImportant)
                        Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      Icon(item.category.icon,
                          color: item.category.color, size: 16),
                      const SizedBox(width: 4),
                      Text(item.category.label),
                    ],
                  ),
                ),
                DataCell(Text('\$${item.value.toStringAsFixed(0)}')),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(item.category.color),
                    ),
                  ),
                ),
                DataCell(Text(_formatTimestamp(item.timestamp))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "add",
          mini: true,
          onPressed: () => _generateData(1000, append: true),
          child: const Icon(Icons.add),
          tooltip: 'Add 1K Items',
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "refresh",
          onPressed: () => _generateData(_currentDataSize),
          child: const Icon(Icons.refresh),
          tooltip: 'Regenerate Data',
        ),
      ],
    );
  }

  void _showItemDetails(PerformanceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return _ItemDetailsSheet(
              item: item, scrollController: scrollController);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Supporting classes and enums

class PerformanceItem {
  final int id;
  final String title;
  final String subtitle;
  final double value;
  final double progress;
  final Category category;
  final bool isImportant;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.progress,
    required this.category,
    required this.isImportant,
    required this.timestamp,
    required this.metadata,
  });
}

enum Category {
  analytics,
  finance,
  operations,
  marketing,
  development,
  support;

  String get label {
    switch (this) {
      case Category.analytics:
        return 'Analytics';
      case Category.finance:
        return 'Finance';
      case Category.operations:
        return 'Operations';
      case Category.marketing:
        return 'Marketing';
      case Category.development:
        return 'Development';
      case Category.support:
        return 'Support';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.analytics:
        return Icons.analytics;
      case Category.finance:
        return Icons.attach_money;
      case Category.operations:
        return Icons.build;
      case Category.marketing:
        return Icons.campaign;
      case Category.development:
        return Icons.code;
      case Category.support:
        return Icons.support_agent;
    }
  }

  Color get color {
    switch (this) {
      case Category.analytics:
        return Colors.blue;
      case Category.finance:
        return Colors.green;
      case Category.operations:
        return Colors.orange;
      case Category.marketing:
        return Colors.purple;
      case Category.development:
        return Colors.red;
      case Category.support:
        return Colors.teal;
    }
  }
}

enum ViewMode {
  list,
  grid,
  table;

  String get label {
    switch (this) {
      case ViewMode.list:
        return 'List';
      case ViewMode.grid:
        return 'Grid';
      case ViewMode.table:
        return 'Table';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewMode.list:
        return Icons.list;
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.table:
        return Icons.table_chart;
    }
  }
}

enum SortMode {
  none,
  title,
  value,
  date,
  progress;

  String get label {
    switch (this) {
      case SortMode.none:
        return 'No Sort';
      case SortMode.title:
        return 'By Title';
      case SortMode.value:
        return 'By Value';
      case SortMode.date:
        return 'By Date';
      case SortMode.progress:
        return 'By Progress';
    }
  }
}

class _ItemDetailsSheet extends StatelessWidget {
  final PerformanceItem item;
  final ScrollController scrollController;

  const _ItemDetailsSheet({
    required this.item,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.category.icon,
                  color: item.category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.category.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isImportant)
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            item.subtitle,
            style: theme.textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          // Metrics
          Row(
            children: [
              Expanded(
                child: _buildDetailMetric(
                  'Value',
                  '\$${item.value.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailMetric(
                  'Progress',
                  '${(item.progress * 100).toInt()}%',
                  Icons.trending_up,
                  item.category.color,
                  theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress bar
          Text(
            'Progress',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: item.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(item.category.color),
            minHeight: 8,
          ),

          const SizedBox(height: 24),

          // Metadata
          Text(
            'Metadata',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          ...item.metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${entry.key}:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Timestamp
          Text(
            'Created',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            item.timestamp.toString(),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class FrameMetrics {
  final Duration timestamp;
  final double fps;

  FrameMetrics({required this.timestamp, required this.fps});
}
