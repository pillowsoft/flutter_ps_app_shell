import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:signals/signals.dart';
import '../utils/logger.dart';
import 'package:logging/logging.dart';
import 'authentication_service.dart';

/// Connection status for Cloudflare service
enum CloudflareConnectionStatus {
  disconnected,
  connecting,
  connected,
  error;

  String get name => toString().split('.').last;
}

/// Service for integrating with Cloudflare Workers
///
/// Provides seamless integration between InstantDB authentication and
/// Cloudflare Workers for R2 storage, AI capabilities, and custom endpoints.
class CloudflareService {
  static CloudflareService? _instance;
  static CloudflareService get instance => _instance ??= CloudflareService._();

  CloudflareService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('CloudflareService');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Check if service is configured with worker URLs
  bool get isConfigured =>
      _authShimUrl?.isNotEmpty == true && _apiWorkerUrl?.isNotEmpty == true;

  /// Base URLs for the Cloudflare Workers
  String? _authShimUrl;
  String? _apiWorkerUrl;

  /// Authentication service for InstantDB tokens
  AuthenticationService? _authService;

  /// Cached session JWT from the auth shim
  String? _sessionJwt;
  DateTime? _sessionExpiry;

  /// Connection status signal
  final connectionStatus = signal<CloudflareConnectionStatus>(
      CloudflareConnectionStatus.disconnected);

  /// Current session information
  CloudflareSession? get currentSession {
    if (_sessionJwt != null && _sessionExpiry != null) {
      return CloudflareSession(
        token: _sessionJwt!,
        expiresAt: _sessionExpiry!,
        userId: _authService?.currentUser?.value?.id ?? 'unknown',
      );
    }
    return null;
  }

  /// Initialize the Cloudflare service
  Future<void> initialize({
    required String authShimUrl,
    required String apiWorkerUrl,
    AuthenticationService? authService,
  }) async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing Cloudflare service...');

      _authShimUrl = authShimUrl;
      _apiWorkerUrl = apiWorkerUrl;
      _authService = authService;

      connectionStatus.value = CloudflareConnectionStatus.connecting;

      // Test connection to workers
      await _testConnection();

