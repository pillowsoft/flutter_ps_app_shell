import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_style_provider.dart';

/// Simple adaptive range slider
class AdaptiveRangeSlider extends StatelessWidget {
  final RangeValues values;
  final Function(RangeValues) onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String Function(double)? valueFormatter;
  final bool enabled;

  const AdaptiveRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.valueFormatter,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertino(context);
      case AdaptivePlatform.forui:
        return _buildForui(context);
      default:
        return _buildMaterial(context);
    }
  }

  Widget _buildMaterial(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: enabled ? onChanged : null,
          labels: RangeLabels(
            valueFormatter?.call(values.start) ?? values.start.toString(),
            valueFormatter?.call(values.end) ?? values.end.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildCupertino(BuildContext context) {
    // Simplified Cupertino implementation
    return _buildMaterial(context);
  }

  Widget _buildForui(BuildContext context) {
    // Simplified ForUI implementation
    return _buildMaterial(context);
  }
}

/// Simple multi-select enum
enum MultiSelectStyle {
  chips,
  list,
  dropdown,
}

/// Simple multi-select component
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
  final int? maxSelections;
  final MultiSelectStyle style;
  final Widget? prefix;
  final Widget? suffix;

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
    this.maxSelections,
    this.style = MultiSelectStyle.chips,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedValues.isNotEmpty) ...[
                Text('Selected:', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: selectedValues.map((value) {
                    return Chip(
                      label: Text(optionLabel(value)),
                      onDeleted: enabled ? () => _removeValue(value) : null,
                      deleteIconColor: theme.colorScheme.onSecondaryContainer,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
              ],
              Text('Available:', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
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
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  void _addValue(T value) {
    if (maxSelections == null || selectedValues.length < maxSelections!) {
      final newValues = List<T>.from(selectedValues)..add(value);
      onChanged(newValues);
    }
  }

  void _removeValue(T value) {
    final newValues = List<T>.from(selectedValues)..remove(value);
    onChanged(newValues);
  }
}
