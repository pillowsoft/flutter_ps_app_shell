import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:get_it/get_it.dart';

class PluginDemoScreen extends StatefulWidget {
  const PluginDemoScreen({super.key});

  @override
  State<PluginDemoScreen> createState() => _PluginDemoScreenState();
}

class _PluginDemoScreenState extends State<PluginDemoScreen> {
  AnalyticsService? _analytics;

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  void _initializeAnalytics() {
    try {
      if (GetIt.instance.isRegistered<AnalyticsService>()) {
        _analytics = GetIt.instance<AnalyticsService>();
        _analytics?.trackScreenView('plugin_demo_screen');
      }
    } catch (e) {
      AppShellLogger.e('Failed to get analytics service: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final settingsStore = getIt<AppShellSettingsStore>();
    final uiSystem = settingsStore.uiSystem.value;

    if (uiSystem == 'cupertino') {
      // For Cupertino, show a dialog instead of snackbar
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Info'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      // For Material and ForUI, use ScaffoldMessenger if available
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Fallback to dialog if ScaffoldMessenger is not available
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Info'),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final styles = context.adaptiveStyle;

    return Watch((context) {
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return ui.scaffold(
        key: ValueKey('plugin_demo_scaffold_$uiSystem'),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.extension,
                    size: 32,
                    color: styles.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plugin Demo',
                          style: styles.headlineLarge,
                        ),
                        Text(
                          'Demonstrating plugin capabilities',
                          style: styles.bodyMedium.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Content
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: TabBar(
                          labelColor: styles.primary,
                          unselectedLabelColor: styles.onSurfaceVariant,
                          indicatorColor: styles.primary,
                          tabs: const [
                            Tab(text: 'Analytics Plugin'),
                            Tab(text: 'Chart Widgets'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildAnalyticsDemo(ui, styles),
                            _buildChartDemo(ui, styles),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnalyticsDemo(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    if (_analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: styles.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Analytics Plugin Not Available',
              style: styles.titleLarge.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The analytics service plugin is not loaded.',
              style: styles.bodyMedium.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Watch((context) {
      final eventsTracked = _analytics!.totalEventsTracked.value;
      final sessions = _analytics!.totalSessions.value;
      final isTracking = _analytics!.isTrackingEnabled.value;
      final queueSize = _analytics!.eventQueueSize.value;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Statistics
            ui.card(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Statistics',
                    style: styles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                      'Total Events Tracked', eventsTracked.toString(), styles),
                  _buildStatRow('Sessions', sessions.toString(), styles),
                  _buildStatRow('Tracking Status',
                      isTracking ? 'Enabled' : 'Disabled', styles),
                  _buildStatRow(
                      'Event Queue Size', queueSize.toString(), styles),
                  if (_analytics!.currentSessionId != null)
                    _buildStatRow(
                        'Session ID',
                        _analytics!.currentSessionId!.substring(0, 20) + '...',
                        styles),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Track Events Section
            ui.card(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Events',
                    style: styles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ui.button(
                        label: 'Track Button Click',
                        onPressed: () {
                          _analytics?.trackEvent('button_click', {
                            'button_id': 'demo_button',
                            'screen': 'plugin_demo',
                            'timestamp': DateTime.now().toIso8601String(),
                          });
                        },
                      ),
                      ui.button(
                        label: 'Track Form Submit',
                        onPressed: () {
                          _analytics?.trackEvent('form_submit', {
                            'form_id': 'demo_form',
                            'fields_filled': 5,
                            'validation_passed': true,
                          });
                        },
                      ),
                      ui.button(
                        label: 'Track Error',
                        onPressed: () {
                          _analytics?.trackEvent('error', {
                            'error_type': 'demo_error',
                            'message': 'This is a test error',
                            'severity': 'low',
                          });
                        },
                      ),
                      ui.button(
                        label: 'Track Purchase',
                        onPressed: () {
                          _analytics?.trackEvent('purchase', {
                            'product_id': 'demo_product',
                            'price': 9.99,
                            'currency': 'USD',
                            'quantity': 1,
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Control Section
            ui.card(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Control',
                    style: styles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Tracking Enabled: ', style: styles.bodyMedium),
                      const SizedBox(width: 8),
                      ui.switch_(
                        value: isTracking,
                        onChanged: (value) {
                          _analytics?.setTrackingEnabled(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ui.outlinedButton(
                        label: 'Flush Queue',
                        onPressed: () async {
                          await _analytics?.flushEventQueue();
                          _showMessage('Event queue flushed');
                        },
                      ),
                      ui.outlinedButton(
                        label: 'Clear All Data',
                        onPressed: () {
                          _analytics?.clearAllData();
                          _showMessage('Analytics data cleared');
                        },
                      ),
                      ui.outlinedButton(
                        label: 'Set User ID',
                        onPressed: () async {
                          await _analytics?.setUserId('demo_user_123');
                          _showMessage('User ID set');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChartDemo(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    // Get the settings store
    final settingsStore = getIt<AppShellSettingsStore>();

    // Get the chart plugin if available
    final isPluginManagerRegistered =
        GetIt.instance.isRegistered<PluginManager>();
    ChartWidgetPlugin? chartPlugin;

    if (isPluginManagerRegistered) {
      final pluginManager = GetIt.instance<PluginManager>();
      final widgetPlugins = pluginManager
          .getPluginsByType<WidgetExtensionPlugin>(PluginType.widget);
      chartPlugin = widgetPlugins.whereType<ChartWidgetPlugin>().firstOrNull;
    }

    if (chartPlugin == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: styles.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Chart Plugin Not Available',
              style: styles.titleLarge.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The chart widget plugin is not loaded.',
              style: styles.bodyMedium.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Demo data for charts
    final chartData = [
      ChartDataPoint(label: 'Jan', value: 30, color: Colors.blue),
      ChartDataPoint(label: 'Feb', value: 45, color: Colors.green),
      ChartDataPoint(label: 'Mar', value: 35, color: Colors.orange),
      ChartDataPoint(label: 'Apr', value: 50, color: Colors.purple),
      ChartDataPoint(label: 'May', value: 40, color: Colors.red),
    ];

    final sparklineData = [
      10.0,
      15.0,
      12.0,
      20.0,
      18.0,
      25.0,
      22.0,
      30.0,
      28.0,
      35.0
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plugin Info
          ui.card(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.widgets,
                      size: 24,
                      color: styles.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chartPlugin.name,
                            style: styles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'v${chartPlugin.version} by ${chartPlugin.author}',
                            style: styles.bodySmall.copyWith(
                              color: styles.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  chartPlugin.description,
                  style: styles.bodyMedium.copyWith(
                    color: styles.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Supported UI Systems: ${chartPlugin.supportedUISystems.join(', ')}',
                  style: styles.bodySmall.copyWith(
                    color: styles.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart Widgets Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              // Line Chart
              SizedBox(
                height: 250,
                child: chartPlugin.widgets['line_chart']!(
                  context,
                  settingsStore.uiSystem.value,
                  {
                    'title': 'Sales Trend',
                    'data': chartData,
                    'showLegend': true,
                    'animate': true,
                  },
                ),
              ),

              // Bar Chart
              SizedBox(
                height: 250,
                child: chartPlugin.widgets['bar_chart']!(
                  context,
                  settingsStore.uiSystem.value,
                  {
                    'title': 'Monthly Revenue',
                    'data': chartData,
                    'showLegend': true,
                    'animate': true,
                  },
                ),
              ),

              // Pie Chart
              SizedBox(
                height: 250,
                child: chartPlugin.widgets['pie_chart']!(
                  context,
                  settingsStore.uiSystem.value,
                  {
                    'title': 'Market Share',
                    'data': chartData,
                    'showLegend': true,
                    'animate': true,
                  },
                ),
              ),

              // Sparkline
              ui.card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Price',
                      style: styles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: chartPlugin.widgets['sparkline']!(
                        context,
                        settingsStore.uiSystem.value,
                        {
                          'data': sparklineData,
                          'color': styles.primary,
                          'height': 50.0,
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+12.5% this week',
                      style: styles.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, AdaptiveStyleProvider styles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: styles.bodyMedium.copyWith(
              color: styles.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: styles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
