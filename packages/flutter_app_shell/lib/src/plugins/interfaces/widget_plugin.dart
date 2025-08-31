import 'package:flutter/widgets.dart';
import 'base_plugin.dart';

/// Interface for widget extension plugins that provide adaptive UI components
abstract class WidgetExtensionPlugin extends BasePlugin {
  @override
  PluginType get type => PluginType.widget;

  /// Map of widget identifiers to their adaptive builders
  /// Key: widget identifier (e.g., 'chart', 'calendar', 'data_table')
  /// Value: builder function that creates adaptive widget
  Map<String, AdaptiveWidgetBuilder> get widgets;

  /// UI systems this plugin supports
  /// Should include at least ['material', 'cupertino', 'forui']
  List<String> get supportedUISystems;

  /// Category for organizing widgets in UI
  String get category => 'General';

  /// Icon representing this widget plugin
  IconData? get icon => null;

  /// Register widget builders with the adaptive factory system
  Future<void> registerWidgets();

  /// Unregister widget builders from the adaptive factory system
  Future<void> unregisterWidgets();
}

/// Builder function for adaptive widgets
typedef AdaptiveWidgetBuilder = Widget Function(
  BuildContext context,
  String uiSystem,
  Map<String, dynamic> properties,
);

/// Properties for configuring adaptive widgets
class AdaptiveWidgetProperties {
  final Map<String, dynamic> _properties;

  AdaptiveWidgetProperties([Map<String, dynamic>? properties])
      : _properties = properties ?? {};

  T? get<T>(String key) => _properties[key] as T?;
  void set<T>(String key, T value) => _properties[key] = value;
  Map<String, dynamic> toMap() => Map.from(_properties);

  // Common properties
  String? get label => get<String>('label');
  set label(String? value) => set('label', value);

  VoidCallback? get onPressed => get<VoidCallback>('onPressed');
  set onPressed(VoidCallback? value) => set('onPressed', value);

  bool get enabled => get<bool>('enabled') ?? true;
  set enabled(bool value) => set('enabled', value);

  EdgeInsetsGeometry? get padding => get<EdgeInsetsGeometry>('padding');
  set padding(EdgeInsetsGeometry? value) => set('padding', value);

  EdgeInsetsGeometry? get margin => get<EdgeInsetsGeometry>('margin');
  set margin(EdgeInsetsGeometry? value) => set('margin', value);
}

/// Widget metadata for discovery and organization
class WidgetPluginMetadata {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData? icon;
  final List<String> supportedUISystems;
  final Map<String, PropertyDefinition> properties;

  const WidgetPluginMetadata({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'General',
    this.icon,
    required this.supportedUISystems,
    this.properties = const {},
  });
}

/// Definition of a widget property for UI generation
class PropertyDefinition {
  final String name;
  final String description;
  final PropertyType type;
  final dynamic defaultValue;
  final bool required;
  final List<dynamic>? allowedValues;
  final num? minValue;
  final num? maxValue;

  const PropertyDefinition({
    required this.name,
    required this.description,
    required this.type,
    this.defaultValue,
    this.required = false,
    this.allowedValues,
    this.minValue,
    this.maxValue,
  });
}

/// Types of properties that widgets can accept
enum PropertyType {
  string,
  number,
  boolean,
  color,
  icon,
  function,
  list,
  object,
}

/// Base class for common widget plugin implementations
abstract class BaseWidgetExtensionPlugin extends WidgetExtensionPlugin {
  PluginState _state = PluginState.unloaded;
  Exception? _lastError;

  PluginState get state => _state;
  Exception? get lastError => _lastError;

  @override
  Future<void> initialize() async {
    try {
      _state = PluginState.initializing;
      await registerWidgets();
      await onInitialize();
      _state = PluginState.ready;
      _lastError = null;
    } catch (e) {
      _lastError = e is Exception ? e : Exception(e.toString());
      _state = PluginState.error;
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _state = PluginState.disposing;
      await unregisterWidgets();
      await onDispose();
      _state = PluginState.disposed;
    } catch (e) {
      _lastError = e is Exception ? e : Exception(e.toString());
      _state = PluginState.error;
      rethrow;
    }
  }

  @override
  Future<bool> healthCheck() async {
    return _state == PluginState.ready && _lastError == null;
  }

  @override
  Map<String, dynamic> getStatus() => {
        'state': _state.name,
        'lastError': _lastError?.toString(),
        'widgetCount': widgets.length,
        'supportedUISystems': supportedUISystems,
        'category': category,
      };

  /// Override to implement plugin-specific initialization
  Future<void> onInitialize() async {}

  /// Override to implement plugin-specific disposal
  Future<void> onDispose() async {}
}
