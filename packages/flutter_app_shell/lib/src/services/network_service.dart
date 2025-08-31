import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:signals/signals.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';

/// Network service with offline handling and request queue
class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();

  NetworkService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('NetworkService');

  late Dio _dio;
  Dio get dio => _dio;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Signal for network connectivity status
  final connectionStatus =
      signal<NetworkConnectionStatus>(NetworkConnectionStatus.unknown);

  /// Signal for offline request queue size
  final queueSize = signal<int>(0);

  /// Queue for offline requests
  final List<QueuedRequest> _requestQueue = [];

  /// Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize the network service
  Future<void> initialize({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, String>? defaultHeaders,
    List<Interceptor>? interceptors,
  }) async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing network service...');

      // Initialize Dio
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        },
      ));

      // Add default interceptors
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.fine('Network: $obj'),
      ));

      // Add retry interceptor
      _dio.interceptors.add(_RetryInterceptor(this));

      // Add custom interceptors
      if (interceptors != null) {
        _dio.interceptors.addAll(interceptors);
      }

      // Initialize connectivity monitoring
      await _initializeConnectivity();

      _isInitialized = true;
      _logger.info('Network service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize network service', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose of the network service
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    connectionStatus.value = NetworkConnectionStatus.unknown;
    _isInitialized = false;
  }

  // HTTP Methods with offline support

  /// GET request with offline queueing
  Future<NetworkResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    return _makeRequest<T>(
      () => dio.get(path, queryParameters: queryParameters, options: options),
      RequestType.get,
      path,
      queryParameters: queryParameters,
      options: options,
      queueIfOffline: queueIfOffline,
    );
  }

  /// POST request with offline queueing
  Future<NetworkResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    return _makeRequest<T>(
      () => dio.post(path,
          data: data, queryParameters: queryParameters, options: options),
      RequestType.post,
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      queueIfOffline: queueIfOffline,
    );
  }

  /// PUT request with offline queueing
  Future<NetworkResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    return _makeRequest<T>(
      () => dio.put(path,
          data: data, queryParameters: queryParameters, options: options),
      RequestType.put,
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      queueIfOffline: queueIfOffline,
    );
  }

  /// DELETE request with offline queueing
  Future<NetworkResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    return _makeRequest<T>(
      () => dio.delete(path,
          data: data, queryParameters: queryParameters, options: options),
      RequestType.delete,
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      queueIfOffline: queueIfOffline,
    );
  }

  /// PATCH request with offline queueing
  Future<NetworkResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    return _makeRequest<T>(
      () => dio.patch(path,
          data: data, queryParameters: queryParameters, options: options),
      RequestType.patch,
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      queueIfOffline: queueIfOffline,
    );
  }

  // Utility methods

  /// Check if network is available
  bool get isOnline =>
      connectionStatus.value == NetworkConnectionStatus.connected;

  /// Clear offline request queue
  void clearQueue() {
    _requestQueue.clear();
    queueSize.value = 0;
    _logger.fine('Cleared offline request queue');
  }

  /// Get network statistics
  NetworkStats getStats() {
    return NetworkStats(
      isOnline: isOnline,
      connectionStatus: connectionStatus.value,
      queuedRequests: _requestQueue.length,
    );
  }

  // Private methods

  Future<void> _initializeConnectivity() async {
    final connectivity = Connectivity();

    // Check initial connectivity
    final result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to connectivity changes
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    final newStatus = hasConnection
        ? NetworkConnectionStatus.connected
        : NetworkConnectionStatus.disconnected;

    if (connectionStatus.value != newStatus) {
      connectionStatus.value = newStatus;
      _logger.info('Network status changed: $newStatus');

      // Process queued requests when back online
      if (newStatus == NetworkConnectionStatus.connected &&
          _requestQueue.isNotEmpty) {
        _processQueuedRequests();
      }
    }
  }

  Future<NetworkResponse<T>> _makeRequest<T>(
    Future<Response> Function() request,
    RequestType type,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    _ensureInitialized();

    try {
      if (!isOnline) {
        if (queueIfOffline &&
            (type == RequestType.post ||
                type == RequestType.put ||
                type == RequestType.patch ||
                type == RequestType.delete)) {
          // Queue modifying requests when offline
          final queuedRequest = QueuedRequest(
            type: type,
            path: path,
            data: data,
            queryParameters: queryParameters,
            options: options,
            timestamp: DateTime.now(),
          );

          _requestQueue.add(queuedRequest);
          queueSize.value = _requestQueue.length;
          _logger.fine('Queued offline request: ${type.name} $path');

          return NetworkResponse<T>(
            success: false,
            isOffline: true,
            error: NetworkError(
              type: NetworkErrorType.noConnection,
              message: 'Request queued for when connection is restored',
            ),
          );
        } else {
          return NetworkResponse<T>(
            success: false,
            isOffline: true,
            error: NetworkError(
              type: NetworkErrorType.noConnection,
              message: 'No internet connection available',
            ),
          );
        }
      }

      final response = await request();

      return NetworkResponse<T>(
        success: true,
        data: response.data,
        statusCode: response.statusCode,
        headers: response.headers.map,
      );
    } on DioException catch (e) {
      return NetworkResponse<T>(
        success: false,
        error: NetworkError(
          type: _getErrorType(e),
          message: e.message ?? 'Unknown network error',
          statusCode: e.response?.statusCode,
          response: e.response?.data,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Network request failed: $path', e, stackTrace);
      return NetworkResponse<T>(
        success: false,
        error: NetworkError(
          type: NetworkErrorType.unknown,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _processQueuedRequests() async {
    if (_requestQueue.isEmpty) return;

    _logger.info('Processing ${_requestQueue.length} queued requests');

    final requestsCopy = List<QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();
    queueSize.value = 0;

    for (final request in requestsCopy) {
      try {
        switch (request.type) {
          case RequestType.post:
            await post(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: request.options,
              queueIfOffline: false,
            );
            break;
          case RequestType.put:
            await put(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: request.options,
              queueIfOffline: false,
            );
            break;
          case RequestType.patch:
            await patch(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: request.options,
              queueIfOffline: false,
            );
            break;
          case RequestType.delete:
            await delete(
              request.path,
              data: request.data,
              queryParameters: request.queryParameters,
              options: request.options,
              queueIfOffline: false,
            );
            break;
          default:
            break;
        }

        _logger.fine(
            'Successfully processed queued request: ${request.type.name} ${request.path}');
      } catch (e) {
        _logger.warning(
            'Failed to process queued request: ${request.type.name} ${request.path} - $e');
        // Re-queue failed requests
        _requestQueue.add(request);
        queueSize.value = _requestQueue.length;
      }
    }
  }

  NetworkErrorType _getErrorType(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkErrorType.timeout;
      case DioExceptionType.badResponse:
        return NetworkErrorType.serverError;
      case DioExceptionType.connectionError:
        return NetworkErrorType.noConnection;
      case DioExceptionType.badCertificate:
        return NetworkErrorType.sslError;
      case DioExceptionType.cancel:
        return NetworkErrorType.cancelled;
      default:
        return NetworkErrorType.unknown;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'NetworkService not initialized. Call initialize() first.');
    }
  }
}

/// Retry interceptor for failed requests
class _RetryInterceptor extends Interceptor {
  // Service-specific logger
  static final Logger _logger = createServiceLogger('_RetryInterceptor');

  final NetworkService _networkService;
  final int maxRetries;
  final Duration retryDelay;

  _RetryInterceptor(
    this._networkService, {
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retry_count'] ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      _logger.fine(
          'Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}');

      await Future.delayed(retryDelay * (retryCount + 1));

      final options = err.requestOptions;
      options.extra['retry_count'] = retryCount + 1;

      try {
        final response = await _networkService.dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error if retry fails
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      default:
        return false;
    }
  }
}

/// Network response wrapper
class NetworkResponse<T> {
  final bool success;
  final T? data;
  final int? statusCode;
  final Map<String, List<String>>? headers;
  final NetworkError? error;
  final bool isOffline;

  NetworkResponse({
    required this.success,
    this.data,
    this.statusCode,
    this.headers,
    this.error,
    this.isOffline = false,
  });

  bool get isSuccessful =>
      success && statusCode != null && statusCode! >= 200 && statusCode! < 300;
}

/// Network error details
class NetworkError {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic response;

  NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.response,
  });

  @override
  String toString() {
    return 'NetworkError(type: $type, message: $message, statusCode: $statusCode)';
  }
}

/// Network error types
enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  sslError,
  cancelled,
  unknown,
}

/// Network connection status
enum NetworkConnectionStatus {
  unknown,
  connected,
  disconnected,
}

/// Request types
enum RequestType {
  get,
  post,
  put,
  delete,
  patch,
}

/// Queued request for offline handling
class QueuedRequest {
  final RequestType type;
  final String path;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final Options? options;
  final DateTime timestamp;

  QueuedRequest({
    required this.type,
    required this.path,
    this.data,
    this.queryParameters,
    this.options,
    required this.timestamp,
  });
}

/// Network statistics
class NetworkStats {
  final bool isOnline;
  final NetworkConnectionStatus connectionStatus;
  final int queuedRequests;

  NetworkStats({
    required this.isOnline,
    required this.connectionStatus,
    required this.queuedRequests,
  });

  @override
  String toString() {
    return 'NetworkStats(online: $isOnline, status: $connectionStatus, queued: $queuedRequests)';
  }
}
