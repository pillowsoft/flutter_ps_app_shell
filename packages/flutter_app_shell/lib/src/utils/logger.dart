import 'package:logging/logging.dart';
import '../services/logging_service.dart';

// Global logger for backward compatibility
late Logger logger;

/// Backward compatible logger class that wraps the new logging service
class AppShellLogger {
  static late Logger _logger;
  static bool _initialized = false;

  /// Initialize the logger (called automatically)
  static void _ensureInitialized() {
    if (!_initialized) {
      // Use LoggingService to get a logger named 'AppShell'
      _logger = LoggingService.instance.getLogger('AppShell');
      logger = _logger; // Set global logger for backward compatibility
      _initialized = true;
    }
  }

  /// Debug level logging
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (message is Function) {
      _logger.fine(message, error, stackTrace);
    } else {
      _logger.fine(message?.toString() ?? 'null', error, stackTrace);
    }
  }

  /// Info level logging
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (message is Function) {
      _logger.info(message, error, stackTrace);
    } else {
      _logger.info(message?.toString() ?? 'null', error, stackTrace);
    }
  }

  /// Warning level logging
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (message is Function) {
      _logger.warning(message, error, stackTrace);
    } else {
      _logger.warning(message?.toString() ?? 'null', error, stackTrace);
    }
  }

  /// Error level logging
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (message is Function) {
      _logger.severe(message, error, stackTrace);
    } else {
      _logger.severe(message?.toString() ?? 'null', error, stackTrace);
    }
  }

  /// Fatal level logging (mapped to shout)
  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (message is Function) {
      _logger.shout(message, error, stackTrace);
    } else {
      _logger.shout(message?.toString() ?? 'null', error, stackTrace);
    }
  }

  /// Get a named logger (for services that want hierarchical logging)
  static Logger getLogger(String name) {
    return LoggingService.instance.getLogger(name);
  }

  /// Set log level for a specific logger
  static void setLoggerLevel(String name, Level level) {
    LoggingService.instance.setLoggerLevel(name, level);
  }

  /// Set global log level from string
  static void setGlobalLevel(String levelString) {
    LoggingService.instance.setLevelFromString(levelString);
  }
}

/// Create a named logger for a service
Logger createServiceLogger(String serviceName) {
  return LoggingService.instance.getLogger(serviceName);
}
