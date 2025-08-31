import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../interfaces/base_plugin.dart';

/// Plugin discovery system that finds and loads plugins automatically
class PluginDiscovery {
  static final PluginDiscovery _instance = PluginDiscovery._internal();
  factory PluginDiscovery() => _instance;
  PluginDiscovery._internal();

  static const String _pluginPrefix = 'flutter_app_shell_';
  static const String _pluginSuffix = '_plugin';

  /// Discover all available plugins
  Future<List<BasePlugin>> discoverPlugins() async {
    final plugins = <BasePlugin>[];

    try {
      // Discover from pubspec.yaml dependencies
      final pubspecPlugins = await _discoverFromPubspec();
      plugins.addAll(pubspecPlugins);

      // Discover from plugin directories (for development)
      final directoryPlugins = await _discoverFromDirectories();
      plugins.addAll(directoryPlugins);

      developer.log(
        'Discovered ${plugins.length} plugins',
        name: 'PluginDiscovery',
      );
    } catch (e) {
      developer.log(
        'Error during plugin discovery: $e',
        name: 'PluginDiscovery',
        error: e,
      );
    }

    return plugins;
  }

  /// Discover plugins from pubspec.yaml dependencies
  Future<List<BasePlugin>> _discoverFromPubspec() async {
    final plugins = <BasePlugin>[];

    try {
      final pubspecFile = File('pubspec.yaml');
      if (!await pubspecFile.exists()) {
        developer.log('pubspec.yaml not found', name: 'PluginDiscovery');
        return plugins;
      }

      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as Map;

      final dependencies = yaml['dependencies'] as Map?;
      if (dependencies == null) return plugins;

      // Look for plugin dependencies
      for (final entry in dependencies.entries) {
        final packageName = entry.key as String;

        if (_isPluginPackage(packageName)) {
          try {
            final plugin = await _loadPluginFromPackage(packageName);
            if (plugin != null) {
              plugins.add(plugin);
            }
          } catch (e) {
            developer.log(
              'Failed to load plugin from package $packageName: $e',
              name: 'PluginDiscovery',
              error: e,
            );
          }
        }
      }
    } catch (e) {
      developer.log(
        'Error reading pubspec.yaml: $e',
        name: 'PluginDiscovery',
        error: e,
      );
    }

    return plugins;
  }

  /// Discover plugins from plugin directories (for development)
  Future<List<BasePlugin>> _discoverFromDirectories() async {
    final plugins = <BasePlugin>[];

    final pluginDirs = [
      'plugins',
      'packages/plugins',
      '../plugins',
    ];

    for (final dirPath in pluginDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            try {
              final plugin = await _loadPluginFromDirectory(entity);
              if (plugin != null) {
                plugins.add(plugin);
              }
            } catch (e) {
              developer.log(
                'Failed to load plugin from directory ${entity.path}: $e',
                name: 'PluginDiscovery',
                error: e,
              );
            }
          }
        }
      }
    }

    return plugins;
  }

  /// Check if a package name follows plugin naming conventions
  bool _isPluginPackage(String packageName) {
    return packageName.startsWith(_pluginPrefix) ||
        packageName.endsWith(_pluginSuffix);
  }

  /// Load a plugin from a package
  Future<BasePlugin?> _loadPluginFromPackage(String packageName) async {
    // This is a placeholder implementation
    // In a real implementation, we would use reflection or code generation
    // to dynamically load plugin classes from packages

    developer.log(
      'Plugin loading from packages not yet implemented: $packageName',
      name: 'PluginDiscovery',
    );

    // For now, we'll need to manually register known plugins
    // or use a plugin registry system
    return null;
  }

  /// Load a plugin from a directory
  Future<BasePlugin?> _loadPluginFromDirectory(Directory dir) async {
    try {
      // Look for plugin.yaml or pubspec.yaml in the directory
      final pluginYaml = File(path.join(dir.path, 'plugin.yaml'));
      final pubspecYaml = File(path.join(dir.path, 'pubspec.yaml'));

      Map? pluginConfig;

      if (await pluginYaml.exists()) {
        final content = await pluginYaml.readAsString();
        pluginConfig = loadYaml(content) as Map;
      } else if (await pubspecYaml.exists()) {
        final content = await pubspecYaml.readAsString();
        final yaml = loadYaml(content) as Map;
        pluginConfig = yaml['flutter_app_shell_plugin'] as Map?;
      }

      if (pluginConfig == null) return null;

      // Extract plugin metadata
      final metadata =
          PluginMetadata.fromJson(Map<String, dynamic>.from(pluginConfig));

      developer.log(
        'Found plugin configuration: ${metadata.name} (${metadata.id})',
        name: 'PluginDiscovery',
      );

      // This is where we would dynamically load the plugin class
      // For now, return null as we need the actual plugin implementation
      return null;
    } catch (e) {
      developer.log(
        'Error loading plugin from directory ${dir.path}: $e',
        name: 'PluginDiscovery',
        error: e,
      );
      return null;
    }
  }

  /// Validate plugin metadata
  bool validatePluginMetadata(PluginMetadata metadata) {
    // Check required fields
    if (metadata.id.isEmpty ||
        metadata.name.isEmpty ||
        metadata.version.isEmpty) {
      return false;
    }

    // Check version format (basic validation)
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+');
    if (!versionRegex.hasMatch(metadata.version)) {
      return false;
    }

    return true;
  }

  /// Get plugin information from directory without loading
  Future<PluginMetadata?> getPluginInfo(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return null;

      final pluginYaml = File(path.join(directoryPath, 'plugin.yaml'));
      final pubspecYaml = File(path.join(directoryPath, 'pubspec.yaml'));

      Map? pluginConfig;

      if (await pluginYaml.exists()) {
        final content = await pluginYaml.readAsString();
        pluginConfig = loadYaml(content) as Map;
      } else if (await pubspecYaml.exists()) {
        final content = await pubspecYaml.readAsString();
        final yaml = loadYaml(content) as Map;
        pluginConfig = yaml['flutter_app_shell_plugin'] as Map?;
      }

      if (pluginConfig != null) {
        return PluginMetadata.fromJson(Map<String, dynamic>.from(pluginConfig));
      }
    } catch (e) {
      developer.log(
        'Error getting plugin info from $directoryPath: $e',
        name: 'PluginDiscovery',
        error: e,
      );
    }

    return null;
  }

  /// Scan for available plugin directories
  Future<List<String>> scanPluginDirectories() async {
    final pluginPaths = <String>[];

    final pluginDirs = [
      'plugins',
      'packages/plugins',
      '../plugins',
    ];

    for (final dirPath in pluginDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is Directory) {
            final info = await getPluginInfo(entity.path);
            if (info != null) {
              pluginPaths.add(entity.path);
            }
          }
        }
      }
    }

    return pluginPaths;
  }
}
