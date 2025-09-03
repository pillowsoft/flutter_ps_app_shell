import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';

/// Comprehensive error handling demonstration
class ErrorHandlingDemoScreen extends StatefulWidget {
  const ErrorHandlingDemoScreen({super.key});

  @override
  State<ErrorHandlingDemoScreen> createState() =>
      _ErrorHandlingDemoScreenState();
}

class _ErrorHandlingDemoScreenState extends State<ErrorHandlingDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Error states
  final List<ErrorDemo> _errorDemos = [];
  ErrorState _currentState = ErrorState.idle;
  String? _lastError;
  bool _isRetrying = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  // Network simulation
  bool _isOffline = false;
  bool _hasSlowConnection = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupErrorDemos();
    _simulateInitialLoad();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _setupErrorDemos() {
    _errorDemos.addAll([
      ErrorDemo(
        id: 'network_timeout',
        title: 'Network Timeout',
        description: 'Simulates a request that times out',
        icon: Icons.timer_off,
        color: Colors.orange,
        errorType: ErrorType.network,
      ),
      ErrorDemo(
        id: 'server_error',
        title: '500 Server Error',
        description: 'Internal server error response',
        icon: Icons.server,
        color: Colors.red,
        errorType: ErrorType.server,
      ),
      ErrorDemo(
        id: 'auth_error',
        title: 'Authentication Failed',
        description: 'User authentication error',
        icon: Icons.lock,
        color: Colors.purple,
        errorType: ErrorType.authentication,
      ),
      ErrorDemo(
        id: 'validation_error',
        title: 'Validation Error',
        description: 'Form validation failure',
        icon: Icons.error_outline,
        color: Colors.amber,
        errorType: ErrorType.validation,
      ),
      ErrorDemo(
        id: 'not_found',
        title: '404 Not Found',
        description: 'Requested resource not found',
        icon: Icons.search_off,
        color: Colors.grey,
        errorType: ErrorType.notFound,
      ),
      ErrorDemo(
        id: 'permission_denied',
        title: 'Permission Denied',
        description: 'Insufficient permissions',
        icon: Icons.block,
        color: Colors.red[900]!,
        errorType: ErrorType.permission,
      ),
      ErrorDemo(
        id: 'data_corruption',
        title: 'Data Corruption',
        description: 'Invalid or corrupted data',
        icon: Icons.broken_image,
        color: Colors.brown,
        errorType: ErrorType.data,
      ),
      ErrorDemo(
        id: 'rate_limit',
        title: 'Rate Limited',
        description: 'Too many requests',
        icon: Icons.speed,
        color: Colors.orange[800]!,
        errorType: ErrorType.rateLimit,
      ),
    ]);
  }

  Future<void> _simulateInitialLoad() async {
    setState(() => _currentState = ErrorState.loading);

    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentState = ErrorState.idle);
  }

  Future<void> _simulateError(ErrorDemo demo) async {
    setState(() {
      _currentState = ErrorState.loading;
      _lastError = null;
      _retryCount = 0;
    });

    // Simulate network delay
    await Future.delayed(Duration(
      milliseconds: _hasSlowConnection ? 3000 : 1000,
    ));

    // Simulate various error scenarios
    if (_isOffline && demo.errorType == ErrorType.network) {
      _handleError(
        AppShellException(
          'No internet connection. Please check your network settings.',
          type: ExceptionType.network,
        ),
        demo,
      );
      return;
    }

    final random = Random();

    switch (demo.errorType) {
      case ErrorType.network:
        if (random.nextBool()) {
          _handleError(
            TimeoutException('Connection timeout', const Duration(seconds: 30)),
            demo,
          );
        } else {
          _handleError(
            const SocketException('Failed to connect to server'),
            demo,
          );
        }
        break;

      case ErrorType.server:
        _handleError(
          HttpException('Internal server error (500)',
              uri: Uri.parse('https://api.example.com/data')),
          demo,
        );
        break;

      case ErrorType.authentication:
        _handleError(
          AppShellException(
            'Authentication failed. Please log in again.',
            type: ExceptionType.authentication,
            details: {
              'error_code': 'AUTH_INVALID_TOKEN',
              'expires_at': DateTime.now().subtract(const Duration(hours: 1)),
            },
          ),
          demo,
        );
        break;

      case ErrorType.validation:
        _handleError(
          AppShellException(
            'Validation failed',
            type: ExceptionType.validation,
            details: {
              'field_errors': {
                'email': 'Invalid email format',
                'password': 'Password must be at least 8 characters',
              },
            },
          ),
          demo,
        );
        break;

      case ErrorType.notFound:
        _handleError(
          AppShellException(
            'The requested resource was not found.',
            type: ExceptionType.notFound,
          ),
          demo,
        );
        break;

      case ErrorType.permission:
        _handleError(
          AppShellException(
            'You do not have permission to access this resource.',
            type: ExceptionType.permission,
          ),
          demo,
        );
        break;

      case ErrorType.data:
        _handleError(
          FormatException('Invalid JSON data', '{"invalid": json}'),
          demo,
        );
        break;

      case ErrorType.rateLimit:
        _handleError(
          AppShellException(
            'Too many requests. Please try again in 60 seconds.',
            type: ExceptionType.rateLimit,
            details: {
              'retry_after': 60,
              'limit': 100,
              'remaining': 0,
            },
          ),
          demo,
        );
        break;
    }
  }

  void _handleError(Object error, ErrorDemo demo) {
    setState(() {
      _currentState = ErrorState.error;
      _lastError = _formatError(error);
    });

    // Trigger shake animation
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });

    // Log error
    AppShellLogger.e('Demo error: ${demo.title}', error);

    // Show error snackbar
    _showErrorSnackBar(error, demo);
  }

  void _showErrorSnackBar(Object error, ErrorDemo demo) {
    final ui = getAdaptiveFactory(context);
    final message = _getErrorMessage(error);

    ui.showSnackBar(
      context,
      message,
      backgroundColor: demo.color,
      duration: const Duration(seconds: 4),
      action: _canRetry(error)
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _retry(demo),
            )
          : null,
    );
  }

  String _formatError(Object error) {
    if (error is AppShellException) {
      String formatted = 'Type: ${error.type}\n';
      formatted += 'Message: ${error.message}\n';
      if (error.details != null) {
        formatted += 'Details: ${error.details}\n';
      }
      return formatted;
    }

    if (error is TimeoutException) {
      return 'Timeout: ${error.message ?? 'Operation timed out'}\n'
          'Duration: ${error.duration}';
    }

    if (error is HttpException) {
      return 'HTTP Error: ${error.message}\n'
          'URI: ${error.uri}';
    }

    if (error is SocketException) {
      return 'Network Error: ${error.message}\n'
          'Address: ${error.address?.address ?? 'Unknown'}';
    }

    if (error is FormatException) {
      return 'Format Error: ${error.message}\n'
          'Source: ${error.source}';
    }

    return error.toString();
  }

  String _getErrorMessage(Object error) {
    if (error is AppShellException) {
      return error.message;
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is HttpException) {
      return 'Server error occurred. Please try again later.';
    }

    if (error is SocketException) {
      return 'Network connection failed. Check your internet.';
    }

    if (error is FormatException) {
      return 'Invalid data format received.';
    }

    return 'An unexpected error occurred.';
  }

  bool _canRetry(Object error) {
    if (error is AppShellException) {
      return error.type != ExceptionType.validation &&
          error.type != ExceptionType.permission;
    }

    if (error is HttpException) {
      // Don't retry 4xx errors except 408 (timeout)
      return !error.message.contains('4') || error.message.contains('408');
    }

    return true;
  }

  Future<void> _retry(ErrorDemo demo) async {
    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    // Exponential backoff
    final delay = Duration(seconds: min(pow(2, _retryCount - 1).toInt(), 10));

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () async {
      if (mounted) {
        setState(() => _isRetrying = false);

        // Random success on retry
        final random = Random();
        if (random.nextDouble() < 0.3) {
          // Success
          setState(() {
            _currentState = ErrorState.success;
            _lastError = null;
          });

          _showSuccessMessage(demo);

          // Reset after success
          Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _currentState = ErrorState.idle);
            }
          });
        } else {
          // Retry failed
          await _simulateError(demo);
        }
      }
    });
  }

  void _showSuccessMessage(ErrorDemo demo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
                '${demo.title} succeeded after ${_retryCount} ${_retryCount == 1 ? 'retry' : 'retries'}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGlobalErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Critical Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A critical error has occurred that requires immediate attention.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Error Code: CRIT_001\n'
                'Component: Core System\n'
                'Timestamp: 2024-01-15 14:30:22',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showErrorReportDialog();
            },
            child: const Text('Report Error'),
          ),
        ],
      ),
    );
  }

  void _showErrorReportDialog() {
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Please describe what you were doing when the error occurred:'),
            const SizedBox(height: 16),
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the steps that led to this error...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following information will be included:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Device information\n'
                    '• App version\n'
                    '• Error logs\n'
                    '• No personal data',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendErrorReport(reportController.text);
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendErrorReport(String userDescription) async {
    // Simulate sending error report
    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Error report sent successfully. Thank you!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final theme = Theme.of(context);
      final ui = getAdaptiveFactory(context);

      return Scaffold(
        key: ValueKey('error_demo_scaffold_$uiSystem'),
        appBar: AppBar(
          title: const Text('Error Handling Demo'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'offline',
                  child: Row(
                    children: [
                      Icon(
                        _isOffline ? Icons.wifi_off : Icons.wifi,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_isOffline ? 'Go Online' : 'Go Offline'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'slow',
                  child: Row(
                    children: [
                      Icon(
                        _hasSlowConnection
                            ? Icons.network_wifi_1_bar
                            : Icons.network_wifi,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(_hasSlowConnection
                          ? 'Fast Connection'
                          : 'Slow Connection'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'global_error',
                  child: Row(
                    children: [
                      Icon(Icons.error, size: 20),
                      SizedBox(width: 8),
                      Text('Show Global Error'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                sin(_shakeAnimation.value * pi * 8) * 5,
                0,
              ),
              child: child,
            );
          },
          child: Column(
            children: [
              // Status bar
              _buildStatusBar(theme),

              // Current state display
              _buildStateDisplay(theme, ui),

              // Error demos list
              Expanded(
                child: _buildErrorDemosList(theme, ui),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.wifi,
            size: 16,
            color: _isOffline ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _isOffline ? 'Offline Mode' : 'Online',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          if (_hasSlowConnection) ...[
            const Icon(Icons.network_wifi_1_bar,
                size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('Slow Connection', style: theme.textTheme.bodySmall),
          ],
          const Spacer(),
          if (_retryCount > 0) ...[
            const Icon(Icons.refresh, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text('Retries: $_retryCount', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildStateDisplay(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current state indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStateIcon(_currentState, theme),
              const SizedBox(width: 12),
              Text(
                _currentState.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _currentState.color,
                ),
              ),
            ],
          ),

          if (_isRetrying) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Retrying...', style: theme.textTheme.bodyMedium),
              ],
            ),
          ],

          // Error details
          if (_lastError != null) ...[
            const SizedBox(height: 16),
            ui.card(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Error Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _lastError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateIcon(ErrorState state, ThemeData theme) {
    Widget icon;

    switch (state) {
      case ErrorState.idle:
        icon = const Icon(Icons.check_circle, size: 32, color: Colors.green);
        break;
      case ErrorState.loading:
        icon = const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
        break;
      case ErrorState.error:
        icon = const Icon(Icons.error, size: 32, color: Colors.red);
        break;
      case ErrorState.success:
        icon = const Icon(Icons.check_circle, size: 32, color: Colors.green);
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: icon,
    );
  }

  Widget _buildErrorDemosList(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Scenarios',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any scenario to simulate the error and see how it\'s handled',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _errorDemos.length,
              itemBuilder: (context, index) {
                final demo = _errorDemos[index];
                return _buildErrorDemoCard(demo, theme, ui);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDemoCard(
      ErrorDemo demo, ThemeData theme, AdaptiveWidgetFactory ui) {
    final isActive = _currentState == ErrorState.loading;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ui.card(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? null : () => _simulateError(demo),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: demo.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      demo.icon,
                      color: demo.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demo.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          demo.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_arrow,
                    color: isActive
                        ? theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5)
                        : theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'offline':
        setState(() {
          _isOffline = !_isOffline;
          if (_isOffline) {
            _hasSlowConnection = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isOffline ? 'Switched to offline mode' : 'Back online'),
            backgroundColor: _isOffline ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case 'slow':
        setState(() {
          _hasSlowConnection = !_hasSlowConnection;
          if (_hasSlowConnection) {
            _isOffline = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasSlowConnection
                ? 'Simulating slow connection'
                : 'Connection speed normal'),
            backgroundColor: _hasSlowConnection ? Colors.orange : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case 'global_error':
        _showGlobalErrorDialog();
        break;
    }
  }
}

// Supporting classes and enums

class ErrorDemo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ErrorType errorType;

  ErrorDemo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.errorType,
  });
}

enum ErrorType {
  network,
  server,
  authentication,
  validation,
  notFound,
  permission,
  data,
  rateLimit,
}

enum ErrorState {
  idle,
  loading,
  error,
  success;

  String get label {
    switch (this) {
      case ErrorState.idle:
        return 'Ready';
      case ErrorState.loading:
        return 'Loading...';
      case ErrorState.error:
        return 'Error Occurred';
      case ErrorState.success:
        return 'Success';
    }
  }

  Color get color {
    switch (this) {
      case ErrorState.idle:
        return Colors.blue;
      case ErrorState.loading:
        return Colors.orange;
      case ErrorState.error:
        return Colors.red;
      case ErrorState.success:
        return Colors.green;
    }
  }
}
