import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_widget_factory.dart';
import '../adaptive_style_provider.dart';

/// Adaptive range slider component
class AdaptiveRangeSlider extends StatelessWidget {
  final RangeValues values;
  final Function(RangeValues) onChanged;
  final double min;
  final double max;
  final int? divisions;
  final RangeLabels? labels;
  final String? label;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final String Function(double)? valueFormatter;

  const AdaptiveRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labels,
    this.label,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoRangeSlider(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiRangeSlider(context, styleProvider);
      default:
        return _buildMaterialRangeSlider(context, styleProvider);
    }
  }

  Widget _buildMaterialRangeSlider(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: errorText != null ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),

        // Value display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueFormatter?.call(values.start) ??
                    values.start.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${valueFormatter?.call(min) ?? min.toStringAsFixed(1)} - ${valueFormatter?.call(max) ?? max.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                valueFormatter?.call(values.end) ??
                    values.end.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Slider
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          labels: labels,
          onChanged: enabled ? onChanged : null,
          activeColor: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCupertinoRangeSlider(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    // Cupertino doesn't have a native RangeSlider, so we'll create a custom one
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),

        // Value display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valueFormatter?.call(values.start) ??
                    values.start.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              Text(
                '${valueFormatter?.call(min) ?? min.toStringAsFixed(1)} - ${valueFormatter?.call(max) ?? max.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              Text(
                valueFormatter?.call(values.end) ??
                    values.end.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
        ),

        // Custom range slider using two CupertinoSliders
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Track
              Positioned(
                top: 28,
                left: 16,
                right: 16,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Active track
              Positioned(
                top: 28,
                left: 16 +
                    (values.start - min) /
                        (max - min) *
                        (MediaQuery.of(context).size.width - 64),
                right: MediaQuery.of(context).size.width -
                    32 -
                    (values.end - min) /
                        (max - min) *
                        (MediaQuery.of(context).size.width - 64),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Start thumb
              Positioned(
                top: 20,
                left: (values.start - min) /
                    (max - min) *
                    (MediaQuery.of(context).size.width - 32),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!enabled) return;
                    final width = MediaQuery.of(context).size.width - 64;
                    final newStart =
                        (details.localPosition.dx / width * (max - min) + min)
                            .clamp(min, values.end);
                    onChanged(RangeValues(newStart, values.end));
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey3,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // End thumb
              Positioned(
                top: 20,
                left: (values.end - min) /
                    (max - min) *
                    (MediaQuery.of(context).size.width - 32),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!enabled) return;
                    final width = MediaQuery.of(context).size.width - 64;
                    final newEnd =
                        (details.localPosition.dx / width * (max - min) + min)
                            .clamp(values.start, max);
                    onChanged(RangeValues(values.start, newEnd));
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey3,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForuiRangeSlider(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: errorText != null ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Value display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    valueFormatter?.call(values.start) ??
                        values.start.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${valueFormatter?.call(min) ?? min.toStringAsFixed(1)} - ${valueFormatter?.call(max) ?? max.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    valueFormatter?.call(values.end) ??
                        values.end.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Slider
              RangeSlider(
                values: values,
                min: min,
                max: max,
                divisions: divisions,
                labels: labels,
                onChanged: enabled ? onChanged : null,
                activeColor: errorText != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Adaptive multi-select component with chips
class AdaptiveMultiSelect<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selectedValues;
  final Function(List<T>) onChanged;
  final String Function(T) optionLabel;
  final Widget Function(T)? optionBuilder;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxSelections;
  final bool allowSearch;
  final MultiSelectStyle style;

  const AdaptiveMultiSelect({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    required this.optionLabel,
    this.optionBuilder,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.maxSelections,
    this.allowSearch = false,
    this.style = MultiSelectStyle.chips,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoMultiSelect(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiMultiSelect(context, styleProvider);
      default:
        return _buildMaterialMultiSelect(context, styleProvider);
    }
  }

  Widget _buildMaterialMultiSelect(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: errorText != null ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),
        _getMultiSelectWidget(context, theme, style),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCupertinoMultiSelect(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),
        _getCupertinoMultiSelectWidget(context, style),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForuiMultiSelect(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: errorText != null ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  suffix!,
                ],
              ],
            ),
          ),
        _getForuiMultiSelectWidget(context, theme, style),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChipsStyle(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.5),
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
                  onDeleted: enabled ? () => _removeValue(value) : null,
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

          // Available options
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
                  selectedValues.length < maxSelections!;
              return ActionChip(
                label: Text(optionLabel(option)),
                onPressed:
                    enabled && canSelect ? () => _addValue(option) : null,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: enabled && canSelect
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListStyle(BuildContext context, ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValues.contains(option);

          return CheckboxListTile(
            value: isSelected,
            onChanged: enabled
                ? (selected) {
                    if (selected == true) {
                      _addValue(option);
                    } else {
                      _removeValue(option);
                    }
                  }
                : null,
            title: optionBuilder?.call(option) ?? Text(optionLabel(option)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        },
      ),
    );
  }

  Widget _buildDropdownStyle(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _showDropdownDialog(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedValues.isEmpty
                    ? Text(
                        hint ?? 'Select options',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedValues.take(3).map((value) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              optionLabel(value),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList()
                          ..addAll(selectedValues.length > 3
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '+${selectedValues.length - 3}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ]
                              : []),
                      ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_down,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoChipsStyle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: errorText != null
            ? Border.all(color: CupertinoColors.systemRed)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedValues.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedValues.map((value) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        optionLabel(value),
                        style: const TextStyle(color: CupertinoColors.white),
                      ),
                      if (enabled) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeValue(value),
                          child: const Icon(
                            CupertinoIcons.clear,
                            size: 16,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Available Options:',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
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
                  selectedValues.length < maxSelections!;
              return CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(16),
                minSize: 0,
                onPressed:
                    enabled && canSelect ? () => _addValue(option) : null,
                child: Text(
                  optionLabel(option),
                  style: TextStyle(
                    color: enabled && canSelect
                        ? CupertinoColors.label
                        : CupertinoColors.inactiveGray,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoListStyle(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: errorText != null
            ? Border.all(color: CupertinoColors.systemRed)
            : null,
      ),
      child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValues.contains(option);

          return CupertinoListTile(
            leading: Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.secondaryLabel,
            ),
            title: optionBuilder?.call(option) ?? Text(optionLabel(option)),
            onTap: enabled
                ? () {
                    if (isSelected) {
                      _removeValue(option);
                    } else {
                      _addValue(option);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildCupertinoDropdownStyle(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? () => _showCupertinoDropdownDialog(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: errorText != null
              ? Border.all(color: CupertinoColors.systemRed)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedValues.isEmpty
                  ? Text(
                      hint ?? 'Select options',
                      style: const TextStyle(
                          color: CupertinoColors.placeholderText),
                    )
                  : Text(
                      selectedValues.length == 1
                          ? optionLabel(selectedValues.first)
                          : '${selectedValues.length} selected',
                      style: const TextStyle(color: CupertinoColors.label),
                    ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 20,
              color: CupertinoColors.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForuiChipsStyle(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedValues.isNotEmpty) ...[
            Text(
              'Selected:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedValues.map((value) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        optionLabel(value),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (enabled) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeValue(value),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Available:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
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
                  selectedValues.length < maxSelections!;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled && canSelect ? () => _addValue(option) : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      optionLabel(option),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled && canSelect
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildForuiListStyle(BuildContext context, ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValues.contains(option);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled
                  ? () {
                      if (isSelected) {
                        _removeValue(option);
                      } else {
                        _addValue(option);
                      }
                    }
                  : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: optionBuilder?.call(option) ??
                          Text(
                            optionLabel(option),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForuiDropdownStyle(BuildContext context, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _showForuiDropdownDialog(context, theme) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedValues.isEmpty
                    ? Text(
                        hint ?? 'Select options',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        selectedValues.length == 1
                            ? optionLabel(selectedValues.first)
                            : '${selectedValues.length} options selected',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addValue(T value) {
    if (maxSelections != null && selectedValues.length >= maxSelections!)
      return;
    if (!selectedValues.contains(value)) {
      onChanged([...selectedValues, value]);
    }
  }

  void _removeValue(T value) {
    onChanged(selectedValues.where((v) => v != value).toList());
  }

  Future<void> _showDropdownDialog(BuildContext context) async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (context) => _MultiSelectDialog<T>(
        options: options,
        selectedValues: selectedValues,
        optionLabel: optionLabel,
        optionBuilder: optionBuilder,
        maxSelections: maxSelections,
        allowSearch: allowSearch,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }

  Future<void> _showCupertinoDropdownDialog(BuildContext context) async {
    // Implementation for Cupertino dialog
    _showDropdownDialog(context);
  }

  Future<void> _showForuiDropdownDialog(
      BuildContext context, ThemeData theme) async {
    // Implementation for ForUI dialog
    _showDropdownDialog(context);
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  final List<T> options;
  final List<T> selectedValues;
  final String Function(T) optionLabel;
  final Widget Function(T)? optionBuilder;
  final int? maxSelections;
  final bool allowSearch;

  const _MultiSelectDialog({
    required this.options,
    required this.selectedValues,
    required this.optionLabel,
    this.optionBuilder,
    this.maxSelections,
    required this.allowSearch,
  });

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selectedValues;
  List<T> _filteredOptions = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOptions = widget.options.where((option) {
        return widget.optionLabel(option).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Options'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowSearch) ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search options...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  final isSelected = _selectedValues.contains(option);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          if (widget.maxSelections == null ||
                              _selectedValues.length < widget.maxSelections!) {
                            _selectedValues.add(option);
                          }
                        } else {
                          _selectedValues.remove(option);
                        }
                      });
                    },
                    title: widget.optionBuilder?.call(option) ??
                        Text(widget.optionLabel(option)),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedValues),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

enum MultiSelectStyle {
  chips,
  list,
  dropdown,
}

/// Adaptive checkbox group component
class AdaptiveCheckboxGroup<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selectedValues;
  final Function(List<T>) onChanged;
  final String Function(T) optionLabel;
  final Widget Function(T)? optionBuilder;
  final String? label;
  final bool enabled;
  final String? errorText;
  final Axis direction;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const AdaptiveCheckboxGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    required this.optionLabel,
    this.optionBuilder,
    this.label,
    this.enabled = true,
    this.errorText,
    this.direction = Axis.vertical,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        if (direction == Axis.vertical)
          Column(
            crossAxisAlignment: crossAxisAlignment,
            children: _buildCheckboxes(context),
          )
        else
          Wrap(
            children: _buildCheckboxes(context),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCheckboxes(BuildContext context) {
    return options.map((option) {
      final isSelected = selectedValues.contains(option);

      return CheckboxListTile(
        value: isSelected,
        onChanged: enabled
            ? (selected) {
                List<T> newValues = List.from(selectedValues);
                if (selected == true) {
                  if (!newValues.contains(option)) {
                    newValues.add(option);
                  }
                } else {
                  newValues.remove(option);
                }
                onChanged(newValues);
              }
            : null,
        title: optionBuilder?.call(option) ?? Text(optionLabel(option)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: direction == Axis.vertical
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
      );
    }).toList();
  }
}
