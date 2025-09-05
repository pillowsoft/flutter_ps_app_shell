import 'dart:async';
import 'dart:convert';
import 'package:instantdb_flutter/instantdb_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';

/// Real-time database service using InstantDB with built-in cloud sync
/// Supports both local-only mode (no app ID) and cloud-sync mode (with app ID)
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('DatabaseService');

  InstantDB? _db;
  InstantDB get db => _db!;

  String? _appId;

  bool get isInitialized => _db != null;
  bool get isAuthenticated => _db?.auth.currentUser.value != null;
  String? get appId => _appId;

  /// Signal for database connection status
  final connectionStatus =
      signal<DatabaseConnectionStatus>(DatabaseConnectionStatus.disconnected);

  /// Signal for authentication status
  final authenticationStatus =
      signal<AuthenticationStatus>(AuthenticationStatus.unauthenticated);

  /// Signal for real-time sync status
  final syncStatus = signal<SyncStatus>(SyncStatus.disconnected);

  /// Signal for last sync timestamp
  final lastSyncTime = signal<DateTime?>(null);

  /// Signal for real-time updates received
  final realtimeUpdates = signal<int>(0);

  /// Initialize the database service
  /// [appId] can be empty for local-only mode, or provide InstantDB app ID for cloud sync
  /// [enableSync] controls whether real-time sync is enabled (ignored in local-only mode)
  Future<void> initialize({
    String appId = '',
    bool enableSync = true,
    bool verboseLogging = false,
  }) async {
    if (_db != null) return;

    try {
      connectionStatus.value = DatabaseConnectionStatus.connecting;
      _logger.info('Initializing database service...');

      // Use local-only mode if no app ID provided
      final effectiveAppId = appId.isEmpty
          ? 'local-only-${DateTime.now().millisecondsSinceEpoch}'
          : appId;
      final isLocalOnly = appId.isEmpty;

      _appId = effectiveAppId;

      // Initialize InstantDB with configuration
      _db = await InstantDB.init(
        appId: effectiveAppId,
        config: InstantConfig(
          syncEnabled:
              enableSync && !isLocalOnly, // Disable sync for local-only mode
          verboseLogging: verboseLogging,
        ),
      );

      // Authentication is available via _db.auth

      // Set up status monitoring
      _setupStatusMonitoring();

      connectionStatus.value = DatabaseConnectionStatus.connected;
      if (enableSync && !isLocalOnly) {
        syncStatus.value = SyncStatus.connected;
      }

      final mode = isLocalOnly ? 'local-only' : 'cloud-sync';
      _logger.info('Database service initialized successfully ($mode mode)');
    } catch (e, stackTrace) {
      connectionStatus.value = DatabaseConnectionStatus.error;
      _logger.severe('Failed to initialize database service', e, stackTrace);
      rethrow;
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_db != null) {
      try {
        // InstantDB handles cleanup automatically
        _db = null;
        _appId = null;

        connectionStatus.value = DatabaseConnectionStatus.disconnected;
        authenticationStatus.value = AuthenticationStatus.unauthenticated;
        syncStatus.value = SyncStatus.disconnected;

        _logger.info('Database service closed');
      } catch (e) {
        _logger.warning('Error closing database service: $e');
      }
    }
  }

  /// Set up status monitoring for connection and auth state
  void _setupStatusMonitoring() {
    // Monitor authentication status
    effect(() {
      final user = _db?.auth.currentUser.value;
      if (user != null) {
        authenticationStatus.value = AuthenticationStatus.authenticated;
        _logger.fine('User authenticated: ${user.email}');
      } else {
        authenticationStatus.value = AuthenticationStatus.unauthenticated;
      }
    });

    // Update sync time periodically
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isInitialized) {
        timer.cancel();
        return;
      }
      lastSyncTime.value = DateTime.now();
    });
  }

  // CRUD Operations

  /// Create a new document
  /// [collection] is the document type/collection name
  /// [data] is the document data
  /// Returns the generated document ID
  Future<String> create(String collection, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      final id = _db!.id();

      // Add metadata to the document
      final documentData = {
        ...data,
        '_type': collection,
        '_createdAt': DateTime.now().toIso8601String(),
        '_updatedAt': DateTime.now().toIso8601String(),
        '_version': 1,
      };

      // Create the document using InstantDB transaction
      await _db!.transact(_db!.tx[collection][id].update(documentData));

      _logger.fine('Created document: collection=$collection, id=$id');
      return id;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to create document: collection=$collection', e, stackTrace);
      rethrow;
    }
  }

  /// Read a document by ID
  /// [collection] is the document type/collection name
  /// [id] is the document ID
  Future<Map<String, dynamic>?> read(String collection, String id) async {
    _ensureInitialized();

    try {
      // Query for the specific document
      final query = {
        collection: {
          '\$': {
            'where': {'id': id}
          }
        }
      };

      final querySignal = _db!.subscribeQuery(query);
      final result = querySignal.value;

      // Check if query has data and the collection exists
      if (result.hasData && result.data![collection] != null) {
        final collectionData = result.data![collection] as List?;
        if (collectionData != null && collectionData.isNotEmpty) {
          final document = Map<String, dynamic>.from(collectionData.first);
          // Add document ID to the returned data
          document['_id'] = id;
          return document;
        }
      }

      return null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to read document: collection=$collection, id=$id',
          e, stackTrace);
      rethrow;
    }
  }

  /// Update a document by ID
  /// [collection] is the document type/collection name
  /// [id] is the document ID
  /// [data] is the updated document data
  Future<bool> update(
      String collection, String id, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      // First, check if document exists
      final existing = await read(collection, id);
      if (existing == null) {
        return false;
      }

      // Prepare updated data with metadata
      final updatedData = {
        ...data,
        '_updatedAt': DateTime.now().toIso8601String(),
        '_version': (existing['_version'] ?? 0) + 1,
      };

      // Update the document
      await _db!.transact(_db!.tx[collection][id].update(updatedData));

      _logger.fine('Updated document: collection=$collection, id=$id');
      return true;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to update document: collection=$collection, id=$id',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Delete a document by ID
  /// [collection] is the document type/collection name
  /// [id] is the document ID
  Future<bool> delete(String collection, String id) async {
    _ensureInitialized();

    try {
      // Check if document exists
      final existing = await read(collection, id);
      if (existing == null) {
        return false;
      }

      // Delete the document using InstantDB transaction
      await _db!.transact(_db!.delete(id));

      _logger.fine('Deleted document: collection=$collection, id=$id');
      return true;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to delete document: collection=$collection, id=$id',
          e,
          stackTrace);
      rethrow;
    }
  }

  // Query Operations

  /// Find all documents in a collection
  /// [collection] is the document type/collection name
  /// [limit] optionally limits the number of results
  Future<List<Map<String, dynamic>>> findAll(String collection,
      {int? limit}) async {
    _ensureInitialized();

    try {
      final query = <String, dynamic>{collection: <String, dynamic>{}};

      if (limit != null) {
        query[collection]['limit'] = limit;
      }

      final querySignal = _db!.subscribeQuery(query);
      final result = querySignal.value;

      if (result.hasData && result.data![collection] != null) {
        final collectionData = result.data![collection] as List?;
        if (collectionData != null) {
          final documents = List<Map<String, dynamic>>.from(
              collectionData.map((item) => Map<String, dynamic>.from(item)));
          // Add IDs to each document
          for (int i = 0; i < documents.length; i++) {
            final doc = documents[i];
            if (doc.containsKey('id')) {
              doc['_id'] = doc['id'];
            }
          }
          return documents;
        }
      }

      return [];
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to find documents in collection: $collection', e, stackTrace);
      rethrow;
    }
  }

  /// Find documents with a filter
  /// [collection] is the document type/collection name
  /// [where] is the filter condition
  Future<List<Map<String, dynamic>>> findWhere(
      String collection, Map<String, dynamic> where,
      {int? limit}) async {
    _ensureInitialized();

    try {
      final query = <String, dynamic>{
        collection: <String, dynamic>{
          'where': where,
        }
      };

      if (limit != null) {
        query[collection]['limit'] = limit;
      }

      final querySignal = _db!.subscribeQuery(query);
      final result = querySignal.value;

      if (result.hasData && result.data![collection] != null) {
        final collectionData = result.data![collection] as List?;
        if (collectionData != null) {
          final documents = List<Map<String, dynamic>>.from(
              collectionData.map((item) => Map<String, dynamic>.from(item)));
          // Add IDs to each document
          for (int i = 0; i < documents.length; i++) {
            final doc = documents[i];
            if (doc.containsKey('id')) {
              doc['_id'] = doc['id'];
            }
          }
          return documents;
        }
      }

      return [];
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to find documents with filter in collection: $collection',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Count documents in a collection
  /// [collection] is the document type/collection name
  Future<int> count(String collection) async {
    final documents = await findAll(collection);
    return documents.length;
  }

  /// Watch documents in a collection (reactive)
  /// Returns a Signal that updates when the collection changes
  Computed<List<Map<String, dynamic>>> watchCollection(String collection) {
    _ensureInitialized();

    final query = <String, dynamic>{collection: <String, dynamic>{}};

    final querySignal = _db!.subscribeQuery(query);

    // Transform the InstantDB signal to our format
    final transformedSignal = computed(() {
      final result = querySignal.value;
      if (result.hasData && result.data![collection] != null) {
        final collectionData = result.data![collection] as List?;
        if (collectionData != null) {
          final documents = List<Map<String, dynamic>>.from(
              collectionData.map((item) => Map<String, dynamic>.from(item)));
          // Add IDs to each document
          for (int i = 0; i < documents.length; i++) {
            final doc = documents[i];
            if (doc.containsKey('id')) {
              doc['_id'] = doc['id'];
            }
          }
          return documents;
        }
      }
      return <Map<String, dynamic>>[];
    });

    // Update real-time counter when data changes
    effect(() {
      transformedSignal.value; // Subscribe to changes
      realtimeUpdates.value++;
    });

    return transformedSignal;
  }

  /// Watch documents with a filter (reactive)
  Computed<List<Map<String, dynamic>>> watchWhere(
      String collection, Map<String, dynamic> where) {
    _ensureInitialized();

    final query = <String, dynamic>{
      collection: <String, dynamic>{
        'where': where,
      }
    };

    final querySignal = _db!.subscribeQuery(query);

    // Transform the InstantDB signal to our format
    final transformedSignal = computed(() {
      final result = querySignal.value;
      if (result.hasData && result.data![collection] != null) {
        final collectionData = result.data![collection] as List?;
        if (collectionData != null) {
          final documents = List<Map<String, dynamic>>.from(
              collectionData.map((item) => Map<String, dynamic>.from(item)));
          // Add IDs to each document
          for (int i = 0; i < documents.length; i++) {
            final doc = documents[i];
            if (doc.containsKey('id')) {
              doc['_id'] = doc['id'];
            }
          }
          return documents;
        }
      }
      return <Map<String, dynamic>>[];
    });

    // Update real-time counter when data changes
    effect(() {
      transformedSignal.value; // Subscribe to changes
      realtimeUpdates.value++;
    });

    return transformedSignal;
  }

  // Authentication Methods

  /// Sign up a new user
  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
  }) async {
    _ensureInitialized();

    try {
      final user = await _db!.auth.signUp(email: email, password: password);
      _logger.info('User signed up successfully');
      return user?.toJson(); // Convert to map if user exists
    } catch (e, stackTrace) {
      _logger.severe('Failed to sign up user', e, stackTrace);
      rethrow;
    }
  }

  /// Sign in an existing user
  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    _ensureInitialized();

    try {
      final user = await _db!.auth.signIn(email: email, password: password);
      _logger.info('User signed in successfully');
      return user?.toJson(); // Convert to map if user exists
    } catch (e, stackTrace) {
      _logger.severe('Failed to sign in user', e, stackTrace);
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _ensureInitialized();

    try {
      await _db!.auth.signOut();
      _logger.info('User signed out successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sign out user', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current user
  Map<String, dynamic>? get currentUser =>
      _db?.auth.currentUser.value?.toJson();

  /// Get database statistics
  Future<DatabaseStats> getStats() async {
    _ensureInitialized();

    try {
      // Note: InstantDB doesn't provide built-in stats API
      // We'll implement a basic version by counting documents

      // This is a simplified implementation
      // In a real app, you might want to maintain collection stats
      int totalDocuments = 0;
      int totalCollections = 0;

      // For demo purposes, we'll count some common collections
      final commonCollections = ['demo', 'tasks', 'users', 'settings'];

      for (final collection in commonCollections) {
        try {
          final count = await this.count(collection);
          if (count > 0) {
            totalDocuments += count;
            totalCollections++;
          }
        } catch (e) {
          // Collection might not exist, ignore
        }
      }

      return DatabaseStats(
        totalDocuments: totalDocuments,
        totalCollections: totalCollections,
        connectionStatus: connectionStatus.value,
        syncStatus: syncStatus.value,
        isAuthenticated: isAuthenticated,
        realtimeUpdates: realtimeUpdates.value,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to get database stats', e, stackTrace);
      rethrow;
    }
  }

  // Private Methods

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
          'DatabaseService not initialized. Call initialize() first.');
    }
  }
}

/// Database connection status
enum DatabaseConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Authentication status
enum AuthenticationStatus {
  unauthenticated,
  authenticated,
  error,
}

/// Real-time sync status
enum SyncStatus {
  disconnected,
  connected,
  error,
}

/// Database statistics
class DatabaseStats {
  final int totalDocuments;
  final int totalCollections;
  final DatabaseConnectionStatus connectionStatus;
  final SyncStatus syncStatus;
  final bool isAuthenticated;
  final int realtimeUpdates;

  DatabaseStats({
    required this.totalDocuments,
    required this.totalCollections,
    required this.connectionStatus,
    required this.syncStatus,
    required this.isAuthenticated,
    required this.realtimeUpdates,
  });

  @override
  String toString() {
    return 'DatabaseStats(docs: $totalDocuments, collections: $totalCollections, '
        'connected: ${connectionStatus.name}, sync: ${syncStatus.name}, '
        'auth: $isAuthenticated, updates: $realtimeUpdates)';
  }
}
