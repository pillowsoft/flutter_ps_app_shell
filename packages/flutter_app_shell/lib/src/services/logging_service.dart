import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Centralized logging service with hierarchical logger support
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();

  LoggingService._();

  bool _isInitialized = false;
  StreamSubscription<LogRecord>? _logSubscription;
  IOSink? _logFile;
  final Map<String, Logger> _loggers = {};

  /// Initialize the logging service
  Future<void> initialize({
    Level globalLevel = Level.INFO,
    bool enableFileLogging = false,
    String? logFilePath,
    bool forceDebugMode = false,
  }) async {
    if (_isInitialized) return;

    // Enable hierarchical logging
    hierarchicalLoggingEnabled = true;

    // Set global log level based on release mode
    Level effectiveLevel = globalLevel;
    if (!kDebugMode && !forceDebugMode) {
      // In release mode, only log warnings and above
      effectiveLevel = Level.WARNING;
      enableFileLogging = false; // Disable file logging in release
    }

    Logger.root.level = effectiveLevel;

    // Set up log stream listener
    _logSubscription = Logger.root.onRecord.listen((record) {
      _handleLogRecord(record);
    });

    // Set up file logging if requested
    if (enableFileLogging && (kDebugMode || forceDebugMode)) {
      await _setupFileLogging(logFilePath);
    }

    _isInitialized = true;

    // Log successful initialization
    final logger = getLogger('LoggingService');
    logger.info(
        'Logging service initialized (level: $effectiveLevel, file: $enableFileLogging)');
  }

  /// Get a logger for a specific name (creates hierarchical loggers)
  Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(name);
    }
    return _loggers[name]!;
  }

  /// Update the global log level
  void setGlobalLevel(Level level) {
    Logger.root.level = level;
    final logger = getLogger('LoggingService');
    logger.config('Global log level set to: $level');
  }

  /// Update log level from string (for settings integration)
  void setLevelFromString(String levelString) {
    final level = _parseLogLevel(levelString);
    setGlobalLevel(level);
  }

  /// Set log level for a specific logger
  void setLoggerLevel(String name, Level level) {
    final logger = getLogger(name);
    logger.level = level;
    final rootLogger = getLogger('LoggingService');
    rootLogger.config('Logger $name level set to: $level');
  }

  /// Parse string log level to Level enum
  Level _parseLogLevel(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'off':
        return Level.OFF;
      case 'shout':
      case 'fatal':
        return Level.SHOUT;
      case 'severe':
      case 'error':
        return Level.SEVERE;
      case 'warning':
      case 'warn':
        return Level.WARNING;
      case 'info':
        return Level.INFO;
      case 'config':
        return Level.CONFIG;
      case 'fine':
      case 'debug':
        return Level.FINE;
      case 'finer':
      case 'trace':
        return Level.FINER;
      case 'finest':
        return Level.FINEST;
      default:
        return Level.INFO;
    }
  }

  /// Handle a log record (console output + file output)
  void _handleLogRecord(LogRecord record) {
    // Format the log message
    final formattedMessage = _formatLogRecord(record);

    // Output to console (in debug mode or if forced)
    if (kDebugMode || record.level >= Level.WARNING) {
      print(formattedMessage);
    }

    // Output to file if enabled
    _logFile?.writeln(formattedMessage);
  }

  /// Format a log record for display
  String _formatLogRecord(LogRecord record) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    final level = record.level.name.padRight(7);
    final logger = record.loggerName.padRight(20);
    final message = record.message;

    String formatted = '[$timestamp] $level [$logger] $message';

    // Add error and stack trace if present
    if (record.error != null) {
      formatted += '\n  Error: ${record.error}';
    }
    if (record.stackTrace != null) {
      formatted += '\n  Stack: ${record.stackTrace}';
    }

    return formatted;
  }

  /// Set up file logging
  Future<void> _setupFileLogging(String? customPath) async {
    try {
      Directory logDir;
      if (customPath != null) {
        logDir = Directory(path.dirname(customPath));
      } else {
        final appDir = await getApplicationSupportDirectory();
        logDir = Directory(path.join(appDir.path, 'logs'));
      }

      // Create logs directory if it doesn't exist
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      // Create log file with timestamp
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final logFileName =
          customPath != null ? path.basename(customPath) : 'app_$timestamp.log';
      final logFile = File(path.join(logDir.path, logFileName));

      // Open file for writing
      _logFile = logFile.openWrite(mode: FileMode.append);

      final logger = getLogger('LoggingService');
      logger.config('File logging enabled: ${logFile.path}');
    } catch (e) {
      final logger = getLogger('LoggingService');
      logger.warning('Failed to set up file logging: $e');
    }
  }

  /// Get current log level as string
  String getCurrentLevelString() {
    final level = Logger.root.level;
    switch (level) {
      case Level.OFF:
        return 'off';
      case Level.SHOUT:
        return 'fatal';
      case Level.SEVERE:
        return 'error';
      case Level.WARNING:
        return 'warning';
      case Level.INFO:
        return 'info';
      case Level.CONFIG:
        return 'config';
      case Level.FINE:
        return 'debug';
      case Level.FINER:
        return 'trace';
      case Level.FINEST:
        return 'finest';
      default:
        return 'info';
    }
  }

  /// Get all registered logger names
  List<String> getLoggerNames() {
    return _loggers.keys.toList()..sort();
  }

  /// Check if logging is initialized
  bool get isInitialized => _isInitialized;

  /// Get current global log level
  Level get currentLevel => Logger.root.level;

  /// Dispose of the logging service
  Future<void> dispose() async {
    await _logSubscription?.cancel();
    await _logFile?.close();
    _loggers.clear();
    _isInitialized = false;
  }
}
