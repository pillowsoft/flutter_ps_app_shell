import 'dart:async';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';
import '../interfaces/base_plugin.dart';
import '../interfaces/service_plugin.dart';
import '../interfaces/widget_plugin.dart';
import '../interfaces/theme_plugin.dart';
import '../interfaces/workflow_plugin.dart';
import 'plugin_registry.dart';
import 'plugin_discovery.dart';

/// Central manager for plugin discovery, loading, and lifecycle management
class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();

  final PluginRegistry _registry = PluginRegistry();
  final PluginDiscovery _discovery = PluginDiscovery();
  final GetIt _getIt = GetIt.instance;

  bool _initialized = false;
  bool _disposed = false;
  final List<String> _initializationOrder = [];

  /// Signal that emits when plugin states change
  final _stateChanged = signal(0);
  Signal<int> get stateChanged => _stateChanged;

  /// Registry instance
  PluginRegistry get registry => _registry;

  /// Discovery instance
  PluginDiscovery get discovery => _discovery;

  /// Whether plugin manager is initialized
  bool get isInitialized => _initialized;

  /// Whether plugin manager is disposed
  bool get isDisposed => _disposed;

  /// Initialize the plugin manager and load all discovered plugins
  Future<void> initialize({
    bool enableAutoDiscovery = true,
    List<BasePlugin> manualPlugins = const [],
    Map<String, dynamic> configuration = const {},
  }) async {
    if (_initialized) {
      developer.log('PluginManager already initialized', name: 'PluginManager');
      return;
    }

    if (_disposed) {
      throw PluginException(
        'PluginManager has been disposed and cannot be reinitialized',
        'plugin_manager',
      );
    }

    developer.log('Initializing PluginManager...', name: 'PluginManager');

    try {
      // Register manual plugins first
      for (final plugin in manualPlugins) {
        _registry.register(plugin);
      }

      // Auto-discover plugins if enabled
      if (enableAutoDiscovery) {
        final discoveredPlugins = await _discovery.discoverPlugins();
        for (final plugin in discoveredPlugins) {
          if (!_registry.isRegistered(plugin.id)) {
            _registry.register(plugin);
          }
        }
      }

      // Validate dependencies
      final dependencyErrors = _registry.validateDependencies();
      if (dependencyErrors.isNotEmpty) {
        throw PluginException(
          'Plugin dependency validation failed: ${dependencyErrors.join(', ')}',
          'plugin_manager',
        );
      }

      // Resolve loading order
      final loadOrder = _registry.resolveLoadOrder();
      _initializationOrder.addAll(loadOrder);

      developer.log(
        'Loading ${loadOrder.length} plugins in order: ${loadOrder.join(', ')}',
        name: 'PluginManager',
      );

      // Initialize plugins in dependency order
      for (final pluginId in loadOrder) {
        await _initializePlugin(pluginId, configuration);
      }

      _initialized = true;
      _stateChanged.value++;

      developer.log(
        'PluginManager initialized successfully with ${_registry.allPlugins.length} plugins',
        name: 'PluginManager',
      );
    } catch (e) {
      developer.log(
        'Failed to initialize PluginManager: $e',
        name: 'PluginManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Dispose the plugin manager and all loaded plugins
  Future<void> dispose() async {
    if (_disposed) return;

    developer.log('Disposing PluginManager...', name: 'PluginManager');

    try {
      // Dispose plugins in reverse order
      final disposeOrder = _initializationOrder.reversed.toList();

      for (final pluginId in disposeOrder) {
        await _disposePlugin(pluginId);
      }

      _registry.clear();
      _initializationOrder.clear();
      _initialized = false;
      _disposed = true;

      developer.log('PluginManager disposed successfully',
          name: 'PluginManager');
    } catch (e) {
      developer.log(
        'Error disposing PluginManager: $e',
        name: 'PluginManager',
        error: e,
      );
    }
  }

  /// Manually register a plugin
  Future<void> registerPlugin(BasePlugin plugin) async {
    if (_disposed) {
      throw PluginException(
        'Cannot register plugin on disposed PluginManager',
        plugin.id,
      );
    }

    _registry.register(plugin);

    if (_initialized) {
      // If manager is already initialized, initialize this plugin immediately
      await _initializePlugin(plugin.id, {});
      _initializationOrder.add(plugin.id);
    }

    _stateChanged.value++;
  }

  /// Manually unregister a plugin
  Future<void> unregisterPlugin(String pluginId) async {
    if (_disposed) return;

    await _disposePlugin(pluginId);
    _registry.unregister(pluginId);
    _initializationOrder.remove(pluginId);
    _stateChanged.value++;
  }

  /// Get a plugin by ID
  T? getPlugin<T extends BasePlugin>(String pluginId) {
    return _registry.getPlugin<T>(pluginId);
  }

  /// Get all plugins of a specific type
  List<T> getPluginsByType<T extends BasePlugin>(PluginType type) {
    return _registry.getPluginsByType<T>(type);
  }

  /// Reload a specific plugin
  Future<void> reloadPlugin(String pluginId) async {
    if (!_registry.isRegistered(pluginId)) {
      throw PluginException('Plugin $pluginId is not registered', pluginId);
    }

    developer.log('Reloading plugin: $pluginId', name: 'PluginManager');

    // Dispose and reinitialize
    await _disposePlugin(pluginId);
    await _initializePlugin(pluginId, {});

    _stateChanged.value++;
  }

  /// Perform health check on all plugins
  Future<Map<String, bool>> performHealthChecks() async {
    final results = <String, bool>{};

    for (final plugin in _registry.allPlugins) {
      try {
        results[plugin.id] = await plugin.healthCheck();
      } catch (e) {
        results[plugin.id] = false;
        developer.log(
          'Health check failed for plugin ${plugin.id}: $e',
          name: 'PluginManager',
          error: e,
        );
      }
    }

    return results;
  }

  /// Get comprehensive status of all plugins
  Map<String, dynamic> getPluginStatuses() {
    final statuses = <String, dynamic>{};

    for (final plugin in _registry.allPlugins) {
      statuses[plugin.id] = {
        ...plugin.getStatus(),
        'metadata': {
          'name': plugin.name,
          'version': plugin.version,
          'author': plugin.author,
          'type': plugin.type.name,
        },
      };
    }

    return statuses;
  }

  /// Initialize a specific plugin
  Future<void> _initializePlugin(
      String pluginId, Map<String, dynamic> configuration) async {
    final plugin = _registry.getPlugin(pluginId);
    if (plugin == null) {
      throw PluginException('Plugin $pluginId not found in registry', pluginId);
    }

    try {
      _registry.updatePluginState(pluginId, PluginState.initializing);

      developer.log('Initializing plugin: ${plugin.name} (${plugin.id})',
          name: 'PluginManager');

      // Type-specific initialization
      if (plugin is ServicePlugin) {
        await _initializeServicePlugin(plugin);
      } else if (plugin is WidgetExtensionPlugin) {
        await _initializeWidgetPlugin(plugin);
      } else if (plugin is ThemePlugin) {
        await _initializeThemePlugin(plugin);
      } else if (plugin is WorkflowPlugin) {
        await _initializeWorkflowPlugin(plugin);
      }

      // Common initialization
      await plugin.initialize();

      _registry.updatePluginState(pluginId, PluginState.ready);

      developer.log('Plugin initialized: ${plugin.name}',
          name: 'PluginManager');
    } catch (e) {
      _registry.updatePluginState(pluginId, PluginState.error);
      developer.log(
        'Failed to initialize plugin ${plugin.name}: $e',
        name: 'PluginManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Dispose a specific plugin
  Future<void> _disposePlugin(String pluginId) async {
    final plugin = _registry.getPlugin(pluginId);
    if (plugin == null) return;

    try {
      _registry.updatePluginState(pluginId, PluginState.disposing);

      developer.log('Disposing plugin: ${plugin.name}', name: 'PluginManager');

      await plugin.dispose();

      // Type-specific cleanup
      if (plugin is ServicePlugin) {
        await _disposeServicePlugin(plugin);
      }

      _registry.updatePluginState(pluginId, PluginState.disposed);
    } catch (e) {
      _registry.updatePluginState(pluginId, PluginState.error);
      developer.log(
        'Error disposing plugin ${plugin.name}: $e',
        name: 'PluginManager',
        error: e,
      );
    }
  }

  /// Initialize a service plugin
  Future<void> _initializeServicePlugin(ServicePlugin plugin) async {
    await plugin.registerServices(_getIt);
  }

  /// Initialize a widget plugin
  Future<void> _initializeWidgetPlugin(WidgetExtensionPlugin plugin) async {
    await plugin.registerWidgets();
  }

  /// Initialize a theme plugin
  Future<void> _initializeThemePlugin(ThemePlugin plugin) async {
    await plugin.registerTheme();
  }

  /// Initialize a workflow plugin
  Future<void> _initializeWorkflowPlugin(WorkflowPlugin plugin) async {
    await plugin.registerWorkflows();
  }

  /// Dispose a service plugin
  Future<void> _disposeServicePlugin(ServicePlugin plugin) async {
    await plugin.unregisterServices(_getIt);
  }

  /// Get plugin manager statistics
  Map<String, dynamic> getStatistics() {
    return {
      'initialized': _initialized,
      'disposed': _disposed,
      'initializationOrder': _initializationOrder,
      'registry': _registry.getStatistics(),
    };
  }
}
