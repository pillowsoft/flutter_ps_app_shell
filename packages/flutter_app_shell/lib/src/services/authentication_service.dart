import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:instantdb_flutter/instantdb_flutter.dart';
import 'package:logging/logging.dart';
import 'preferences_service.dart';
import '../utils/logger.dart';
import 'database_service.dart';

/// Authentication service with token management and biometric support
/// Provides local authentication with JWT-style tokens
class AuthenticationService {
  static AuthenticationService? _instance;
  static AuthenticationService get instance =>
      _instance ??= AuthenticationService._();

  AuthenticationService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('AuthenticationService');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late PreferencesService _prefs;
  late LocalAuthentication _localAuth;

  /// Signal for authentication status
  final isAuthenticated = signal<bool>(false);

  /// Signal for current user
  final currentUser = signal<AuthUser?>(null);

  /// Signal for authentication loading state
  final isLoading = signal<bool>(false);

  /// Signal for biometric availability
  final biometricAvailable = signal<bool>(false);

  // Preference keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyTokenExpiry = 'auth_token_expiry';
  static const String _keyBiometricEnabled = 'auth_biometric_enabled';

  /// Initialize the authentication service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('Initializing authentication service...');

      _prefs = PreferencesService.instance;
      _localAuth = LocalAuthentication();

      // Check biometric availability
      await _checkBiometricAvailability();

      // Restore authentication state
      await _restoreAuthState();

