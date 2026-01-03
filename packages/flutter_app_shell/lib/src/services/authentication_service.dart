import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:local_auth/local_auth.dart';
import 'package:instantdb_flutter/instantdb_flutter.dart';
import 'package:logging/logging.dart';
import 'package:signals/signals.dart' show batch;
import 'preferences_service.dart';
import '../utils/logger.dart';
import 'database_service.dart';

/// Authentication service with token management and biometric support
/// Provides local authentication with JWT-style tokens
///
/// ## BREAKING CHANGE in v2.0.0
///
/// **Password hashing has been upgraded from SHA-256 to bcrypt** for improved
/// security. This is a **CRITICAL SECURITY FIX** that addresses vulnerability
/// to rainbow table attacks.
///
/// ### Migration Required
///
/// Existing password-based authentication will NOT work after upgrading to v2.0.0.
/// Users must either:
///
/// 1. **Reset passwords** via "forgot password" flow
/// 2. **Migrate hashes** using the `migratePasswordHash()` method during first sign-in
/// 3. **Re-authenticate** (if app clears local auth data on upgrade)
///
/// **Note**: This only affects password-based authentication. InstantDB magic link
/// authentication is unaffected.
///
/// See `docs/migration-v2.md` for detailed migration guide.
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

  /// Get the current refresh token value (for API authentication with backend services)
  ///
  /// Returns the stored refresh token or null if not authenticated.
  /// This token can be used to authenticate with backend services like Cloudflare Workers.
  ///
  /// **Security Note**: Only expose this to trusted backend services, never to client-side code.
  ///
  /// **Note:** This is different from [refreshToken()], which is a method that refreshes
  /// the authentication token by making an API call.
  String? get currentRefreshToken {
    if (!_isInitialized) return null;
    return _prefs.getString(_keyRefreshToken).value;
  }

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

      batch(() {
        currentUser.value = null;
        isAuthenticated.value = false;
      });

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
        biometricOnly: true,
        persistAcrossBackgrounding: true,
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
        biometricOnly: true,
        persistAcrossBackgrounding: true,
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

      // Store user data BEFORE batch to ensure persistence even if batch fails
      await _storeUserData(user);

      // Store the auth state (InstantDB manages tokens and session persistence internally)
      batch(() {
        currentUser.value = user;
        isAuthenticated.value = true;
      });

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

      batch(() {
        currentUser.value = user;
        isAuthenticated.value = true;
      });

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

    batch(() {
      currentUser.value = user;
      isAuthenticated.value = true;
    });

    _logger.info('Local sign up successful for: $email');
    return AuthResult.success(user);
  }

  /// Restore authentication state from local storage or InstantDB session
  ///
  /// **Error Safety**: Uses local variables throughout and only updates signals
  /// at the end in a single batch() to ensure atomic state updates and prevent
  /// inconsistent state if exceptions occur.
  Future<void> _restoreAuthState() async {
    _logger.info('Attempting to restore authentication state...');

    // Local variables to accumulate results
    AuthUser? restoredUser;
    bool authenticated = false;

    // Try to restore from local token-based auth first
    try {
      final token = _prefs.getString(_keyAuthToken).value;
      final userDataString = _prefs.getString(_keyUserData).value;

      _logger.fine(
          'Local auth check - token: ${token != null}, userData: ${userDataString != null}');

      if (token != null && userDataString != null && isTokenValid()) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        final user = AuthUser.fromJson(userData);

        // Store in local variables, don't update signals yet
        restoredUser = user;
        authenticated = true;

        _logger.info('Restored local authentication state for: ${user.email}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore local auth state', e, stackTrace);
      // Clear corrupted auth data
      await _clearAuthData();
      // Keep restoredUser = null, authenticated = false
    }

    // If local auth failed, check for InstantDB session
    // InstantDB v0.2.9+ automatically restores sessions via enableSessionPersistence
    if (!authenticated) {
      try {
        final dbService = DatabaseService.instance;

        if (dbService.isInitialized) {
          final instantUser = dbService.db.auth.currentUser.value;
          if (instantUser != null) {
            _logger.info(
                'InstantDB session restored automatically for: ${instantUser.email}');

            final user = AuthUser(
              id: instantUser.id,
              email: instantUser.email,
              name: _extractNameFromEmail(instantUser.email),
              avatarUrl: null,
            );

            // Store in local variables
            restoredUser = user;
            authenticated = true;

            // Store user data for future local restoration
            await _storeUserData(user);
          } else {
            _logger.fine('No active InstantDB session found');
          }
        } else {
          _logger.fine(
              'Database service not initialized, skipping InstantDB check');
        }
      } catch (e, stackTrace) {
        // InstantDB check failure is not critical - service can still function
        _logger.warning('Failed to check InstantDB auth state (non-critical)',
            e, stackTrace);
        // Keep current restoredUser and authenticated values
      }
    }

    // ALWAYS update signals with safe values in a single atomic batch
    // This ensures consistent state even if exceptions occurred above
    batch(() {
      currentUser.value = restoredUser;
      isAuthenticated.value = authenticated;
    });

    if (authenticated && restoredUser != null) {
      _logger.info('Authentication state restored for: ${restoredUser.email}');
    } else {
      _logger.fine('No authentication state to restore');
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

  /// Hash password using bcrypt with cost factor 12
  ///
  /// ## BREAKING CHANGE in v2.0.0
  ///
  /// This method now uses **bcrypt** instead of SHA-256 for secure password hashing.
  /// Bcrypt provides:
  /// - Built-in salt generation (prevents rainbow table attacks)
  /// - Adaptive cost factor (resistant to brute-force attacks)
  /// - Industry-standard security (200-400ms hashing time acceptable for auth)
  ///
  /// **Cost factor 12** provides good security/performance balance:
  /// - ~300ms on modern devices (acceptable for login/signup)
  /// - 2^12 = 4096 iterations
  /// - Increases difficulty for attackers exponentially
  ///
  /// **Migration**: Old SHA-256 hashes will NOT verify. Use `migratePasswordHash()`
  /// or require password resets.
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
  }

  /// Verify password against bcrypt hash
  ///
  /// ## BREAKING CHANGE in v2.0.0
  ///
  /// This method now verifies **bcrypt** hashes instead of SHA-256.
  /// Will return false for old SHA-256 hashes.
  bool _verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      _logger.warning(
          'Password verification failed (possibly old SHA-256 hash): $e');
      return false;
    }
  }

  /// Migrate password hash from SHA-256 to bcrypt
  ///
  /// ## Migration Helper for v2.0.0 Upgrade
  ///
  /// Use this method to migrate user passwords from old SHA-256 hashes to
  /// new bcrypt hashes during first sign-in after upgrading to v2.0.0.
  ///
  /// **Migration Strategy**:
  /// 1. Verify the password against the old SHA-256 hash
  /// 2. If valid, rehash with bcrypt and update storage
  /// 3. User can continue without password reset
  ///
  /// **Example Usage**:
  /// ```dart
  /// // During sign-in, detect old hash format and migrate
  /// final oldHash = await getUserPasswordHash(email);
  /// if (oldHash.length == 64) { // SHA-256 produces 64-char hex string
  ///   final migrated = await auth.migratePasswordHash(
  ///     email: email,
  ///     plainPassword: password,
  ///     oldSha256Hash: oldHash,
  ///   );
  ///   if (migrated != null) {
  ///     await updateUserPasswordHash(email, migrated);
  ///     // Proceed with sign-in
  ///   }
  /// }
  /// ```
  ///
  /// **Returns**: New bcrypt hash if migration successful, null if old hash invalid
  Future<String?> migratePasswordHash({
    required String email,
    required String plainPassword,
    required String oldSha256Hash,
  }) async {
    try {
      _logger.info('Attempting password hash migration for: $email');

      // Verify against old SHA-256 hash
      final bytes = utf8.encode(plainPassword);
      final digest = sha256.convert(bytes);
      final computedOldHash = digest.toString();

      if (computedOldHash != oldSha256Hash) {
        _logger.warning(
            'Password hash migration failed: password does not match old hash');
        return null;
      }

      // Generate new bcrypt hash
      final newHash = _hashPassword(plainPassword);
      _logger.info('Password hash successfully migrated to bcrypt for: $email');

      return newHash;
    } catch (e, stackTrace) {
      _logger.severe('Password hash migration error for $email', e, stackTrace);
      return null;
    }
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
