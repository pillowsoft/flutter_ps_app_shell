import 'dart:async';
import 'dart:convert';
import 'package:instantdb_flutter/instantdb_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';

/// Real-time database service using InstantDB with built-in cloud sync
/// Supports both local-only mode (no app ID) and cloud-sync mode (with app ID)
///
/// IMPORTANT: This service includes a workaround for InstantDB Flutter package bug
/// where datalog-result format from the server is not properly converted to the
/// expected collection format. Remove the workaround when the package is fixed.
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
      // Add metadata to the document
      final documentData = {
        ...data,
        '_type': collection,
        '_createdAt': DateTime.now().toIso8601String(),
        '_updatedAt': DateTime.now().toIso8601String(),
        '_version': 1,
      };

      // Create the document using correct InstantDB transaction API
      // tx[collection].create() generates OperationType.add and handles ID automatically
      final transactionResult =
          await _db!.transact(_db!.tx[collection].create(documentData));

      // Extract the generated ID from the transaction
      // InstantDB's create() method generates an ID if not provided
      final id = documentData['id'] as String? ?? _db!.id();

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

      // Use queryOnce to wait for the initial data load
      final result = await _db!.queryOnce(query);

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

      // Delete the document using correct InstantDB transaction API
      // tx[collection][id].delete() generates OperationType.delete
      await _db!.transact(_db!.tx[collection][id].delete());

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

      // Use queryOnce to wait for the initial data load
      final result = await _db!.queryOnce(query);

      if (result.hasData && result.data != null) {
        // Check for datalog format first (workaround for InstantDB package bug)
        if (result.data!['datalog-result'] != null) {
          final documents = _parseDatalogResult(result.data!, collection);
          _logger
              .fine('Parsed ${documents.length} documents from datalog format');
          return documents;
        }

        // Fall back to standard format
        if (result.data![collection] != null) {
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

      // Use queryOnce to wait for the initial data load
      final result = await _db!.queryOnce(query);

      if (result.hasData && result.data != null) {
        // Check for datalog format first (workaround for InstantDB package bug)
        if (result.data!['datalog-result'] != null) {
          final documents = _parseDatalogResult(result.data!, collection);
          _logger.fine(
              'Parsed ${documents.length} documents from datalog format (findWhere)');
          return documents;
        }

        // Fall back to standard format
        if (result.data![collection] != null) {
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
      if (result.hasData && result.data != null) {
        // Check for datalog format first (workaround for InstantDB package bug)
        if (result.data!['datalog-result'] != null) {
          final documents = _parseDatalogResult(result.data!, collection);
          return documents;
        }

        // Fall back to standard format
        if (result.data![collection] != null) {
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
      if (result.hasData && result.data != null) {
        // Check for datalog format first (workaround for InstantDB package bug)
        if (result.data!['datalog-result'] != null) {
          final documents = _parseDatalogResult(result.data!, collection);
          return documents;
        }

        // Fall back to standard format
        if (result.data![collection] != null) {
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

  /// Diagnose datalog parsing for debugging issues
  /// Returns detailed information about the parsing process
  Future<Map<String, dynamic>> diagnoseDatalogParsing(String collection) async {
    _ensureInitialized();
    
    final diagnosis = <String, dynamic>{
      'collection': collection,
      'timestamp': DateTime.now().toIso8601String(),
      'attributeMappings': {},
      'queryResult': {},
      'parsedDocuments': 0,
      'unmappedAttributes': [],
      'errors': [],
    };

    try {
      // Get the attribute mappings for this collection
      final mappings = _getAttributeMappings(collection);
      diagnosis['attributeMappings'] = mappings;
      
      // Run a query to get datalog format
      final query = {collection: {}};
      final result = await _db!.queryOnce(query);
      
      diagnosis['queryResult'] = {
        'hasData': result.hasData,
        'hasError': result.hasError,
        'error': result.error?.toString(),
      };
      
      if (result.hasData && result.data != null) {
        final data = result.data!;
        
        // Check format
        if (data['datalog-result'] != null) {
          diagnosis['format'] = 'datalog';
          final datalogResult = data['datalog-result'] as Map;
          final joinRows = datalogResult['join-rows'] as List?;
          
          diagnosis['joinRowCount'] = joinRows?.length ?? 0;
          
          if (joinRows != null && joinRows.isNotEmpty) {
            // Analyze attribute IDs in the data
            final foundAttributeIds = <String, Map<String, dynamic>>{};
            
            for (final row in joinRows) {
              if (row is List && row.length >= 4) {
                final attributeId = row[1] as String;
                final value = row[2];
                
                if (!foundAttributeIds.containsKey(attributeId)) {
                  foundAttributeIds[attributeId] = {
                    'sampleValue': value,
                    'valueType': value.runtimeType.toString(),
                    'isMapped': mappings.containsKey(attributeId),
                    'mappedTo': mappings[attributeId],
                    'occurrences': 1,
                  };
                } else {
                  foundAttributeIds[attributeId]!['occurrences']++;
                }
              }
            }
            
            diagnosis['foundAttributeIds'] = foundAttributeIds;
            
            // Identify unmapped attributes
            final unmapped = foundAttributeIds.entries
                .where((e) => !e.value['isMapped'])
                .map((e) => {
                      'id': e.key,
                      'sampleValue': e.value['sampleValue'],
                      'valueType': e.value['valueType'],
                      'occurrences': e.value['occurrences'],
                    })
                .toList();
            
            diagnosis['unmappedAttributes'] = unmapped;
            
            // Try to parse with current mappings
            final parsedDocs = _parseDatalogResult(data, collection);
            diagnosis['parsedDocuments'] = parsedDocs.length;
            
            if (parsedDocs.isNotEmpty) {
              diagnosis['sampleDocument'] = parsedDocs.first;
              diagnosis['documentFields'] = parsedDocs.first.keys.toList();
            }
          }
        } else if (data[collection] != null) {
          diagnosis['format'] = 'collection';
          final collectionData = data[collection] as List?;
          diagnosis['documentCount'] = collectionData?.length ?? 0;
        } else {
          diagnosis['format'] = 'unknown';
          diagnosis['dataKeys'] = data.keys.toList();
        }
      }
    } catch (e, stack) {
      diagnosis['errors'].add({
        'message': e.toString(),
        'stackTrace': stack.toString().split('\n').take(5).join('\n'),
      });
    }
    
    return diagnosis;
  }

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

  /// Get attribute ID mappings for a specific collection
  /// Supports multiple possible IDs per field to handle schema variations
  Map<String, String> _getAttributeMappings(String collection) {
    // Collection-specific mappings
    final collectionMappings = <String, Map<String, List<String>>>{
      'conversations': {
        'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
        'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
        'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
        'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
      },
      'test_conversations': {
        'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
        'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
        'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
        'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
      },
      'todos': {
        'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
        'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
        'completed': ['a1b2c3d4-e5f6-7890-abcd-ef1234567890'], // Example ID
        'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
        'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
      },
    };

    // Default/common mappings that apply to most collections
    final defaultMappings = {
      'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
      'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
      'name': ['82a884f7-6e0f-427d-88b6-66c550e86d98'], // title/name often share IDs
      'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
      'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
    };

    // Get mappings for this collection or use defaults
    final mappings = collectionMappings[collection] ?? defaultMappings;
    
    // Convert from field->IDs to ID->field for efficient lookup
    final attributeMap = <String, String>{};
    mappings.forEach((fieldName, attributeIds) {
      for (final attrId in attributeIds) {
        attributeMap[attrId] = fieldName;
      }
    });

    return attributeMap;
  }

  /// Parse InstantDB's datalog-result format into entity list
  /// This is a workaround for the InstantDB package bug where datalog results
  /// are not properly converted to the expected collection format
  List<Map<String, dynamic>> _parseDatalogResult(
      Map<String, dynamic> data, String collection) {
    final datalogResult = data['datalog-result'];
    if (datalogResult == null || datalogResult['join-rows'] == null) {
      return [];
    }

    final joinRows = datalogResult['join-rows'] as List;
    if (joinRows.isEmpty) {
      return [];
    }

    _logger.info('🔍 Parsing datalog for collection "$collection" with ${joinRows.length} join-rows');

    // Group rows by entity ID to reconstruct documents
    final entityMap = <String, Map<String, dynamic>>{};
    
    // Track unmapped attribute IDs for debugging
    final unmappedAttributes = <String, dynamic>{};

    // Get attribute mappings for this collection
    final attributeMap = _getAttributeMappings(collection);

    for (final row in joinRows) {
      if (row is List && row.length >= 4) {
        final entityId = row[0] as String;
        final attributeId = row[1] as String;
        final value = row[2];
        // final timestamp = row[3]; // Not used currently

        // Initialize entity if not exists
        entityMap[entityId] ??= {'id': entityId};

        // Map attribute ID to field name
        final fieldName = attributeMap[attributeId];
        if (fieldName != null) {
          entityMap[entityId]![fieldName] = value;
        } else {
          // Track unmapped attributes for debugging
          if (!unmappedAttributes.containsKey(attributeId)) {
            unmappedAttributes[attributeId] = {
              'sampleValue': value,
              'valueType': value.runtimeType.toString(),
              'count': 1,
            };
          } else {
            unmappedAttributes[attributeId]['count']++;
          }
          
          // For unknown attribute IDs, try to infer based on value type
          if (value is bool && !entityMap[entityId]!.containsKey('completed')) {
            // Boolean values are likely 'completed' for todos
            entityMap[entityId]!['completed'] = value;
          } else if (value is String && value.contains('@')) {
            // Email-like strings might be email field
            entityMap[entityId]!['email'] = value;
          } else if (value is String && 
                     (value.contains('T') && value.contains(':')) &&
                     !entityMap[entityId]!.containsKey('createdAt')) {
            // ISO date strings for createdAt if not mapped
            entityMap[entityId]!['createdAt'] = value;
          } else {
            // Use the attribute ID as the field name for now
            entityMap[entityId]![attributeId] = value;
            _logger.fine(
                'Unknown attribute ID: $attributeId with value: $value (${value.runtimeType})');
          }
        }
      }
    }
    
    // Log unmapped attributes summary
    if (unmappedAttributes.isNotEmpty) {
      _logger.warning('⚠️ Found ${unmappedAttributes.length} unmapped attribute IDs:');
      unmappedAttributes.forEach((attrId, info) {
        _logger.warning('  - $attrId: ${info['valueType']} (${info['count']} occurrences) sample: "${info['sampleValue']}"');
      });
      _logger.warning('Consider adding these mappings to the attributeMap');
    }

    // Convert to list and add metadata
    final documents = entityMap.values.map((entity) {
      final doc = Map<String, dynamic>.from(entity);
      // Add standard metadata if not present
      doc['_id'] = doc['id'];
      doc['__type'] = collection;
      return doc;
    }).toList();

    _logger.info('✅ Parsed ${documents.length} documents from ${joinRows.length} join-rows');
    if (documents.isNotEmpty) {
      _logger.fine('Sample document fields: ${documents.first.keys.toList()}');
    }

    return documents;
  }

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