      _isInitialized = true;
      _logger.info('Authentication service initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to initialize authentication service', e, stackTrace);
      rethrow;
    }
  }

  // Authentication methods

  /// Sign in with email and password
  Future<AuthResult> signIn(String email, String password,
      {bool rememberMe = false}) async {
    _ensureInitialized();

    try {
      isLoading.value = true;
      _logger.fine('Attempting sign in for: $email');

      // Validate inputs
      final validationError = _validateCredentials(email, password);
      if (validationError != null) {
        return AuthResult.failure(validationError);
      }

      // Use local authentication (demo mode)
      return await _signInLocally(email, password);
    } catch (e, stackTrace) {
      _logger.severe('Sign in failed', e, stackTrace);
      return AuthResult.failure('Sign in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUp(String email, String password, String name) async {
    _ensureInitialized();

    try {
      isLoading.value = true;
      _logger.fine('Attempting sign up for: $email');

      // Validate inputs
      final validationError = _validateCredentials(email, password);
      if (validationError != null) {
        return AuthResult.failure(validationError);
      }

      if (name.trim().isEmpty) {
        return AuthResult.failure('Name is required');
      }

      // Use local authentication (demo mode)
      return await _signUpLocally(email, password, name);
    } catch (e, stackTrace) {
      _logger.severe('Sign up failed', e, stackTrace);
      return AuthResult.failure('Sign up failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _ensureInitialized();

    try {
      isLoading.value = true;
      _logger.fine('Signing out user: ${currentUser.value?.email}');

      // Clear stored auth data
      await _clearAuthData();

      currentUser.value = null;
      isAuthenticated.value = false;

      _logger.info('Sign out successful');
    } catch (e, stackTrace) {
      _logger.severe('Sign out failed', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    _ensureInitialized();

    try {
      final refreshToken = _prefs.getString(_keyRefreshToken).value;
      if (refreshToken == null) {
        await signOut();
        return false;
      }

      _logger.fine('Refreshing authentication token');

      // Simulate API call to refresh token
      await Future.delayed(const Duration(milliseconds: 500));

      final newToken = _generateToken();
      final newRefreshToken = _generateRefreshToken();
      final newExpiry = DateTime.now().add(const Duration(hours: 24));

      await _prefs.setString(_keyAuthToken, newToken);
      await _prefs.setString(_keyRefreshToken, newRefreshToken);
      await _prefs.setString(_keyTokenExpiry, newExpiry.toIso8601String());

      _logger.fine('Token refreshed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Token refresh failed', e, stackTrace);
      await signOut();
      return false;
    }
  }

  /// Check if current token is valid
  bool isTokenValid() {
    if (!isAuthenticated.value) return false;

    final expiryString = _prefs.getString(_keyTokenExpiry).value;
    if (expiryString == null) return false;

    final expiry = DateTime.tryParse(expiryString);
    if (expiry == null) return false;

    return DateTime.now().isBefore(expiry);
  }

  /// Get current authentication token
  String? getAuthToken() {
    if (!isAuthenticated.value || !isTokenValid()) return null;
    return _prefs.getString(_keyAuthToken).value;
  }

  // Biometric authentication

  /// Check if biometric authentication is available
  Future<bool> checkBiometricAvailability() async {
    _ensureInitialized();
    await _checkBiometricAvailability();
    return biometricAvailable.value;
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    _ensureInitialized();

    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get available biometrics', e, stackTrace);
      return [];
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometricAuth() async {
    _ensureInitialized();

    if (!biometricAvailable.value) {
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for quick sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _prefs.setBool(_keyBiometricEnabled, true);
        _logger.info('Biometric authentication enabled');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to enable biometric authentication', e, stackTrace);
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    _ensureInitialized();

    await _prefs.setBool(_keyBiometricEnabled, false);
    _logger.info('Biometric authentication disabled');
  }

  /// Check if biometric authentication is enabled
  bool isBiometricEnabled() {
    return _prefs.getBool(_keyBiometricEnabled).value;
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    _ensureInitialized();

    if (!biometricAvailable.value || !isBiometricEnabled()) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use biometric authentication to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Biometric authentication failed', e, stackTrace);
      return false;
    }
  }

  // InstantDB Magic Link Authentication

  /// Send a magic link code to email using InstantDB
  Future<AuthResult> sendMagicLink(String email) async {
    _ensureInitialized();

    try {
      isLoading.value = true;
      _logger.fine('Sending magic link to: $email');

      // Get the database service to access InstantDB
      final dbService = DatabaseService.instance;
      if (!dbService.isInitialized) {
        return AuthResult.failure(
            'Database service not initialized. Magic link authentication requires InstantDB configuration.');
      }

      // Check if we have an app ID configured (needed for auth)
      if (dbService.appId == null || dbService.appId!.isEmpty) {
        return AuthResult.failure(
            'Magic link authentication requires an InstantDB app ID. Please configure INSTANTDB_APP_ID in your .env file.');
      }

      // Use InstantDB's built-in magic code authentication
      await dbService.db.auth.sendMagicCode(email);

      _logger.info('Magic link code sent to: $email');
      return AuthResult.success(null); // No user object until code is verified
    } catch (e, stackTrace) {
      _logger.severe('Failed to send magic link', e, stackTrace);

      // Handle specific InstantDB errors
      if (e is InstantException) {
        if (e.code == 'endpoint_not_found') {
          return AuthResult.failure(
              'Magic link authentication is not available with your current InstantDB configuration.');
        } else if (e.code == 'invalid_email') {
          return AuthResult.failure('Please enter a valid email address.');
        }
        return AuthResult.failure(e.message);
      }

      return AuthResult.failure('Failed to send magic link: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify magic link code and sign in using InstantDB
  Future<AuthResult> verifyMagicCode(String email, String code) async {
    _ensureInitialized();

    try {
      isLoading.value = true;
      _logger.fine('Verifying magic code for: $email');

      // Get the database service to access InstantDB
      final dbService = DatabaseService.instance;
      if (!dbService.isInitialized) {
        return AuthResult.failure('Database service not initialized.');
      }

      // Use InstantDB's built-in magic code verification
      final instantUser = await dbService.db.auth.verifyMagicCode(
        email: email,
        code: code,
      );

      // Convert InstantDB user to our AuthUser format
      final user = AuthUser(
        id: instantUser.id,
        email: instantUser.email,
        name: _extractNameFromEmail(instantUser.email),
        avatarUrl: null, // InstantDB user might not have avatar in basic setup
      );

      // Store the auth state (InstantDB manages tokens internally)
      currentUser.value = user;
      isAuthenticated.value = true;

      // Store user data for persistence
      await _storeUserData(user);

      _logger.info('Magic link authentication successful for: $email');
      return AuthResult.success(user);
    } catch (e, stackTrace) {
      _logger.severe('Magic code verification failed', e, stackTrace);

      // Handle specific InstantDB errors
      if (e is InstantException) {
        if (e.code == 'invalid_code') {
          return AuthResult.failure(
              'Invalid verification code. Please try again.');
        } else if (e.code == 'invalid_email') {
          return AuthResult.failure('Please enter a valid email address.');
        }
        return AuthResult.failure(e.message);
      }

      return AuthResult.failure('Verification failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Utility methods

  /// Get authentication statistics
  AuthStats getStats() {
    return AuthStats(
      isAuthenticated: isAuthenticated.value,
      hasUser: currentUser.value != null,
      tokenValid: isTokenValid(),
      biometricAvailable: biometricAvailable.value,
      biometricEnabled: isBiometricEnabled(),
    );
  }

  // Private methods

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      biometricAvailable.value = isAvailable && canCheckBiometrics;
      _logger.fine('Biometric availability: ${biometricAvailable.value}');
    } catch (e) {
      biometricAvailable.value = false;
      _logger.warning('Failed to check biometric availability: $e');
    }
  }

  // Local authentication methods

  Future<AuthResult> _signInLocally(String email, String password) async {
    // Original local sign in logic
    await Future.delayed(const Duration(seconds: 1));

    if (email.contains('@') && password.length >= 6) {
      final user = AuthUser(
        id: _generateUserId(email),
        email: email,
        name: _extractNameFromEmail(email),
        avatarUrl: null,
      );

      final token = _generateToken();
      final refreshToken = _generateRefreshToken();
      final expiry = DateTime.now().add(const Duration(hours: 24));

      await _storeAuthData(user, token, refreshToken, expiry);

      currentUser.value = user;
      isAuthenticated.value = true;

      _logger.info('Local sign in successful for: $email');
      return AuthResult.success(user);
    } else {
      return AuthResult.failure('Invalid email or password');
    }
  }

  Future<AuthResult> _signUpLocally(
      String email, String password, String name) async {
    // Original local sign up logic
    await Future.delayed(const Duration(seconds: 1));

    final user = AuthUser(
      id: _generateUserId(email),
      email: email,
      name: name.trim(),
      avatarUrl: null,
    );

    final token = _generateToken();
    final refreshToken = _generateRefreshToken();
    final expiry = DateTime.now().add(const Duration(hours: 24));

    await _storeAuthData(user, token, refreshToken, expiry);

    currentUser.value = user;
    isAuthenticated.value = true;

    _logger.info('Local sign up successful for: $email');
    return AuthResult.success(user);
  }

  Future<void> _restoreAuthState() async {
    // Restore local auth state
    final token = _prefs.getString(_keyAuthToken).value;
    final userDataString = _prefs.getString(_keyUserData).value;

    if (token != null && userDataString != null && isTokenValid()) {
      try {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        final user = AuthUser.fromJson(userData);

        currentUser.value = user;
        isAuthenticated.value = true;

        _logger.info('Restored local authentication state for: ${user.email}');
      } catch (e, stackTrace) {
        _logger.severe('Failed to restore auth state', e, stackTrace);
        await _clearAuthData();
      }
    }
  }

  Future<void> _storeAuthData(
      AuthUser user, String token, String refreshToken, DateTime expiry) async {
    await _prefs.setString(_keyAuthToken, token);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    await _prefs.setString(_keyTokenExpiry, expiry.toIso8601String());
  }

  Future<void> _storeUserData(AuthUser user) async {
    await _prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  Future<void> _clearAuthData() async {
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserData);
    await _prefs.remove(_keyTokenExpiry);
  }

  String? _validateCredentials(String email, String password) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateUserId(String email) {
    final bytes = utf8.encode(email + DateTime.now().toString());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  String _extractNameFromEmail(String email) {
    final name = email.split('@').first;
    return name
        .split('.')
        .map((part) =>
            part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final bytes = utf8.encode('token_$timestamp$random');
    final digest = sha256.convert(bytes);
    return 'at_${digest.toString().substring(0, 32)}';
  }

  String _generateRefreshToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond * 2;
    final bytes = utf8.encode('refresh_$timestamp$random');
    final digest = sha256.convert(bytes);
    return 'rt_${digest.toString().substring(0, 32)}';
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'AuthenticationService not initialized. Call initialize() first.');
    }
  }
}

/// Authentication user model
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, name: $name)';
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final AuthUser? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;
  AuthResult.failure(this.error)
      : success = false,
        user = null;

  @override
  String toString() {
    return success
        ? 'AuthResult.success(user: $user)'
        : 'AuthResult.failure(error: $error)';
  }
}

/// Authentication statistics
class AuthStats {
  final bool isAuthenticated;
  final bool hasUser;
  final bool tokenValid;
  final bool biometricAvailable;
  final bool biometricEnabled;

  AuthStats({
    required this.isAuthenticated,
    required this.hasUser,
    required this.tokenValid,
    required this.biometricAvailable,
    required this.biometricEnabled,
  });

  @override
  String toString() {
    return 'AuthStats(auth: $isAuthenticated, user: $hasUser, token: $tokenValid, biometric: $biometricAvailable/$biometricEnabled)';
  }
}
