import 'package:flutter/material.dart';
import '../interfaces/widget_plugin.dart';

/// Example Chart Widget Extension Plugin
/// Demonstrates how to create a widget plugin that provides adaptive chart components
class ChartWidgetPlugin extends BaseWidgetExtensionPlugin {
  @override
  String get id => 'com.example.charts';

  @override
  String get name => 'Chart Widgets';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Adaptive chart components for data visualization';

  @override
  String get author => 'Flutter App Shell Team';

  @override
  String get minAppShellVersion => '0.1.0';

  @override
  String get category => 'Data Visualization';

  @override
  IconData? get icon => Icons.bar_chart;

  @override
  List<String> get supportedUISystems => ['material', 'cupertino', 'forui'];

  @override
  Map<String, AdaptiveWidgetBuilder> get widgets => {
        'line_chart': _buildLineChart,
        'bar_chart': _buildBarChart,
        'pie_chart': _buildPieChart,
        'sparkline': _buildSparkline,
      };

  @override
  Future<void> registerWidgets() async {
    // In a real implementation, register with the adaptive factory system
    // For now, this is a placeholder
    print('[ChartWidgetPlugin] Registering chart widgets');
  }

  @override
  Future<void> unregisterWidgets() async {
    // In a real implementation, unregister from the adaptive factory system
    print('[ChartWidgetPlugin] Unregistering chart widgets');
  }

  /// Build a line chart widget
  Widget _buildLineChart(
    BuildContext context,
    String uiSystem,
    Map<String, dynamic> properties,
  ) {
    final data = properties['data'] as List<ChartDataPoint>? ?? [];
    final title = properties['title'] as String? ?? 'Line Chart';
    final showLegend = properties['showLegend'] as bool? ?? true;
    final animate = properties['animate'] as bool? ?? true;

    return _ChartContainer(
      title: title,
      uiSystem: uiSystem,
      child: _LineChartWidget(
        data: data,
        showLegend: showLegend,
        animate: animate,
        uiSystem: uiSystem,
      ),
    );
  }

  /// Build a bar chart widget
  Widget _buildBarChart(
    BuildContext context,
    String uiSystem,
    Map<String, dynamic> properties,
  ) {
    final data = properties['data'] as List<ChartDataPoint>? ?? [];
    final title = properties['title'] as String? ?? 'Bar Chart';
    final showLegend = properties['showLegend'] as bool? ?? true;
    final animate = properties['animate'] as bool? ?? true;

    return _ChartContainer(
      title: title,
      uiSystem: uiSystem,
      child: _BarChartWidget(
        data: data,
        showLegend: showLegend,
        animate: animate,
        uiSystem: uiSystem,
      ),
    );
  }

  /// Build a pie chart widget
  Widget _buildPieChart(
    BuildContext context,
    String uiSystem,
    Map<String, dynamic> properties,
  ) {
    final data = properties['data'] as List<ChartDataPoint>? ?? [];
    final title = properties['title'] as String? ?? 'Pie Chart';
    final showLegend = properties['showLegend'] as bool? ?? true;
    final animate = properties['animate'] as bool? ?? true;

    return _ChartContainer(
      title: title,
      uiSystem: uiSystem,
      child: _PieChartWidget(
        data: data,
        showLegend: showLegend,
        animate: animate,
        uiSystem: uiSystem,
      ),
    );
  }

  /// Build a sparkline widget
  Widget _buildSparkline(
    BuildContext context,
    String uiSystem,
    Map<String, dynamic> properties,
  ) {
    final data = properties['data'] as List<double>? ?? [];
    final color = properties['color'] as Color? ?? Colors.blue;
    final height = properties['height'] as double? ?? 50;

    return _SparklineWidget(
      data: data,
      color: color,
      height: height,
      uiSystem: uiSystem,
    );
  }
}

/// Chart data point model
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

/// Container for chart widgets with adaptive styling
class _ChartContainer extends StatelessWidget {
  final String title;
  final String uiSystem;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.uiSystem,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Adaptive styling based on UI system
    final decoration = _getDecoration(uiSystem, theme);
    final titleStyle = _getTitleStyle(uiSystem, theme);

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  BoxDecoration _getDecoration(String uiSystem, ThemeData theme) {
    switch (uiSystem) {
      case 'material':
        return BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case 'cupertino':
        return BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        );
      case 'forui':
        return BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        );
      default:
        return BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        );
    }
  }

  TextStyle _getTitleStyle(String uiSystem, ThemeData theme) {
    final baseStyle = theme.textTheme.titleMedium ?? const TextStyle();

    switch (uiSystem) {
      case 'material':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w500,
        );
      case 'cupertino':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        );
      case 'forui':
        return baseStyle.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        );
      default:
        return baseStyle;
    }
  }
}

/// Placeholder line chart widget
class _LineChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool showLegend;
  final bool animate;
  final String uiSystem;

  const _LineChartWidget({
    required this.data,
    required this.showLegend,
    required this.animate,
    required this.uiSystem,
  });

  @override
  Widget build(BuildContext context) {
    // In a real implementation, this would render an actual chart
    // For now, show a placeholder
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.blue.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Line Chart',
              style: TextStyle(
                color: Colors.blue.withOpacity(0.7),
              ),
            ),
            if (data.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${data.length} data points',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder bar chart widget
class _BarChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool showLegend;
  final bool animate;
  final String uiSystem;

  const _BarChartWidget({
    required this.data,
    required this.showLegend,
    required this.animate,
    required this.uiSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Bar Chart',
              style: TextStyle(
                color: Colors.green.withOpacity(0.7),
              ),
            ),
            if (data.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${data.length} bars',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder pie chart widget
class _PieChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool showLegend;
  final bool animate;
  final String uiSystem;

  const _PieChartWidget({
    required this.data,
    required this.showLegend,
    required this.animate,
    required this.uiSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Pie Chart',
              style: TextStyle(
                color: Colors.orange.withOpacity(0.7),
              ),
            ),
            if (data.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${data.length} segments',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder sparkline widget
class _SparklineWidget extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final String uiSystem;

  const _SparklineWidget({
    required this.data,
    required this.color,
    required this.height,
    required this.uiSystem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 20,
              color: color.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Sparkline (${data.length} points)',
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
