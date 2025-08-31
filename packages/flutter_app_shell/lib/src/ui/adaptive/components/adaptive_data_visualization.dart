import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../adaptive_style_provider.dart';

/// Adaptive chart base class
abstract class AdaptiveChart extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool showLegend;
  final LegendPosition legendPosition;
  final Map<String, dynamic>? customStyle;

  const AdaptiveChart({
    super.key,
    this.title,
    this.subtitle,
    this.padding,
    this.width,
    this.height,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.customStyle,
  });

  Widget buildChart(BuildContext context, AdaptiveStyleProvider styleProvider);

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null)
            _buildHeader(context, styleProvider),
          Expanded(
            child: buildChart(context, styleProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: _getTitleStyle(theme, styleProvider),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: _getSubtitleStyle(theme, styleProvider),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _getTitleStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w700,
        );
      default:
        return theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w500,
        );
    }
  }

  TextStyle _getSubtitleStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 14,
          color: CupertinoColors.secondaryLabel,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        );
      default:
        return theme.textTheme.bodyMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

/// Pie chart implementation
class AdaptivePieChart extends AdaptiveChart {
  final List<PieChartData> data;
  final bool showValues;
  final bool showPercentages;
  final double strokeWidth;
  final double? innerRadius;
  final Color? backgroundColor;

  const AdaptivePieChart({
    super.key,
    required this.data,
    this.showValues = false,
    this.showPercentages = true,
    this.strokeWidth = 2.0,
    this.innerRadius,
    this.backgroundColor,
    super.title,
    super.subtitle,
    super.padding,
    super.width,
    super.height,
    super.showLegend,
    super.legendPosition,
    super.customStyle,
  });

  @override
  Widget buildChart(BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = (size - 32) / 2;

        return Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      data: data,
                      radius: radius,
                      strokeWidth: strokeWidth,
                      innerRadius: innerRadius,
                      backgroundColor: backgroundColor ?? Colors.transparent,
                      showValues: showValues,
                      showPercentages: showPercentages,
                      textStyle: _getDataLabelStyle(theme, styleProvider),
                    ),
                  ),
                ),
              ),
            ),
            if (showLegend) _buildLegend(context, theme, styleProvider),
          ],
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context, ThemeData theme,
      AdaptiveStyleProvider styleProvider) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: _getDataLabelStyle(theme, styleProvider),
                  ),
                ],
              ))
          .toList(),
    );
  }

  TextStyle _getDataLabelStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 12,
          color: CupertinoColors.label,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w500,
        );
      default:
        return theme.textTheme.bodySmall!;
    }
  }
}

/// Bar chart implementation
class AdaptiveBarChart extends AdaptiveChart {
  final List<BarChartData> data;
  final bool showValues;
  final bool showGrid;
  final Color? gridColor;
  final double barWidth;
  final double spacing;
  final Axis direction;
  final double? maxValue;
  final double? minValue;

  const AdaptiveBarChart({
    super.key,
    required this.data,
    this.showValues = true,
    this.showGrid = true,
    this.gridColor,
    this.barWidth = 32.0,
    this.spacing = 8.0,
    this.direction = Axis.vertical,
    this.maxValue,
    this.minValue,
    super.title,
    super.subtitle,
    super.padding,
    super.width,
    super.height,
    super.showLegend,
    super.legendPosition,
    super.customStyle,
  });

  @override
  Widget buildChart(BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: _BarChartPainter(
        data: data,
        showValues: showValues,
        showGrid: showGrid,
        gridColor:
            gridColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
        barWidth: barWidth,
        spacing: spacing,
        direction: direction,
        maxValue: maxValue,
        minValue: minValue,
        textStyle: _getDataLabelStyle(theme, styleProvider),
        labelStyle: _getLabelStyle(theme, styleProvider),
      ),
      child: Container(),
    );
  }

  TextStyle _getDataLabelStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 11,
          color: CupertinoColors.label,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
      default:
        return theme.textTheme.bodySmall!.copyWith(
          fontSize: 11,
        );
    }
  }

  TextStyle _getLabelStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 12,
          color: CupertinoColors.secondaryLabel,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w500,
        );
      default:
        return theme.textTheme.bodySmall!;
    }
  }
}

