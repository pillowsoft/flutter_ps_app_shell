import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

/// Comprehensive demo of all extended adaptive components
class AdaptiveComponentsDemoScreen extends StatefulWidget {
  const AdaptiveComponentsDemoScreen({super.key});

  @override
  State<AdaptiveComponentsDemoScreen> createState() =>
      _AdaptiveComponentsDemoScreenState();
}

class _AdaptiveComponentsDemoScreenState
    extends State<AdaptiveComponentsDemoScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Demo state for various components
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTimeRange? _selectedDateRange;
  RangeValues _rangeValues = const RangeValues(20, 80);
  List<String> _selectedFruits = [];
  List<String> _selectedColors = [];
  List<DemoFile> _selectedFiles = [];
  bool _isDragOver = false;

  // Data for demo components
  final List<String> _fruitOptions = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Honeydew',
    'Kiwi',
    'Lemon',
  ];

  final List<String> _colorOptions = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
    'Pink',
    'Brown',
    'Black',
    'White',
  ];

  final List<ChartData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _generateChartData();
  }

  void _generateChartData() {
    final random = Random();
    for (int i = 0; i < 12; i++) {
      _chartData.add(ChartData(
        category: 'Month ${i + 1}',
        value: 20 + random.nextDouble() * 80,
        color: Colors.primaries[i % Colors.primaries.length],
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return Scaffold(
        key: ValueKey('adaptive_components_scaffold_$uiSystem'),
        appBar: AppBar(
          title: const Text('Extended Adaptive Components'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.date_range), text: 'Date & Time'),
              Tab(icon: Icon(Icons.tune), text: 'Input Controls'),
              Tab(icon: Icon(Icons.attach_file), text: 'File Picker'),
              Tab(icon: Icon(Icons.view_module), text: 'Layout'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Data Viz'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDateTimeTab(theme, ui),
            _buildInputControlsTab(theme, ui),
            _buildFilePickerTab(theme, ui),
            _buildLayoutTab(theme, ui),
            _buildDataVizTab(theme, ui),
          ],
        ),
      );
    });
  }

  Widget _buildDateTimeTab(ThemeData theme, AdaptiveWidgetFactory ui) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time Pickers',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Date Picker
          _buildAdaptiveDatePicker(
            label: 'Select Date',
            hint: 'Choose a date',
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),

          const SizedBox(height: 24),

          // Time Picker
          _buildAdaptiveTimePicker(
            label: 'Select Time',
            hint: 'Choose a time',
            selectedTime: _selectedTime,
            onTimeSelected: (time) {
              setState(() => _selectedTime = time);
            },
          ),

          const SizedBox(height: 24),

          // Date Range Picker
          _buildAdaptiveDateRangePicker(
            label: 'Select Date Range',
            hint: 'Choose date range',
            selectedRange: _selectedDateRange,
            onRangeSelected: (range) {
              setState(() => _selectedDateRange = range);
            },
          ),

          const SizedBox(height: 24),

          // Results Display
          ui.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Values:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: ${_selectedDate?.toString() ?? 'None'}'),
                Text('Time: ${_selectedTime?.format(context) ?? 'None'}'),
                Text(
                    'Date Range: ${_selectedDateRange != null ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}' : 'None'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputControlsTab(ThemeData theme, AdaptiveWidgetFactory ui) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input Controls',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Range Slider
          _buildAdaptiveRangeSlider(
            label: 'Price Range',
            values: _rangeValues,
            min: 0,
            max: 100,
            onChanged: (values) {
              setState(() => _rangeValues = values);
            },
            valueFormatter: (value) => '\$${value.toInt()}',
          ),

          const SizedBox(height: 24),

          // Multi-Select Chips
          _buildAdaptiveMultiSelect<String>(
            label: 'Favorite Fruits (Chips Style)',
            options: _fruitOptions,
            selectedValues: _selectedFruits,
            onChanged: (values) {
              setState(() => _selectedFruits = values);
            },
            optionLabel: (fruit) => fruit,
            style: MultiSelectStyle.chips,
            maxSelections: 5,
          ),

          const SizedBox(height: 24),

          // Multi-Select List
          _buildAdaptiveMultiSelect<String>(
            label: 'Favorite Colors (List Style)',
            options: _colorOptions,
            selectedValues: _selectedColors,
            onChanged: (values) {
              setState(() => _selectedColors = values);
            },
            optionLabel: (color) => color,
            style: MultiSelectStyle.list,
            maxSelections: 3,
          ),

          const SizedBox(height: 24),

          // Results Display
          ui.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Values:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Price Range: \$${_rangeValues.start.toInt()} - \$${_rangeValues.end.toInt()}'),
                Text(
                    'Fruits: ${_selectedFruits.isEmpty ? 'None' : _selectedFruits.join(', ')}'),
                Text(
                    'Colors: ${_selectedColors.isEmpty ? 'None' : _selectedColors.join(', ')}')
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerTab(ThemeData theme, AdaptiveWidgetFactory ui) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Picker with Drag & Drop',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Drag & Drop Zone
          _buildDragDropZone(theme),

          const SizedBox(height: 24),

          // Traditional File Picker
          Row(
            children: [
              Expanded(
                child: ui.button(label: 'Choose Files', onPressed: _pickFiles),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ui.button(
                  label: 'Clear All',
                  onPressed: _selectedFiles.isNotEmpty ? _clearFiles : () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Selected Files Display
          if (_selectedFiles.isNotEmpty) ...[
            Text(
              'Selected Files (${_selectedFiles.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedFiles.map((file) => ui.card(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(file.name),
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_formatFileSize(file.size)} • ${file.type}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeFile(file),
                        tooltip: 'Remove file',
                      ),
                    ],
                  ),
                )),
          ] else ...[
            ui.card(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No files selected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drag and drop files or use the button above',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutTab(ThemeData theme, AdaptiveWidgetFactory ui) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout Components',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Responsive Grid Demo
          Text(
            'Responsive Grid',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildResponsiveGrid(theme),

          const SizedBox(height: 24),

          // Expandable Card Demo
          Text(
            'Expandable Components',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildExpandableCard(
              'Project Overview', _buildProjectContent(), theme),
          const SizedBox(height: 8),
          _buildExpandableCard('Team Members', _buildTeamContent(), theme),
          const SizedBox(height: 8),
          _buildExpandableCard(
              'Recent Activity', _buildActivityContent(), theme),

          const SizedBox(height: 24),

          // Bottom Sheet Demo
          ui.button(
            label: 'Show Adaptive Bottom Sheet',
            onPressed: () => _showAdaptiveBottomSheet(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDataVizTab(ThemeData theme, AdaptiveWidgetFactory ui) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Visualization',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart
          Text(
            'Sales by Month',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ui.card(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: _buildBarChart(theme),
            ),
          ),

          const SizedBox(height: 24),

          // Pie Chart
          Text(
            'Market Share',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ui.card(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: _buildPieChart(theme),
            ),
          ),

          const SizedBox(height: 24),

          // Progress Indicators
          Text(
            'Progress Indicators',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildProgressIndicators(theme),
        ],
      ),
    );
  }

  // Helper methods for building components

  Widget _buildAdaptiveDatePicker({
    required String label,
    required String hint,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    final theme = Theme.of(context);
    final ui = getAdaptiveFactory(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await ui.showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null ? _formatDate(selectedDate) : hint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveTimePicker({
    required String label,
    required String hint,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    final theme = Theme.of(context);
    final ui = getAdaptiveFactory(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final time = await ui.showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );
              if (time != null) {
                onTimeSelected(time);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime != null
                          ? selectedTime.format(context)
                          : hint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedTime != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveDateRangePicker({
    required String label,
    required String hint,
    required DateTimeRange? selectedRange,
    required Function(DateTimeRange) onRangeSelected,
  }) {
    final theme = Theme.of(context);
    final ui = getAdaptiveFactory(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final range = await ui.showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: selectedRange,
              );
              if (range != null) {
                onRangeSelected(range);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedRange != null
                          ? '${_formatDate(selectedRange.start)} - ${_formatDate(selectedRange.end)}'
                          : hint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedRange != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveRangeSlider({
    required String label,
    required RangeValues values,
    required double min,
    required double max,
    required Function(RangeValues) onChanged,
    String Function(double)? valueFormatter,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${valueFormatter?.call(values.start) ?? values.start.toStringAsFixed(1)} - ${valueFormatter?.call(values.end) ?? values.end.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: 20,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildAdaptiveMultiSelect<T>({
    required String label,
    required List<T> options,
    required List<T> selectedValues,
    required Function(List<T>) onChanged,
    required String Function(T) optionLabel,
    required MultiSelectStyle style,
    int? maxSelections,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (style == MultiSelectStyle.chips)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedValues.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedValues.map((value) {
                      return Chip(
                        label: Text(optionLabel(value)),
                        onDeleted: () {
                          final newValues =
                              selectedValues.where((v) => v != value).toList();
                          onChanged(newValues);
                        },
                        deleteIconColor: theme.colorScheme.onSecondaryContainer,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Available Options:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options
                      .where((option) => !selectedValues.contains(option))
                      .map((option) {
                    final canSelect = maxSelections == null ||
                        selectedValues.length < maxSelections;
                    return ActionChip(
                      label: Text(optionLabel(option)),
                      onPressed: canSelect
                          ? () {
                              if (!selectedValues.contains(option)) {
                                onChanged([...selectedValues, option]);
                              }
                            }
                          : null,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: canSelect
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedValues.contains(option);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    List<T> newValues = List.from(selectedValues);
                    if (selected == true) {
                      if (!newValues.contains(option) &&
                          (maxSelections == null ||
                              newValues.length < maxSelections)) {
                        newValues.add(option);
                      }
                    } else {
                      newValues.remove(option);
                    }
                    onChanged(newValues);
                  },
                  title: Text(optionLabel(option)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDragDropZone(ThemeData theme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _isDragOver
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragOver
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: _isDragOver ? 2 : 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDragOver ? Icons.file_download : Icons.cloud_upload_outlined,
              size: 32,
              color: _isDragOver
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              _isDragOver ? 'Drop files here' : 'Drag and drop files here',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _isDragOver
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supports: Images, Documents, Archives',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
            ? 3
            : screenWidth > 600
                ? 2
                : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.teal,
        ];

        return Container(
          decoration: BoxDecoration(
            color: colors[index].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors[index].withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.widgets,
                color: colors[index],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Item ${index + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors[index],
                ),
              ),
              Text(
                'Grid responsive',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableCard(String title, Widget content, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectContent() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flutter App Shell Framework',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A comprehensive Flutter application framework for rapid development with adaptive UI, service architecture, and state management.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '85% Complete',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamContent() {
    final theme = Theme.of(context);
    final members = [
      {'name': 'Alice Johnson', 'role': 'Lead Developer'},
      {'name': 'Bob Smith', 'role': 'UI/UX Designer'},
      {'name': 'Carol Davis', 'role': 'Backend Developer'},
    ];

    return Column(
      children: members.map((member) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              member['name']![0],
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(member['name']!),
          subtitle: Text(member['role']!),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildActivityContent() {
    final theme = Theme.of(context);
    final activities = [
      {'action': 'Updated documentation', 'time': '2 hours ago'},
      {'action': 'Fixed navigation bug', 'time': '1 day ago'},
      {'action': 'Added new components', 'time': '3 days ago'},
    ];

    return Column(
      children: activities.map((activity) {
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(activity['action']!),
          subtitle: Text(activity['time']!),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _chartData.take(8).map((data) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  data.value.toInt().toString(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Container(
                  height: data.value * 2,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.category.split(' ').last,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size.square(200),
                  painter: PieChartPainter(_chartData.take(5).toList()),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '100%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _chartData.take(5).map((data) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.category,
                        style: theme.textTheme.bodySmall,
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

  Widget _buildProgressIndicators(ThemeData theme) {
    return Column(
      children: [
        _buildProgressItem('Project Completion', 0.85, Colors.blue, theme),
        const SizedBox(height: 16),
        _buildProgressItem('Testing Coverage', 0.92, Colors.green, theme),
        const SizedBox(height: 16),
        _buildProgressItem('Documentation', 0.68, Colors.orange, theme),
        const SizedBox(height: 16),
        _buildProgressItem('Performance', 0.76, Colors.purple, theme),
      ],
    );
  }

  Widget _buildProgressItem(
      String label, double progress, Color color, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAdaptiveBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Adaptive Bottom Sheet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This is an adaptive bottom sheet that works across all platforms with native feel and behavior.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // Sample content
                    ...List.generate(20, (index) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text('Item ${index + 1}'),
                        subtitle: Text('Description for item ${index + 1}'),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // File picker methods

  Future<void> _pickFiles() async {
    // Simulate file picker
    final random = Random();
    final fileTypes = [
      'image/jpeg',
      'application/pdf',
      'text/plain',
      'application/zip'
    ];
    final fileNames = ['photo.jpg', 'document.pdf', 'notes.txt', 'archive.zip'];

    final selectedCount = random.nextInt(3) + 1;
    for (int i = 0; i < selectedCount; i++) {
      final index = random.nextInt(fileTypes.length);
      final file = DemoFile(
        name:
            '${fileNames[index].split('.').first}_${i + 1}.${fileNames[index].split('.').last}',
        type: fileTypes[index],
        size: random.nextInt(5000000) + 100000,
        data:
            Uint8List.fromList(List.generate(100, (i) => random.nextInt(256))),
      );

      if (!_selectedFiles.any((f) => f.name == file.name)) {
        setState(() => _selectedFiles.add(file));
      }
    }
  }

  void _clearFiles() {
    setState(() => _selectedFiles.clear());
  }

  void _removeFile(DemoFile file) {
    setState(() => _selectedFiles.remove(file));
  }

  // Helper methods

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'md':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Supporting classes

class DemoFile {
  final String name;
  final String type;
  final int size;
  final Uint8List data;

  DemoFile({
    required this.name,
    required this.type,
    required this.size,
    required this.data,
  });
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData({
    required this.category,
    required this.value,
    required this.color,
  });
}

enum MultiSelectStyle {
  chips,
  list,
  dropdown,
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final List<ChartData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    double total = data.fold(0, (sum, item) => sum + item.value);
    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * 3.14159;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
