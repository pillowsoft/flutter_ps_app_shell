import 'package:get_it/get_it.dart';
import 'base_plugin.dart';

/// Interface for service plugins that provide business logic and data access
abstract class ServicePlugin extends BasePlugin {
  @override
  PluginType get type => PluginType.service;

  /// Service types this plugin provides
  /// Used for GetIt registration
  List<Type> get serviceTypes;

  /// Register services with GetIt dependency injection container
  Future<void> registerServices(GetIt getIt);

  /// Unregister services from GetIt container
  Future<void> unregisterServices(GetIt getIt);

  /// Optional: Service configuration
  Map<String, dynamic> get defaultConfiguration => {};

  /// Optional: Validate service configuration
  bool validateConfiguration(Map<String, dynamic> config) => true;

  /// Optional: Handle configuration changes
  Future<void> updateConfiguration(Map<String, dynamic> config) async {}
}

/// Mixin for services that need reactive state management
mixin ReactiveServiceMixin on ServicePlugin {
  /// Services that use signals should implement this to expose reactive state
  Map<String, dynamic> get reactiveState => {};
}

/// Mixin for services that need periodic background work
mixin BackgroundServiceMixin on ServicePlugin {
  /// How often to run background tasks (null = no background work)
  Duration? get backgroundInterval => null;

  /// Perform background work
  Future<void> performBackgroundWork();

  /// Whether background work should run when app is in background
  bool get runInBackground => false;
}

/// Mixin for services that need to persist data
mixin PersistentServiceMixin on ServicePlugin {
  /// Save service state to persistent storage
  Future<void> saveState();

  /// Load service state from persistent storage
  Future<void> loadState();

  /// Clear all persistent state
  Future<void> clearState();
}

/// Base class for common service plugin implementations
abstract class BaseServicePlugin extends ServicePlugin {
  PluginState _state = PluginState.unloaded;
  Exception? _lastError;
  DateTime? _lastHealthCheck;
  bool _isHealthy = false;

  PluginState get state => _state;
  Exception? get lastError => _lastError;
  DateTime? get lastHealthCheck => _lastHealthCheck;
  bool get isHealthy => _isHealthy;

  @override
  Future<void> initialize() async {
    try {
      _state = PluginState.initializing;
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
    try {
      _lastHealthCheck = DateTime.now();
      _isHealthy = await performHealthCheck();
      return _isHealthy;
    } catch (e) {
      _lastError = e is Exception ? e : Exception(e.toString());
      _isHealthy = false;
      return false;
    }
  }

  @override
  Map<String, dynamic> getStatus() => {
        'state': _state.name,
        'isHealthy': _isHealthy,
        'lastHealthCheck': _lastHealthCheck?.toIso8601String(),
        'lastError': _lastError?.toString(),
        'serviceTypes': serviceTypes.map((t) => t.toString()).toList(),
      };

  /// Override to implement plugin-specific initialization
  Future<void> onInitialize();

  /// Override to implement plugin-specific disposal
  Future<void> onDispose();

  /// Override to implement plugin-specific health checking
  Future<bool> performHealthCheck() async => true;
}