/// Line chart implementation
class AdaptiveLineChart extends AdaptiveChart {
  final List<LineChartData> data;
  final bool showPoints;
  final bool showGrid;
  final Color? gridColor;
  final double strokeWidth;
  final double pointRadius;
  final double? maxValue;
  final double? minValue;
  final bool smooth;

  const AdaptiveLineChart({
    super.key,
    required this.data,
    this.showPoints = true,
    this.showGrid = true,
    this.gridColor,
    this.strokeWidth = 2.0,
    this.pointRadius = 4.0,
    this.maxValue,
    this.minValue,
    this.smooth = false,
    super.title,
    super.subtitle,
    super.padding,
    super.width,
    super.height,
    super.showLegend,
    super.legendPosition,
    super.customStyle,
  });

  @override
  Widget buildChart(BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        showPoints: showPoints,
        showGrid: showGrid,
        gridColor:
            gridColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
        strokeWidth: strokeWidth,
        pointRadius: pointRadius,
        maxValue: maxValue,
        minValue: minValue,
        smooth: smooth,
        textStyle: _getDataLabelStyle(theme, styleProvider),
      ),
      child: Container(),
    );
  }

  TextStyle _getDataLabelStyle(
      ThemeData theme, AdaptiveStyleProvider styleProvider) {
    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return const TextStyle(
          fontSize: 11,
          color: CupertinoColors.secondaryLabel,
        );
      case AdaptivePlatform.forui:
        return theme.textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        );
      default:
        return theme.textTheme.bodySmall!.copyWith(
          fontSize: 11,
        );
    }
  }
}

/// Progress indicators with adaptive styling
class AdaptiveProgressIndicator extends StatelessWidget {
  final double value;
  final double? minValue;
  final double? maxValue;
  final String? label;
  final String? valueLabel;
  final Color? backgroundColor;
  final Color? valueColor;
  final double strokeWidth;
  final ProgressIndicatorType type;
  final bool showPercentage;
  final bool animated;
  final Duration animationDuration;

  const AdaptiveProgressIndicator({
    super.key,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.label,
    this.valueLabel,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 4.0,
    this.type = ProgressIndicatorType.linear,
    this.showPercentage = true,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = AdaptiveStyleProvider.of(context);

    switch (styleProvider.platform) {
      case AdaptivePlatform.cupertino:
        return _buildCupertinoProgress(context, styleProvider);
      case AdaptivePlatform.forui:
        return _buildForuiProgress(context, styleProvider);
      default:
        return _buildMaterialProgress(context, styleProvider);
    }
  }

  Widget _buildMaterialProgress(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);
    final normalizedValue = _normalizeValue();

    Widget progressWidget;
    if (type == ProgressIndicatorType.circular) {
      progressWidget = SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: animated ? null : normalizedValue,
          backgroundColor:
              backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
          valueColor:
              AlwaysStoppedAnimation(valueColor ?? theme.colorScheme.primary),
          strokeWidth: strokeWidth,
        ),
      );
    } else {
      progressWidget = LinearProgressIndicator(
        value: normalizedValue,
        backgroundColor:
            backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        valueColor:
            AlwaysStoppedAnimation(valueColor ?? theme.colorScheme.primary),
        minHeight: strokeWidth,
      );
    }

    return _wrapWithLabels(context, theme, progressWidget);
  }

  Widget _buildCupertinoProgress(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final normalizedValue = _normalizeValue();

    Widget progressWidget;
    if (type == ProgressIndicatorType.circular) {
      progressWidget = SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator.adaptive(
          value: normalizedValue,
          backgroundColor: backgroundColor ?? CupertinoColors.systemGrey5,
          valueColor:
              AlwaysStoppedAnimation(valueColor ?? CupertinoColors.activeBlue),
          strokeWidth: strokeWidth,
        ),
      );
    } else {
      progressWidget = Container(
        height: strokeWidth,
        decoration: BoxDecoration(
          color: backgroundColor ?? CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(strokeWidth / 2),
        ),
        child: FractionallySizedBox(
          widthFactor: normalizedValue,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: valueColor ?? CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(strokeWidth / 2),
            ),
          ),
        ),
      );
    }

    return _wrapWithLabels(context, Theme.of(context), progressWidget);
  }

  Widget _buildForuiProgress(
      BuildContext context, AdaptiveStyleProvider styleProvider) {
    final theme = Theme.of(context);
    final normalizedValue = _normalizeValue();

    Widget progressWidget;
    if (type == ProgressIndicatorType.circular) {
      progressWidget = SizedBox(
        width: 44,
        height: 44,
        child: CustomPaint(
          painter: _CircularProgressPainter(
            value: normalizedValue,
            backgroundColor:
                backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
            valueColor: valueColor ?? theme.colorScheme.primary,
            strokeWidth: strokeWidth,
          ),
        ),
      );
    } else {
      progressWidget = Container(
        height: strokeWidth + 2,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular((strokeWidth + 2) / 2),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: FractionallySizedBox(
          widthFactor: normalizedValue,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: valueColor ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular((strokeWidth + 2) / 2),
            ),
          ),
        ),
      );
    }

    return _wrapWithLabels(context, theme, progressWidget);
  }

  Widget _wrapWithLabels(
      BuildContext context, ThemeData theme, Widget progressWidget) {
    if (label == null && valueLabel == null && !showPercentage) {
      return progressWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage || valueLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (showPercentage || valueLabel != null)
                  Text(
                    valueLabel ?? '${(_normalizeValue() * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        progressWidget,
      ],
    );
  }

  double _normalizeValue() {
    final min = minValue ?? 0.0;
    final max = maxValue ?? 1.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}

