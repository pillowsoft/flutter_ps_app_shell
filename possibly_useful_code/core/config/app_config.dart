class AppConfig {
  // WebSocket configuration
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  // API configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Session configuration
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const int maxDevicesPerSession = 10;
  static const int maxSessionNameLength = 50;

  // Recording configuration
  static const Duration maxRecordingDuration = Duration(hours: 2);
  static const int minRecordingDurationSeconds = 3;

  // Sync configuration
  static const Duration syncInterval = Duration(milliseconds: 100);
  static const int syncBufferSize = 100;

  // Device configuration
  static const String deviceIdKey = 'device_id';
  static const String deviceNameKey = 'device_name';

  // Storage configuration
  static const String recordingsDirectory = 'recordings';
  static const String tempDirectory = 'temp';
  static const String metadataDirectory = 'metadata';

  // Feature flags
  static const bool enableWebSocket = bool.fromEnvironment(
    'ENABLE_WEBSOCKET',
    defaultValue: true,
  );

  static const bool enableOfflineMode = bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );

  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: true,
  );

  // Development settings
  static const bool isDevelopment = bool.fromEnvironment(
    'DEVELOPMENT',
    defaultValue: true,
  );

  // Get environment-specific WebSocket URL
  static String getWebSocketUrl() {
    if (isDevelopment) {
      return 'ws://localhost:8080/ws';
    }
    return websocketUrl;
  }

  // Get environment-specific API URL
  static String getApiUrl(String endpoint) {
    final base = isDevelopment ? 'http://localhost:8080' : apiBaseUrl;
    return '$base$endpoint';
  }
}
