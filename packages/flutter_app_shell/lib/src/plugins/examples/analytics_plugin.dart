import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';
import '../interfaces/service_plugin.dart';

/// Example Analytics Service Plugin
/// Demonstrates how to create a service plugin that provides analytics capabilities
class AnalyticsPlugin extends BaseServicePlugin
    with BackgroundServiceMixin, PersistentServiceMixin {
  @override
  String get id => 'com.example.analytics';

  @override
  String get name => 'Analytics Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description =>
      'Provides analytics tracking and reporting capabilities';

  @override
  String get author => 'Flutter App Shell Team';

  @override
  String get minAppShellVersion => '0.1.0';

  @override
  List<Type> get serviceTypes => [AnalyticsService];

  @override
  Map<String, dynamic> get defaultConfiguration => {
        'trackingEnabled': true,
        'debugMode': false,
        'sessionTimeout': 1800, // 30 minutes
        'maxEventsPerBatch': 100,
        'batchFlushInterval': 60, // seconds
      };

  late AnalyticsService _analyticsService;

  @override
  Future<void> registerServices(GetIt getIt) async {
    _analyticsService = AnalyticsService(defaultConfiguration);
    getIt.registerSingleton<AnalyticsService>(_analyticsService);
  }

  @override
  Future<void> unregisterServices(GetIt getIt) async {
    if (getIt.isRegistered<AnalyticsService>()) {
      await _analyticsService.dispose();
      getIt.unregister<AnalyticsService>();
    }
  }

  @override
  Future<void> onInitialize() async {
    await _analyticsService.initialize();
    await loadState();
  }

  @override
  Future<void> onDispose() async {
    await saveState();
    await _analyticsService.dispose();
  }

  @override
  Future<bool> performHealthCheck() async {
    return _analyticsService.isHealthy;
  }

  @override
  Map<String, dynamic> getStatus() {
    final baseStatus = super.getStatus();
    return {
      ...baseStatus,
      'eventsTracked': _analyticsService.totalEventsTracked.value,
      'sessionsTracked': _analyticsService.totalSessions.value,
      'isTracking': _analyticsService.isTrackingEnabled.value,
      'queueSize': _analyticsService.eventQueueSize.value,
    };
  }

  // BackgroundServiceMixin implementation
  @override
  Duration? get backgroundInterval => const Duration(seconds: 60);

  @override
  bool get runInBackground => true;

  @override
  Future<void> performBackgroundWork() async {
    await _analyticsService.flushEventQueue();
  }

  // PersistentServiceMixin implementation
  @override
  Future<void> saveState() async {
    // Save analytics state to persistent storage
    final state = {
      'totalEvents': _analyticsService.totalEventsTracked.value,
      'totalSessions': _analyticsService.totalSessions.value,
      'lastSessionId': _analyticsService.currentSessionId,
    };
    // In a real implementation, save to SharedPreferences or database
    print('Saving analytics state: $state');
  }

  @override
  Future<void> loadState() async {
    // Load analytics state from persistent storage
    // In a real implementation, load from SharedPreferences or database
    print('Loading analytics state...');
  }

  @override
  Future<void> clearState() async {
    _analyticsService.clearAllData();
  }
}

/// Analytics Service provided by the plugin
class AnalyticsService {
  final Map<String, dynamic> _configuration;
  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;
  String? _currentSessionId;
  DateTime? _sessionStartTime;

  // Reactive signals for monitoring
  final _totalEventsTracked = signal(0);
  final _totalSessions = signal(0);
  final _isTrackingEnabled = signal(true);
  final _eventQueueSize = signal(0);

  Signal<int> get totalEventsTracked => _totalEventsTracked;
  Signal<int> get totalSessions => _totalSessions;
  Signal<bool> get isTrackingEnabled => _isTrackingEnabled;
  Signal<int> get eventQueueSize => _eventQueueSize;