/// Custom painters for charts
class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double radius;
  final double strokeWidth;
  final double? innerRadius;
  final Color backgroundColor;
  final bool showValues;
  final bool showPercentages;
  final TextStyle textStyle;

  _PieChartPainter({
    required this.data,
    required this.radius,
    required this.strokeWidth,
    this.innerRadius,
    required this.backgroundColor,
    required this.showValues,
    required this.showPercentages,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = data.fold(0.0, (sum, item) => sum + item.value);

    double currentAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      // Draw the slice
      final path = Path();
      if (innerRadius != null && innerRadius! > 0) {
        // Donut chart
        path.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          currentAngle,
          sweepAngle,
          true,
        );
        path.arcTo(
          Rect.fromCircle(center: center, radius: innerRadius!),
          currentAngle + sweepAngle,
          -sweepAngle,
          false,
        );
        path.close();
      } else {
        // Pie chart
        path.moveTo(center.dx, center.dy);
        path.arcTo(
          Rect.fromCircle(center: center, radius: radius),
          currentAngle,
          sweepAngle,
          false,
        );
        path.close();
      }

      canvas.drawPath(path, paint);

      // Draw stroke
      if (strokeWidth > 0) {
        final strokePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawPath(path, strokePaint);
      }

      // Draw labels
      if (showValues || showPercentages) {
        final labelAngle = currentAngle + sweepAngle / 2;
        final labelRadius =
            (innerRadius ?? 0) + (radius - (innerRadius ?? 0)) / 2;
        final labelPosition = Offset(
          center.dx + math.cos(labelAngle) * labelRadius,
          center.dy + math.sin(labelAngle) * labelRadius,
        );

        String labelText = '';
        if (showPercentages) {
          final percentage = (item.value / total * 100).toStringAsFixed(1);
          labelText = '$percentage%';
        } else if (showValues) {
          labelText = item.value.toString();
        }

        final textPainter = TextPainter(
          text: TextSpan(text: labelText, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final textOffset = Offset(
          labelPosition.dx - textPainter.width / 2,
          labelPosition.dy - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartData> data;
  final bool showValues;
  final bool showGrid;
  final Color gridColor;
  final double barWidth;
  final double spacing;
  final Axis direction;
  final double? maxValue;
  final double? minValue;
  final TextStyle textStyle;
  final TextStyle labelStyle;

  _BarChartPainter({
    required this.data,
    required this.showValues,
    required this.showGrid,
    required this.gridColor,
    required this.barWidth,
    required this.spacing,
    required this.direction,
    this.maxValue,
    this.minValue,
    required this.textStyle,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = maxValue ?? data.map((e) => e.value).reduce(math.max);
    final minVal =
        minValue ?? math.min(0, data.map((e) => e.value).reduce(math.min));
    final range = maxVal - minVal;

    if (range == 0) return;

    final chartArea = Rect.fromLTWH(40, 20, size.width - 60, size.height - 60);

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;

      const gridLines = 5;
      for (int i = 0; i <= gridLines; i++) {
        final y = chartArea.top + (chartArea.height * i / gridLines);
        canvas.drawLine(
          Offset(chartArea.left, y),
          Offset(chartArea.right, y),
          gridPaint,
        );
      }
    }

    // Draw bars
    final totalWidth = chartArea.width;
    final availableWidth = totalWidth - (spacing * (data.length - 1));
    final actualBarWidth = math.min(barWidth, availableWidth / data.length);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight = ((item.value - minVal) / range) * chartArea.height;

      final barX = chartArea.left + i * (actualBarWidth + spacing);
      final barY = chartArea.bottom - barHeight;

      final barRect = Rect.fromLTWH(barX, barY, actualBarWidth, barHeight);
      final paint = Paint()..color = item.color;

      canvas.drawRect(barRect, paint);

      // Draw value label
      if (showValues) {
        final textPainter = TextPainter(
          text: TextSpan(text: item.value.toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final textX = barX + (actualBarWidth - textPainter.width) / 2;
        final textY = barY - textPainter.height - 4;

        textPainter.paint(canvas, Offset(textX, textY));
      }

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(text: item.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      final labelX = barX + (actualBarWidth - labelPainter.width) / 2;
      final labelY = chartArea.bottom + 8;

      labelPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartData> data;
  final bool showPoints;
  final bool showGrid;
  final Color gridColor;
  final double strokeWidth;
  final double pointRadius;
  final double? maxValue;
  final double? minValue;
  final bool smooth;
  final TextStyle textStyle;

  _LineChartPainter({
    required this.data,
    required this.showPoints,
    required this.showGrid,
    required this.gridColor,
    required this.strokeWidth,
    required this.pointRadius,
    this.maxValue,
    this.minValue,
    required this.smooth,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final allPoints = data.expand((series) => series.points).toList();
    if (allPoints.isEmpty) return;

    final maxX = allPoints.map((p) => p.x).reduce(math.max);
    final minX = allPoints.map((p) => p.x).reduce(math.min);
    final maxY = maxValue ?? allPoints.map((p) => p.y).reduce(math.max);
    final minY = minValue ?? allPoints.map((p) => p.y).reduce(math.min);

    final chartArea = Rect.fromLTWH(40, 20, size.width - 60, size.height - 60);

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;

      const gridLines = 5;
      for (int i = 0; i <= gridLines; i++) {
        final y = chartArea.top + (chartArea.height * i / gridLines);
        canvas.drawLine(
          Offset(chartArea.left, y),
          Offset(chartArea.right, y),
          gridPaint,
        );
      }
    }

    // Draw lines and points
    for (final series in data) {
      final linePaint = Paint()
        ..color = series.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool isFirst = true;

      for (final point in series.points) {
        final x = chartArea.left +
            ((point.x - minX) / (maxX - minX)) * chartArea.width;
        final y = chartArea.bottom -
            ((point.y - minY) / (maxY - minY)) * chartArea.height;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, linePaint);

      // Draw points
      if (showPoints) {
        final pointPaint = Paint()
          ..color = series.color
          ..style = PaintingStyle.fill;

        for (final point in series.points) {
          final x = chartArea.left +
              ((point.x - minX) / (maxX - minX)) * chartArea.width;
          final y = chartArea.bottom -
              ((point.y - minY) / (maxY - minY)) * chartArea.height;

          canvas.drawCircle(Offset(x, y), pointRadius, pointPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final Color backgroundColor;
  final Color valueColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = value * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Data models for charts
class PieChartData {
  final String label;
  final double value;
  final Color color;

  const PieChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class BarChartData {
  final String label;
  final double value;
  final Color color;

  const BarChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class LineChartData {
  final String label;
  final List<ChartPoint> points;
  final Color color;

  const LineChartData({
    required this.label,
    required this.points,
    required this.color,
  });
}

class ChartPoint {
  final double x;
  final double y;
  final String? label;

  const ChartPoint({
    required this.x,
    required this.y,
    this.label,
  });
}

enum LegendPosition {
  top,
  bottom,
  left,
  right,
}

enum ProgressIndicatorType {
  linear,
  circular,
}
