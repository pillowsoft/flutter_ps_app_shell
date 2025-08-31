import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_widget_factory.dart';
import '../adaptive_style_provider.dart';

/// Adaptive date picker that follows platform conventions
class AdaptiveDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final DatePickerMode mode;
  final bool showClearButton;

  const AdaptiveDatePicker({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.mode = DatePickerMode.date,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoDatePicker(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiDatePicker(context, styleProvider);
      default:
        return _buildMaterialDatePicker(context, styleProvider);
    }
  }

  Widget _buildMaterialDatePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _showMaterialDatePicker(context) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    mode == DatePickerMode.dateTime
                        ? Icons.event_note
                        : Icons.event,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? _formatDate(selectedDate!, mode, context)
                          : (hint ?? 'Select date'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedDate != null
                            ? (enabled
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (showClearButton && selectedDate != null && enabled)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _clearSelection(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  if (suffix != null) ...[
                    const SizedBox(width: 12),
                    suffix!,
                  ],
                ],
              ),
            ),
          ),
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

  Widget _buildCupertinoDatePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: enabled ? () => _showCupertinoDatePicker(context) : null,
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
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 12),
                ],
                Icon(
                  mode == DatePickerMode.dateTime
                      ? CupertinoIcons.calendar_today
                      : CupertinoIcons.calendar,
                  color: enabled
                      ? CupertinoColors.label
                      : CupertinoColors.inactiveGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!, mode, context)
                        : (hint ?? 'Select date'),
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null
                          ? (enabled
                              ? CupertinoColors.label
                              : CupertinoColors.inactiveGray)
                          : CupertinoColors.placeholderText,
                    ),
                  ),
                ),
                if (showClearButton && selectedDate != null && enabled)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: const Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () => _clearSelection(),
                  ),
                if (suffix != null) ...[
                  const SizedBox(width: 12),
                  suffix!,
                ],
              ],
            ),
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

  Widget _buildForuiDatePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
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
                fontWeight: FontWeight.w600,
                color: errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _showMaterialDatePicker(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    mode == DatePickerMode.dateTime
                        ? Icons.schedule
                        : Icons.calendar_today,
                    size: 20,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? _formatDate(selectedDate!, mode, context)
                          : (hint ?? 'Select date'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedDate != null
                            ? (enabled
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showClearButton && selectedDate != null && enabled)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _clearSelection(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                    ),
                  if (suffix != null) ...[
                    const SizedBox(width: 12),
                    suffix!,
                  ],
                ],
              ),
            ),
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

  Future<void> _showMaterialDatePicker(BuildContext context) async {
    if (mode == DatePickerMode.dateTime) {
      // Show date picker first, then time picker
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
      );

      if (date != null && context.mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedDate != null
              ? TimeOfDay.fromDateTime(selectedDate!)
              : TimeOfDay.now(),
        );

        if (time != null) {
          final dateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          onDateSelected(dateTime);
        }
      }
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
      );

      if (date != null) {
        onDateSelected(date);
      }
    }
  }

  Future<void> _showCupertinoDatePicker(BuildContext context) async {
    DateTime tempDate = selectedDate ?? DateTime.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header with actions
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () {
                        onDateSelected(tempDate);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Date picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode == DatePickerMode.dateTime
                      ? CupertinoDatePickerMode.dateAndTime
                      : CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate ?? DateTime.now(),
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) => tempDate = date,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSelection() {
    // Clear by passing a very old date that can be handled by the parent
    onDateSelected(DateTime(1900));
  }

  String _formatDate(DateTime date, DatePickerMode mode, BuildContext context) {
    if (date.year == 1900) return ''; // Handle cleared state

    switch (mode) {
      case DatePickerMode.date:
        return '${date.day}/${date.month}/${date.year}';
      case DatePickerMode.dateTime:
        final time = TimeOfDay.fromDateTime(date);
        return '${date.day}/${date.month}/${date.year} ${time.format(context)}';
    }
  }
}