  String? get currentSessionId => _currentSessionId;
  bool get isHealthy => _isTrackingEnabled.value && _currentSessionId != null;

  AnalyticsService(this._configuration);

  Future<void> initialize() async {
    _isTrackingEnabled.value = _configuration['trackingEnabled'] ?? true;

    if (_isTrackingEnabled.value) {
      await _startNewSession();
      _startFlushTimer();
    }
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flushEventQueue();
    await _endSession();
  }

  /// Track a custom event
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? parameters]) async {
    if (!_isTrackingEnabled.value) return;

    final event = AnalyticsEvent(
      name: eventName,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
      sessionId: _currentSessionId ?? 'unknown',
    );

    _eventQueue.add(event);
    _eventQueueSize.value = _eventQueue.length;
    _totalEventsTracked.value++;

    // Check if we should flush
    if (_eventQueue.length >= (_configuration['maxEventsPerBatch'] ?? 100)) {
      await flushEventQueue();
    }

    // Log in debug mode
    if (_configuration['debugMode'] == true) {
      print('[Analytics] Event: $eventName, Parameters: $parameters');
    }
  }

  /// Track a screen view
  Future<void> trackScreenView(String screenName,
      [Map<String, dynamic>? parameters]) async {
    await trackEvent('screen_view', {
      'screen_name': screenName,
      ...?parameters,
    });
  }

  /// Track user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isTrackingEnabled.value) return;

    await trackEvent('user_properties_updated', properties);
  }

  /// Track user ID
  Future<void> setUserId(String userId) async {
    if (!_isTrackingEnabled.value) return;

    await trackEvent('user_id_set', {'user_id': userId});
  }

  /// Enable or disable tracking
  void setTrackingEnabled(bool enabled) {
    _isTrackingEnabled.value = enabled;

    if (enabled && _currentSessionId == null) {
      _startNewSession();
      _startFlushTimer();
    } else if (!enabled) {
      _flushTimer?.cancel();
      flushEventQueue();
    }
  }

  /// Flush event queue (send to backend)
  Future<void> flushEventQueue() async {
    if (_eventQueue.isEmpty) return;

    final eventsToSend = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();
    _eventQueueSize.value = 0;

    try {
      // In a real implementation, send to analytics backend
      if (_configuration['debugMode'] == true) {
        print('[Analytics] Flushing ${eventsToSend.length} events');
        for (final event in eventsToSend) {
          print('  - ${event.name} at ${event.timestamp}');
        }
      }

      // Simulate network call
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // On error, add events back to queue
      _eventQueue.insertAll(0, eventsToSend);
      _eventQueueSize.value = _eventQueue.length;
      print('[Analytics] Failed to flush events: $e');
    }
  }

  /// Clear all analytics data
  void clearAllData() {
    _eventQueue.clear();
    _eventQueueSize.value = 0;
    _totalEventsTracked.value = 0;
    _totalSessions.value = 0;
  }

  Future<void> _startNewSession() async {
    _currentSessionId = _generateSessionId();
    _sessionStartTime = DateTime.now();
    _totalSessions.value++;

    await trackEvent('session_start', {
      'session_id': _currentSessionId,
      'timestamp': _sessionStartTime!.toIso8601String(),
    });
  }

  Future<void> _endSession() async {
    if (_currentSessionId == null) return;

    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    await trackEvent('session_end', {
      'session_id': _currentSessionId,
      'duration_seconds': duration,
    });

    _currentSessionId = null;
    _sessionStartTime = null;
  }

  void _startFlushTimer() {
    final interval = _configuration['batchFlushInterval'] ?? 60;
    _flushTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => flushEventQueue(),
    );
  }

  String _generateSessionId() {
    final now = DateTime.now();
    return 'session_${now.millisecondsSinceEpoch}_${now.microsecond}';
  }
}

/// Analytics event data model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String sessionId;

  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'parameters': parameters,
        'timestamp': timestamp.toIso8601String(),
        'sessionId': sessionId,
      };
}
