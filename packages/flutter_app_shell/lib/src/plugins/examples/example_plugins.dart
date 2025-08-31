/// Example plugins for demonstrating the Flutter App Shell Plugin System
///
/// These plugins show how to implement different types of plugins:
/// - Service plugins for business logic
/// - Widget extension plugins for UI components
/// - Theme plugins for custom design systems
/// - Workflow plugins for automation

export 'analytics_plugin.dart';
export 'chart_widget_plugin.dart';

import '../interfaces/base_plugin.dart';
import 'analytics_plugin.dart';
import 'chart_widget_plugin.dart';

/// Get all example plugins for testing
List<BasePlugin> getExamplePlugins() {
  return [
    AnalyticsPlugin(),
    ChartWidgetPlugin(),
  ];
}
