/// Base interface for all Flutter App Shell plugins
abstract class BasePlugin {
  /// Unique identifier for this plugin
  String get id;

  /// Human-readable name for this plugin
  String get name;

  /// Plugin version
  String get version;

  /// Plugin description
  String get description;

  /// Plugin author/organization
  String get author;

  /// Minimum App Shell version required
  String get minAppShellVersion;

  /// Plugin type
  PluginType get type;

  /// List of plugin IDs this plugin depends on
  List<String> get dependencies => [];

  /// Initialize the plugin
  /// Called during app startup after dependencies are loaded
  Future<void> initialize();

  /// Dispose/cleanup the plugin
  /// Called during app shutdown
  Future<void> dispose();

  /// Check if the plugin is healthy and functioning
  Future<bool> healthCheck();

  /// Get plugin status information for debugging
  Map<String, dynamic> getStatus();
}

/// Plugin lifecycle states
enum PluginState {
  unloaded,
  loading,
  loaded,
  initializing,
  ready,
  error,
  disposing,
  disposed,
}

/// Plugin metadata for registration and discovery
class PluginMetadata {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String minAppShellVersion;
  final List<String> dependencies;
  final PluginType type;

  const PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.minAppShellVersion,
    this.dependencies = const [],
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'author': author,
        'minAppShellVersion': minAppShellVersion,
        'dependencies': dependencies,
        'type': type.name,
      };

  factory PluginMetadata.fromJson(Map<String, dynamic> json) => PluginMetadata(
        id: json['id'],
        name: json['name'],
        version: json['version'],
        description: json['description'],
        author: json['author'],
        minAppShellVersion: json['minAppShellVersion'],
        dependencies: List<String>.from(json['dependencies'] ?? []),
        type: PluginType.values.firstWhere((e) => e.name == json['type']),
      );
}

/// Types of plugins supported by App Shell
enum PluginType {
  service,
  widget,
  theme,
  workflow,
}

/// Exception thrown when plugin operations fail
class PluginException implements Exception {
  final String message;
  final String pluginId;
  final dynamic cause;

  const PluginException(this.message, this.pluginId, [this.cause]);

  @override
  String toString() =>
      'PluginException($pluginId): $message${cause != null ? ' - $cause' : ''}';
}