      _isInitialized = true;
      connectionStatus.value = CloudflareConnectionStatus.connected;
      _logger.info('Cloudflare service initialized successfully');
    } catch (e, stackTrace) {
      connectionStatus.value = CloudflareConnectionStatus.error;
      _logger.severe('Failed to initialize Cloudflare service', e, stackTrace);
      rethrow;
    }
  }

  /// Test connection to Cloudflare workers
  Future<void> _testConnection() async {
    try {
      // Test auth shim health
      final authResponse = await http.get(
        Uri.parse('$_authShimUrl/health'),
        headers: {'User-Agent': 'FlutterAppShell/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (authResponse.statusCode != 200) {
        throw CloudflareException(
            'Auth shim health check failed: ${authResponse.statusCode}');
      }

      // Test API worker health
      final apiResponse = await http.get(
        Uri.parse('$_apiWorkerUrl/health'),
        headers: {'User-Agent': 'FlutterAppShell/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (apiResponse.statusCode != 200) {
        throw CloudflareException(
            'API worker health check failed: ${apiResponse.statusCode}');
      }

      _logger.fine('Cloudflare workers health check passed');
    } catch (e) {
      throw CloudflareException('Connection test failed: $e');
    }
  }

  /// Get or refresh session JWT token
  Future<String> _getSessionToken() async {
    // Check if current token is still valid
    if (_sessionJwt != null && _sessionExpiry != null) {
      final now = DateTime.now();
      final bufferMinutes = 2; // Refresh 2 minutes before expiry
      if (now.isBefore(
          _sessionExpiry!.subtract(Duration(minutes: bufferMinutes)))) {
        return _sessionJwt!;
      }
    }

    // Get InstantDB refresh token
    if (_authService == null || !_authService!.isAuthenticated.value) {
      throw CloudflareException('User not authenticated with InstantDB');
    }

    // TODO: Get refresh token from InstantDB service
    // This requires extending the AuthenticationService to expose refresh tokens
    // For now, we'll simulate this
    final refreshToken =
        'instant-refresh-token'; // This would come from AuthenticationService

    try {
      final response = await http
          .post(
            Uri.parse('$_authShimUrl/auth/session'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'FlutterAppShell/1.0',
            },
            body: jsonEncode({
              'refresh_token': refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw CloudflareException(
            'Session token exchange failed: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _sessionJwt = data['token'] as String;

      // Parse JWT to get expiry (simplified - in production, use a JWT library)
      final parts = _sessionJwt!.split('.');
      if (parts.length == 3) {
        final payload =
            jsonDecode(utf8.decode(base64Url.decode(_padBase64(parts[1]))))
                as Map<String, dynamic>;
        final exp = payload['exp'] as int?;
        if (exp != null) {
          _sessionExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        }
      }

      _logger.fine('Session token refreshed successfully');
      return _sessionJwt!;
    } catch (e) {
      throw CloudflareException('Failed to get session token: $e');
    }
  }

  /// Upload a file to R2 storage
  ///
  /// For files larger than [largeSizeThreshold], uses presigned URL for direct upload.
  /// For smaller files, proxies through the worker.
  Future<CloudflareUploadResult> uploadFile({
    required Uint8List bytes,
    required String filename,
    String? contentType,
    String? customKey,
    int largeSizeThreshold = 5 * 1024 * 1024, // 5MB
  }) async {
    _ensureInitialized();

    try {
      final ct = contentType ?? _guessContentType(filename);

      if (bytes.length > largeSizeThreshold) {
        // Use presigned URL for large files
        return await _uploadViaPresignedUrl(
          bytes: bytes,
          filename: filename,
          contentType: ct,
          customKey: customKey,
        );
      } else {
        // Use proxy upload for smaller files
        return await _uploadViaProxy(
          bytes: bytes,
          filename: filename,
          contentType: ct,
          customKey: customKey,
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('File upload failed: $filename', e, stackTrace);
      rethrow;
    }
  }

  /// Upload via worker proxy (for smaller files)
  Future<CloudflareUploadResult> _uploadViaProxy({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String? customKey,
  }) async {
    final token = await _getSessionToken();

    final uri =
        Uri.parse('$_apiWorkerUrl/v1/r2/upload').replace(queryParameters: {
      'contentType': contentType,
      if (customKey != null) 'key': customKey,
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': contentType,
            'User-Agent': 'FlutterAppShell/1.0',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw CloudflareException(
          'Proxy upload failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CloudflareUploadResult(
      key: data['key'] as String,
      url: data['url'] as String?,
      etag: data['etag'] as String?,
      size: bytes.length,
    );
  }

  /// Upload via presigned URL (for larger files)
  Future<CloudflareUploadResult> _uploadViaPresignedUrl({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String? customKey,
  }) async {
    final token = await _getSessionToken();

    // Get presigned URL
    final presignUri =
        Uri.parse('$_apiWorkerUrl/v1/r2/signed-put').replace(queryParameters: {
      'contentType': contentType,
      if (customKey != null) 'key': customKey,
    });

    final presignResponse = await http.get(
      presignUri,
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': 'FlutterAppShell/1.0',
      },
    ).timeout(const Duration(seconds: 10));

    if (presignResponse.statusCode != 200) {
      throw CloudflareException(
          'Presign request failed: ${presignResponse.statusCode} ${presignResponse.body}');
    }

    final presignData =
        jsonDecode(presignResponse.body) as Map<String, dynamic>;
    final putUrl = presignData['url'] as String;
    final key = presignData['key'] as String;

    // Upload directly to R2
    final uploadResponse = await http
        .put(
          Uri.parse(putUrl),
          headers: {
            'Content-Type': contentType,
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 120));

    if (uploadResponse.statusCode != 200) {
      throw CloudflareException(
          'Direct upload failed: ${uploadResponse.statusCode}');
    }

    return CloudflareUploadResult(
      key: key,
      url: null, // Would need to construct public URL
      etag: uploadResponse.headers['etag'],
      size: bytes.length,
    );
  }

  /// Generate text using AI Gateway (supports multiple providers)
  Future<CloudflareAIResult> generateTextAdvanced({
    required String prompt,
    String provider = 'workers-ai',
    String model = '@cf/meta/llama-3.1-8b-instruct',
    int maxTokens = 512,
    double temperature = 0.7,
    bool enableCache = true,
    List<CloudflareAIFallback>? fallbacks,
  }) async {
    _ensureInitialized();

    CloudflareException? lastError;

    // Try primary provider
    try {
      final result = await _generateTextWithProvider(
        prompt: prompt,
        provider: provider,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        enableCache: enableCache,
      );
      return result;
    } catch (e) {
      lastError = e is CloudflareException
          ? e
          : CloudflareException('Primary AI provider failed: $e');
      _logger.warning('Primary AI provider $provider failed: $e');
    }

    // Try fallbacks if available
    if (fallbacks != null) {
      for (final fallback in fallbacks) {
        try {
          final result = await _generateTextWithProvider(
            prompt: prompt,
            provider: fallback.provider,
            model: fallback.model,
            maxTokens: maxTokens,
            temperature: temperature,
            enableCache: enableCache,
          );
          _logger.info('Fallback AI provider ${fallback.provider} succeeded');
          return result.copyWith(
              usedFallback: true, fallbackProvider: fallback.provider);
        } catch (e) {
          _logger
              .warning('Fallback AI provider ${fallback.provider} failed: $e');
          continue;
        }
      }
    }

    throw lastError ?? CloudflareException('All AI providers failed');
  }

  /// Generate text using Workers AI (backward compatible method)
  Future<String> generateText({
    required String prompt,
    String model = '@cf/meta/llama-3.1-8b-instruct',
  }) async {
    final result = await generateTextAdvanced(
      prompt: prompt,
      model: model,
    );
    return result.response;
  }

  /// Generate image using AI Gateway (supports multiple providers)
  Future<CloudflareAIImageResult> generateImageAdvanced({
    required String prompt,
    String provider = 'workers-ai',
    String model = '@cf/stabilityai/stable-diffusion-xl-base-1.0',
    bool enableCache = true,
    List<CloudflareAIFallback>? fallbacks,
  }) async {
    _ensureInitialized();

    CloudflareException? lastError;

    // Try primary provider
    try {
      final result = await _generateImageWithProvider(
        prompt: prompt,
        provider: provider,
        model: model,
        enableCache: enableCache,
      );
      return result;
    } catch (e) {
      lastError = e is CloudflareException
          ? e
          : CloudflareException('Primary AI provider failed: $e');
      _logger.warning('Primary AI image provider $provider failed: $e');
    }

    // Try fallbacks if available
    if (fallbacks != null) {
      for (final fallback in fallbacks) {
        try {
          final result = await _generateImageWithProvider(
            prompt: prompt,
            provider: fallback.provider,
            model: fallback.model,
            enableCache: enableCache,
          );
          _logger.info(
              'Fallback AI image provider ${fallback.provider} succeeded');
          return result.copyWith(
              usedFallback: true, fallbackProvider: fallback.provider);
        } catch (e) {
          _logger.warning(
              'Fallback AI image provider ${fallback.provider} failed: $e');
          continue;
        }
      }
    }

    throw lastError ?? CloudflareException('All AI image providers failed');
  }

  /// Generate image using Workers AI (backward compatible method)
  Future<Uint8List> generateImage({
    required String prompt,
    String model = '@cf/stabilityai/stable-diffusion-xl-base-1.0',
  }) async {
    final result = await generateImageAdvanced(
      prompt: prompt,
      model: model,
    );
    return result.imageBytes;
  }

  /// Download a file from R2 storage
  Future<Uint8List> downloadFile(String key) async {
    _ensureInitialized();

    try {
      final token = await _getSessionToken();

      final response = await http.get(
        Uri.parse('$_apiWorkerUrl/v1/r2/object')
            .replace(queryParameters: {'key': key}),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'FlutterAppShell/1.0',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 404) {
        throw CloudflareException('File not found: $key');
      }

      if (response.statusCode != 200) {
        throw CloudflareException(
            'Download failed: ${response.statusCode} ${response.body}');
      }

      return response.bodyBytes;
    } catch (e, stackTrace) {
      _logger.severe('File download failed: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a file from R2 storage
  Future<void> deleteFile(String key) async {
    _ensureInitialized();

    try {
      final token = await _getSessionToken();

      final response = await http.delete(
        Uri.parse('$_apiWorkerUrl/v1/r2/object')
            .replace(queryParameters: {'key': key}),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'FlutterAppShell/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw CloudflareException(
            'Delete failed: ${response.statusCode} ${response.body}');
      }

      _logger.fine('File deleted successfully: $key');
    } catch (e, stackTrace) {
      _logger.severe('File deletion failed: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Make a custom API call to the Dart worker
  Future<Map<String, dynamic>> customApiCall({
    required String path,
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    _ensureInitialized();

    try {
      final token = await _getSessionToken();
      final uri = Uri.parse('$_apiWorkerUrl$path');

      final requestHeaders = {
        'Authorization': 'Bearer $token',
        'User-Agent': 'FlutterAppShell/1.0',
        if (headers != null) ...headers,
      };

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          requestHeaders['Content-Type'] = 'application/json';
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          requestHeaders['Content-Type'] = 'application/json';
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw CloudflareException('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 429) {
        throw CloudflareException('Rate limited - too many requests');
      }

      if (response.statusCode >= 400) {
        throw CloudflareException(
            'API call failed: ${response.statusCode} ${response.body}');
      }

      if (response.body.isEmpty) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      _logger.severe('Custom API call failed: $method $path', e, stackTrace);
      rethrow;
    }
  }

  /// Alias for customApiCall for backward compatibility
  Future<Map<String, dynamic>> callCustomEndpoint({
    required String endpoint,
    String method = 'GET',
    Map<String, String>? headers,
    dynamic data,
  }) async {
    return customApiCall(
      path: endpoint,
      method: method,
      headers: headers,
      body: data,
    );
  }

  /// Guess content type from filename
  String _guessContentType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  /// Pad base64 string for decoding
  String _padBase64(String str) {
    final mod = str.length % 4;
    if (mod > 0) {
      return str + ('=' * (4 - mod));
    }
    return str;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'CloudflareService not initialized. Call initialize() first.');
    }
  }

  /// Get available AI providers and models
  Future<CloudflareAIProviders> getAvailableProviders() async {
    _ensureInitialized();

    try {
      final token = await _getSessionToken();

      final response = await http.get(
        Uri.parse('$_apiWorkerUrl/v1/ai/providers'),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': 'FlutterAppShell/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw CloudflareException(
            'Failed to get providers: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return CloudflareAIProviders.fromJson(data);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get AI providers', e, stackTrace);
      rethrow;
    }
  }

  /// Helper method to generate text with a specific provider
  Future<CloudflareAIResult> _generateTextWithProvider({
    required String prompt,
    required String provider,
    required String model,
    required int maxTokens,
    required double temperature,
    required bool enableCache,
  }) async {
    final token = await _getSessionToken();

    final response = await http
        .post(
          Uri.parse('$_apiWorkerUrl/v1/ai/text-generate'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'User-Agent': 'FlutterAppShell/1.0',
          },
          body: jsonEncode({
            'prompt': prompt,
            'provider': provider,
            'model': model,
            'max_tokens': maxTokens,
            'temperature': temperature,
            'cache': enableCache,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      throw CloudflareException('Rate limited - too many AI requests');
    }

    if (response.statusCode != 200) {
      throw CloudflareException(
          'AI text generation failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CloudflareAIResult.fromJson(data);
  }

  /// Helper method to generate images with a specific provider
  Future<CloudflareAIImageResult> _generateImageWithProvider({
    required String prompt,
    required String provider,
    required String model,
    required bool enableCache,
  }) async {
    final token = await _getSessionToken();

    final response = await http
        .post(
          Uri.parse('$_apiWorkerUrl/v1/ai/image-generate'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'User-Agent': 'FlutterAppShell/1.0',
          },
          body: jsonEncode({
            'prompt': prompt,
            'provider': provider,
            'model': model,
            'cache': enableCache,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw CloudflareException('Rate limited - too many AI requests');
    }

    if (response.statusCode != 200) {
      throw CloudflareException(
          'AI image generation failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CloudflareAIImageResult.fromJson(data);
  }

  /// Dispose of the service
  void dispose() {
    _sessionJwt = null;
    _sessionExpiry = null;
    connectionStatus.value = CloudflareConnectionStatus.disconnected;
    _isInitialized = false;
  }
}

/// Upload result from Cloudflare R2
class CloudflareUploadResult {
  final String key;
  final String? url;
  final String? etag;
  final int size;

  CloudflareUploadResult({
    required this.key,
    this.url,
    this.etag,
    required this.size,
  });

  /// CDN URL for the uploaded file (same as url for now)
  String? get cdnUrl => url;

  @override
  String toString() =>
      'CloudflareUploadResult(key: $key, size: $size, url: $url)';
}

/// Cloudflare service exception
class CloudflareException implements Exception {
  final String message;
  final dynamic cause;

  CloudflareException(this.message, [this.cause]);

  @override
  String toString() =>
      'CloudflareException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// AI Gateway result for text generation
class CloudflareAIResult {
  final String response;
  final String provider;
  final Map<String, dynamic>? usage;
  final bool usedFallback;
  final String? fallbackProvider;
  final bool cached;

  CloudflareAIResult({
    required this.response,
    required this.provider,
    this.usage,
    this.usedFallback = false,
    this.fallbackProvider,
    this.cached = false,
  });

  factory CloudflareAIResult.fromJson(Map<String, dynamic> json) {
    return CloudflareAIResult(
      response: json['response'] as String? ?? '',
      provider: json['provider'] as String? ?? 'unknown',
      usage: json['usage'] as Map<String, dynamic>?,
      cached: json['cached'] as bool? ?? false,
    );
  }

  CloudflareAIResult copyWith({
    String? response,
    String? provider,
    Map<String, dynamic>? usage,
    bool? usedFallback,
    String? fallbackProvider,
    bool? cached,
  }) {
    return CloudflareAIResult(
      response: response ?? this.response,
      provider: provider ?? this.provider,
      usage: usage ?? this.usage,
      usedFallback: usedFallback ?? this.usedFallback,
      fallbackProvider: fallbackProvider ?? this.fallbackProvider,
      cached: cached ?? this.cached,
    );
  }

  @override
  String toString() =>
      'CloudflareAIResult(provider: $provider, usedFallback: $usedFallback, cached: $cached)';
}

/// AI Gateway result for image generation
class CloudflareAIImageResult {
  final Uint8List imageBytes;
  final String provider;
  final bool usedFallback;
  final String? fallbackProvider;
  final bool cached;

  CloudflareAIImageResult({
    required this.imageBytes,
    required this.provider,
    this.usedFallback = false,
    this.fallbackProvider,
    this.cached = false,
  });

  factory CloudflareAIImageResult.fromJson(Map<String, dynamic> json) {
    final base64Result = json['result'] as String? ?? '';
    return CloudflareAIImageResult(
      imageBytes: base64Decode(base64Result),
      provider: json['provider'] as String? ?? 'unknown',
      cached: json['cached'] as bool? ?? false,
    );
  }

  CloudflareAIImageResult copyWith({
    Uint8List? imageBytes,
    String? provider,
    bool? usedFallback,
    String? fallbackProvider,
    bool? cached,
  }) {
    return CloudflareAIImageResult(
      imageBytes: imageBytes ?? this.imageBytes,
      provider: provider ?? this.provider,
      usedFallback: usedFallback ?? this.usedFallback,
      fallbackProvider: fallbackProvider ?? this.fallbackProvider,
      cached: cached ?? this.cached,
    );
  }

  @override
  String toString() =>
      'CloudflareAIImageResult(provider: $provider, usedFallback: $usedFallback, cached: $cached)';
}

/// AI Gateway provider configuration
class CloudflareAIProvider {
  final String id;
  final String name;
  final List<String> textModels;
  final List<String> imageModels;
  final bool requiresKey;

  CloudflareAIProvider({
    required this.id,
    required this.name,
    required this.textModels,
    required this.imageModels,
    this.requiresKey = false,
  });

  factory CloudflareAIProvider.fromJson(Map<String, dynamic> json) {
    return CloudflareAIProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      textModels: (json['textModels'] as List?)?.cast<String>() ?? [],
      imageModels: (json['imageModels'] as List?)?.cast<String>() ?? [],
      requiresKey: json['requiresKey'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'CloudflareAIProvider($id: $name)';
}

/// Available AI providers
class CloudflareAIProviders {
  final List<CloudflareAIProvider> providers;

  CloudflareAIProviders({required this.providers});

  factory CloudflareAIProviders.fromJson(Map<String, dynamic> json) {
    final providersList = json['providers'] as List? ?? [];
    return CloudflareAIProviders(
      providers: providersList
          .map((p) => CloudflareAIProvider.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  CloudflareAIProvider? getProvider(String id) {
    return providers.where((p) => p.id == id).firstOrNull;
  }

  List<String> getTextModels(String providerId) {
    return getProvider(providerId)?.textModels ?? [];
  }

  List<String> getImageModels(String providerId) {
    return getProvider(providerId)?.imageModels ?? [];
  }

  @override
  String toString() => 'CloudflareAIProviders(${providers.length} providers)';
}

/// AI Gateway fallback configuration
class CloudflareAIFallback {
  final String provider;
  final String model;

  CloudflareAIFallback({
    required this.provider,
    required this.model,
  });

  @override
  String toString() => 'CloudflareAIFallback($provider: $model)';
}

/// Session information for Cloudflare service
class CloudflareSession {
  final String token;
  final DateTime expiresAt;
  final String userId;

  CloudflareSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
  });

  @override
  String toString() =>
      'CloudflareSession(userId: $userId, expiresAt: $expiresAt)';
}
