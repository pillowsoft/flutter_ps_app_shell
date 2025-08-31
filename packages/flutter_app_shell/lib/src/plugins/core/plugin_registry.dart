import 'dart:collection';
import 'package:signals/signals.dart';
import '../interfaces/base_plugin.dart';
import '../interfaces/service_plugin.dart';
import '../interfaces/widget_plugin.dart';
import '../interfaces/theme_plugin.dart';
import '../interfaces/workflow_plugin.dart';

/// Registry that tracks all loaded plugins and their states
class PluginRegistry {
  static final PluginRegistry _instance = PluginRegistry._internal();
  factory PluginRegistry() => _instance;
  PluginRegistry._internal();

  final Map<String, BasePlugin> _plugins = {};
  final Map<PluginType, List<String>> _pluginsByType = {
    for (final type in PluginType.values) type: <String>[],
  };
  final Map<String, PluginState> _pluginStates = {};
  final Map<String, List<String>> _dependencyGraph = {};

  /// Signal that emits when plugins are added/removed/changed
  final _pluginsChanged = signal(0);
  Signal<int> get pluginsChanged => _pluginsChanged;

  /// Register a plugin with the registry
  void register(BasePlugin plugin) {
    if (_plugins.containsKey(plugin.id)) {
      throw PluginException(
        'Plugin with ID ${plugin.id} is already registered',
        plugin.id,
      );
    }

    _plugins[plugin.id] = plugin;
    _pluginsByType[plugin.type]!.add(plugin.id);
    _pluginStates[plugin.id] = PluginState.loaded;
    _dependencyGraph[plugin.id] = List.from(plugin.dependencies);

    _pluginsChanged.value++;
  }

  /// Unregister a plugin from the registry
  void unregister(String pluginId) {
    final plugin = _plugins.remove(pluginId);
    if (plugin != null) {
      _pluginsByType[plugin.type]!.remove(pluginId);
      _pluginStates.remove(pluginId);
      _dependencyGraph.remove(pluginId);
      _pluginsChanged.value++;
    }
  }

  /// Get a plugin by ID
  T? getPlugin<T extends BasePlugin>(String pluginId) {
    return _plugins[pluginId] as T?;
  }

  /// Get all plugins of a specific type
  List<T> getPluginsByType<T extends BasePlugin>(PluginType type) {
    final pluginIds = _pluginsByType[type] ?? [];
    return pluginIds.map((id) => _plugins[id]).whereType<T>().toList();
  }

  /// Get all service plugins
  List<ServicePlugin> get servicePlugins =>
      getPluginsByType<ServicePlugin>(PluginType.service);

  /// Get all widget extension plugins
  List<WidgetExtensionPlugin> get widgetPlugins =>
      getPluginsByType<WidgetExtensionPlugin>(PluginType.widget);

  /// Get all theme plugins
  List<ThemePlugin> get themePlugins =>
      getPluginsByType<ThemePlugin>(PluginType.theme);

  /// Get all workflow plugins
  List<WorkflowPlugin> get workflowPlugins =>
      getPluginsByType<WorkflowPlugin>(PluginType.workflow);

  /// Get all registered plugins
  List<BasePlugin> get allPlugins => UnmodifiableListView(_plugins.values);

  /// Get plugin IDs by type
  List<String> getPluginIdsByType(PluginType type) {
    return List.from(_pluginsByType[type] ?? []);
  }

  /// Check if a plugin is registered
  bool isRegistered(String pluginId) => _plugins.containsKey(pluginId);

  /// Get plugin state
  PluginState? getPluginState(String pluginId) => _pluginStates[pluginId];

  /// Update plugin state
  void updatePluginState(String pluginId, PluginState state) {
    if (_plugins.containsKey(pluginId)) {
      _pluginStates[pluginId] = state;
      _pluginsChanged.value++;
    }
  }

  /// Get dependency graph
  Map<String, List<String>> get dependencyGraph => Map.from(_dependencyGraph);

  /// Resolve plugin loading order based on dependencies
  List<String> resolveLoadOrder() {
    final resolved = <String>[];
    final visiting = <String>{};
    final visited = <String>{};

    void visit(String pluginId) {
      if (visited.contains(pluginId)) return;
      if (visiting.contains(pluginId)) {
        throw PluginException(
          'Circular dependency detected involving plugin $pluginId',
          pluginId,
        );
      }

      visiting.add(pluginId);

      final dependencies = _dependencyGraph[pluginId] ?? [];
      for (final dep in dependencies) {
        if (!_plugins.containsKey(dep)) {
          throw PluginException(
            'Plugin $pluginId depends on unregistered plugin $dep',
            pluginId,
          );
        }
        visit(dep);
      }

      visiting.remove(pluginId);
      visited.add(pluginId);
      resolved.add(pluginId);
    }

    for (final pluginId in _plugins.keys) {
      if (!visited.contains(pluginId)) {
        visit(pluginId);
      }
    }

    return resolved;
  }

  /// Get plugins that depend on a specific plugin
  List<String> getDependents(String pluginId) {
    final dependents = <String>[];
    for (final entry in _dependencyGraph.entries) {
      if (entry.value.contains(pluginId)) {
        dependents.add(entry.key);
      }
    }
    return dependents;
  }

  /// Validate all plugin dependencies
  List<String> validateDependencies() {
    final errors = <String>[];

    for (final entry in _dependencyGraph.entries) {
      final pluginId = entry.key;
      final dependencies = entry.value;

      for (final dep in dependencies) {
        if (!_plugins.containsKey(dep)) {
          errors.add('Plugin $pluginId depends on unregistered plugin $dep');
        }
      }
    }

    // Check for circular dependencies
    try {
      resolveLoadOrder();
    } catch (e) {
      if (e is PluginException && e.message.contains('Circular dependency')) {
        errors.add(e.message);
      }
    }

    return errors;
  }

  /// Get registry statistics
  Map<String, dynamic> getStatistics() {
    final statsByType = <String, int>{};
    final statesByState = <String, int>{};

    for (final type in PluginType.values) {
      statsByType[type.name] = _pluginsByType[type]!.length;
    }

    for (final state in _pluginStates.values) {
      statesByState[state.name] = (statesByState[state.name] ?? 0) + 1;
    }

    return {
      'totalPlugins': _plugins.length,
      'pluginsByType': statsByType,
      'pluginsByState': statesByState,
      'dependencyErrors': validateDependencies().length,
    };
  }

  /// Clear all plugins (for testing)
  void clear() {
    _plugins.clear();
    for (final list in _pluginsByType.values) {
      list.clear();
    }
    _pluginStates.clear();
    _dependencyGraph.clear();
    _pluginsChanged.value++;
  }

  /// Export registry state for debugging
  Map<String, dynamic> exportState() {
    return {
      'plugins': _plugins.keys.toList(),
      'pluginsByType': Map.fromEntries(
        _pluginsByType.entries.map((e) => MapEntry(e.key.name, e.value)),
      ),
      'pluginStates': Map.fromEntries(
        _pluginStates.entries.map((e) => MapEntry(e.key, e.value.name)),
      ),
      'dependencyGraph': _dependencyGraph,
      'statistics': getStatistics(),
    };
  }
}