/// Adaptive time picker component
class AdaptiveTimePicker extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay) onTimeSelected;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final bool showClearButton;
  final bool use24HourFormat;

  const AdaptiveTimePicker({
    super.key,
    required this.onTimeSelected,
    this.selectedTime,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.showClearButton = true,
    this.use24HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoTimePicker(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiTimePicker(context, styleProvider);
      default:
        return _buildMaterialTimePicker(context, styleProvider);
    }
  }

  Widget _buildMaterialTimePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _showMaterialTimePicker(context) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.access_time,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime != null
                          ? _formatTime(selectedTime!, use24HourFormat)
                          : (hint ?? 'Select time'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedTime != null
                            ? (enabled
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (showClearButton && selectedTime != null && enabled)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _clearSelection(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  if (suffix != null) ...[
                    const SizedBox(width: 12),
                    suffix!,
                  ],
                ],
              ),
            ),
          ),
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

  Widget _buildCupertinoTimePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: enabled ? () => _showCupertinoTimePicker(context) : null,
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
                if (prefix != null) ...[
                  prefix!,
                  const SizedBox(width: 12),
                ],
                Icon(
                  CupertinoIcons.time,
                  color: enabled
                      ? CupertinoColors.label
                      : CupertinoColors.inactiveGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTime != null
                        ? _formatTime(selectedTime!, use24HourFormat)
                        : (hint ?? 'Select time'),
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedTime != null
                          ? (enabled
                              ? CupertinoColors.label
                              : CupertinoColors.inactiveGray)
                          : CupertinoColors.placeholderText,
                    ),
                  ),
                ),
                if (showClearButton && selectedTime != null && enabled)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 24,
                    child: const Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () => _clearSelection(),
                  ),
                if (suffix != null) ...[
                  const SizedBox(width: 12),
                  suffix!,
                ],
              ],
            ),
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

  Widget _buildForuiTimePicker(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
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
                fontWeight: FontWeight.w600,
                color: errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _showMaterialTimePicker(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime != null
                          ? _formatTime(selectedTime!, use24HourFormat)
                          : (hint ?? 'Select time'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedTime != null
                            ? (enabled
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showClearButton && selectedTime != null && enabled)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _clearSelection(),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                    ),
                  if (suffix != null) ...[
                    const SizedBox(width: 12),
                    suffix!,
                  ],
                ],
              ),
            ),
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

  Future<void> _showMaterialTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: use24HourFormat
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              );
            }
          : null,
    );

    if (time != null) {
      onTimeSelected(time);
    }
  }

  Future<void> _showCupertinoTimePicker(BuildContext context) async {
    TimeOfDay tempTime = selectedTime ?? TimeOfDay.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header with actions
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () {
                        onTimeSelected(tempTime);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Time picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now().copyWith(
                    hour: selectedTime?.hour ?? TimeOfDay.now().hour,
                    minute: selectedTime?.minute ?? TimeOfDay.now().minute,
                  ),
                  use24hFormat: use24HourFormat,
                  onDateTimeChanged: (dateTime) {
                    tempTime = TimeOfDay.fromDateTime(dateTime);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSelection() {
    // Clear by passing midnight time that can be handled by the parent
    onTimeSelected(const TimeOfDay(hour: 0, minute: 0));
  }

  String _formatTime(TimeOfDay time, bool use24Hour) {
    if (time.hour == 0 && time.minute == 0) return ''; // Handle cleared state

    if (use24Hour) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour =
          time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }
}

enum DatePickerMode {
  date,
  dateTime,
}

/// Date range picker for selecting start and end dates
class AdaptiveDateRangePicker extends StatefulWidget {
  final DateTimeRange? selectedRange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTimeRange) onRangeSelected;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final bool showClearButton;

  const AdaptiveDateRangePicker({
    super.key,
    required this.onRangeSelected,
    this.selectedRange,
    this.firstDate,
    this.lastDate,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
    this.prefix,
    this.suffix,
    this.showClearButton = true,
  });

  @override
  State<AdaptiveDateRangePicker> createState() =>
      _AdaptiveDateRangePickerState();
}

class _AdaptiveDateRangePickerState extends State<AdaptiveDateRangePicker> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color:
                    widget.errorText != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _showDateRangePicker : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.errorText != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefix != null) ...[
                    widget.prefix!,
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.date_range,
                    color: widget.enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.selectedRange != null
                          ? '${_formatDate(widget.selectedRange!.start)} - ${_formatDate(widget.selectedRange!.end)}'
                          : (widget.hint ?? 'Select date range'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.selectedRange != null
                            ? (widget.enabled
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (widget.showClearButton &&
                      widget.selectedRange != null &&
                      widget.enabled)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSelection,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  if (widget.suffix != null) ...[
                    const SizedBox(width: 12),
                    widget.suffix!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      initialDateRange: widget.selectedRange,
    );

    if (range != null) {
      widget.onRangeSelected(range);
    }
  }

  void _clearSelection() {
    // Clear by passing a special range that can be handled by the parent
    final clearRange = DateTimeRange(
      start: DateTime(1900),
      end: DateTime(1900),
    );
    widget.onRangeSelected(clearRange);
  }

  String _formatDate(DateTime date) {
    if (date.year == 1900) return ''; // Handle cleared state
    return '${date.day}/${date.month}/${date.year}';
  }
}
