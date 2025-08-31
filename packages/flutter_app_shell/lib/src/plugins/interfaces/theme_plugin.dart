import 'package:flutter/material.dart';
import '../../ui/adaptive/adaptive_widget_factory.dart';
import 'base_plugin.dart';

/// Interface for theme plugins that provide custom UI systems
abstract class ThemePlugin extends BasePlugin {
  @override
  PluginType get type => PluginType.theme;

  /// Unique identifier for this UI system
  String get uiSystemId;

  /// Display name for this UI system
  String get uiSystemName;

  /// Description of this UI system's design philosophy
  String get uiSystemDescription;

  /// Icon representing this UI system
  IconData? get uiSystemIcon => null;

  /// Primary color scheme for this UI system
  ColorScheme get lightColorScheme;
  ColorScheme get darkColorScheme;

  /// Create the adaptive factory for this UI system
  AdaptiveWidgetFactory createAdaptiveFactory(BuildContext context);

  /// Create theme data for this UI system
  ThemeData createLightTheme();
  ThemeData createDarkTheme();

  /// Register this theme with the UI system manager
  Future<void> registerTheme();

  /// Unregister this theme from the UI system manager
  Future<void> unregisterTheme();

  /// Optional: Custom material app configuration
  MaterialApp Function(MaterialApp app)? get materialAppTransform => null;

  /// Optional: Custom cupertino app configuration (if this theme supports iOS)
  Widget Function(Widget app)? get cupertinoAppTransform => null;

  /// Whether this theme supports platform-specific optimizations
  bool get supportsMaterial => true;
  bool get supportsCupertino => false;
  bool get supportsWeb => true;
  bool get supportsDesktop => true;
}

/// Theme metadata for discovery and organization
class ThemeMetadata {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData? icon;
  final List<String> supportedPlatforms;
  final bool isBuiltIn;

  const ThemeMetadata({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'Custom',
    this.icon,
    this.supportedPlatforms = const ['all'],
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'supportedPlatforms': supportedPlatforms,
        'isBuiltIn': isBuiltIn,
      };
}

/// Configuration options for theme plugins
class ThemeConfiguration {
  final Map<String, dynamic> _config;

  ThemeConfiguration([Map<String, dynamic>? config]) : _config = config ?? {};

  T? get<T>(String key) => _config[key] as T?;
  void set<T>(String key, T value) => _config[key] = value;
  Map<String, dynamic> toMap() => Map.from(_config);

  // Common theme configuration options
  Color? get primaryColor => get<Color>('primaryColor');
  set primaryColor(Color? value) => set('primaryColor', value);

  Color? get accentColor => get<Color>('accentColor');
  set accentColor(Color? value) => set('accentColor', value);

  String? get fontFamily => get<String>('fontFamily');
  set fontFamily(String? value) => set('fontFamily', value);

  double? get borderRadius => get<double>('borderRadius');
  set borderRadius(double? value) => set('borderRadius', value);

  double? get elevation => get<double>('elevation');
  set elevation(double? value) => set('elevation', value);
}

/// Base class for common theme plugin implementations
abstract class BaseThemePlugin extends ThemePlugin {
  PluginState _state = PluginState.unloaded;
  Exception? _lastError;
  ThemeConfiguration? _configuration;

  PluginState get state => _state;
  Exception? get lastError => _lastError;
  ThemeConfiguration get configuration =>
      _configuration ??= ThemeConfiguration();

  @override
  Future<void> initialize() async {
    try {
      _state = PluginState.initializing;
      await loadConfiguration();
      await registerTheme();
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
      await unregisterTheme();
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
        'uiSystemId': uiSystemId,
        'uiSystemName': uiSystemName,
        'supportsMaterial': supportsMaterial,
        'supportsCupertino': supportsCupertino,
        'supportsWeb': supportsWeb,
        'supportsDesktop': supportsDesktop,
      };

  /// Load theme configuration from persistent storage
  Future<void> loadConfiguration() async {
    // Override to implement configuration loading
  }

  /// Save theme configuration to persistent storage
  Future<void> saveConfiguration() async {
    // Override to implement configuration saving
  }

  /// Update theme configuration
  Future<void> updateConfiguration(ThemeConfiguration newConfig) async {
    _configuration = newConfig;
    await saveConfiguration();
    await onConfigurationChanged();
  }

  /// Called when configuration changes
  Future<void> onConfigurationChanged() async {
    // Override to handle configuration changes
  }

  /// Override to implement plugin-specific initialization
  Future<void> onInitialize() async {}

  /// Override to implement plugin-specific disposal
  Future<void> onDispose() async {}
}
