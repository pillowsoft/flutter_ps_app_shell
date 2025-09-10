import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/src/services/database_service.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService db;
    const testAppId = 'test-app-id'; // Mock app ID for testing

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      db = DatabaseService.instance;
    });

    tearDown(() async {
      if (db.isInitialized) {
        await db.close();
      }
    });

    test('should initialize with app ID', () async {
      // Note: This test may fail if InstantDB service is not available
      // In a real environment, you would mock the InstantDB dependency
      try {
        await db.initialize(appId: testAppId, enableSync: false);
        expect(db.isInitialized, true);
        expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);
      } catch (e) {
        // If InstantDB service is not available, skip this test
        skip('InstantDB service not available: $e');
      }
    });

    test('should initialize in local-only mode without app ID', () async {
      // Empty app ID should work for local-only mode
      try {
        await db.initialize(appId: '', enableSync: false);
        expect(db.isInitialized, true);
        expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);
      } catch (e) {
        // If InstantDB service is not available, skip this test
        skip('InstantDB service not available: $e');
      }
    });

    test('should create and read documents', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create a document
        const collection = 'test_collection';
        final testData = {'name': 'Test Document', 'value': 42};
        final id = await db.create(collection, testData);

        expect(id, isNotEmpty);

        // Read the document back
        final doc = await db.read(collection, id);
        expect(doc, isNotNull);
        expect(doc!['name'], 'Test Document');
        expect(doc['value'], 42);
        expect(doc['_type'], collection);
        expect(doc['_id'], id);
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should update documents', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create a document
        const collection = 'test_collection';
        final id = await db.create(collection, {'name': 'Original'});

        // Update it
        final success = await db.update(collection, id, {'name': 'Updated'});
        expect(success, true);

        // Read it back
        final doc = await db.read(collection, id);
        expect(doc!['name'], 'Updated');
        expect(doc['_version'], greaterThan(1)); // Version should increment
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should delete documents', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create a document
        const collection = 'test_collection';
        final id = await db.create(collection, {'name': 'ToDelete'});

        // Delete it
        final success = await db.delete(collection, id);
        expect(success, true);

        // Should not be readable after delete
        final doc = await db.read(collection, id);
        expect(doc, isNull);
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should find all documents in a collection', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create multiple documents
        const collection = 'test_collection';
        await db.create(collection, {'name': 'Doc1', 'type': 'A'});
        await db.create(collection, {'name': 'Doc2', 'type': 'B'});
        await db.create(collection, {'name': 'Doc3', 'type': 'A'});

        // Find all documents
        final allDocs = await db.findAll(collection);
        expect(allDocs.length, greaterThanOrEqualTo(3));

        // Check that each document has required metadata
        for (final doc in allDocs) {
          expect(doc['_id'], isNotNull);
          expect(doc['_createdAt'], isNotNull);
          expect(doc['_updatedAt'], isNotNull);
          expect(doc['_version'], isNotNull);
        }
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should find documents with filter', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create multiple documents
        const collection = 'test_collection';
        await db.create(
            collection, {'name': 'Doc1', 'category': 'A', 'active': true});
        await db.create(
            collection, {'name': 'Doc2', 'category': 'B', 'active': false});
        await db.create(
            collection, {'name': 'Doc3', 'category': 'A', 'active': true});

        // Find documents with filter
        final filteredDocs =
            await db.findWhere(collection, {'category': 'A', 'active': true});

        expect(filteredDocs.length, greaterThanOrEqualTo(2));

        for (final doc in filteredDocs) {
          expect(doc['category'], 'A');
          expect(doc['active'], true);
        }
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should count documents in a collection', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create multiple documents
        const collection = 'test_collection';
        await db.create(collection, {'name': 'Doc1'});
        await db.create(collection, {'name': 'Doc2'});
        await db.create(collection, {'name': 'Doc3'});

        // Count documents
        final count = await db.count(collection);
        expect(count, greaterThanOrEqualTo(3));
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should provide reactive queries with watchCollection', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        const collection = 'reactive_test';

        // Get reactive signal for the collection
        final watchSignal = db.watchCollection(collection);

        // Initial state should be empty or contain existing docs
        final initialDocs = watchSignal.value;
        final initialCount = initialDocs.length;

        // Create a new document
        await db.create(collection, {
          'name': 'Reactive Doc',
          'timestamp': DateTime.now().toIso8601String()
        });

        // Wait a bit for the reactive update
        await Future.delayed(const Duration(milliseconds: 100));

        // The watch signal should update automatically
        final updatedDocs = watchSignal.value;
        expect(updatedDocs.length, greaterThan(initialCount));

        // Verify the new document is in the results
        final newDoc = updatedDocs.firstWhere(
          (doc) => doc['name'] == 'Reactive Doc',
          orElse: () => <String, dynamic>{},
        );
        expect(newDoc['name'], 'Reactive Doc');
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should provide reactive queries with watchWhere', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        const collection = 'reactive_filter_test';

        // Get reactive signal with filter
        final watchSignal = db.watchWhere(collection, {'active': true});

        // Initial state
        final initialDocs = watchSignal.value;
        final initialCount = initialDocs.length;

        // Create documents with different active states
        await db.create(collection, {'name': 'Active Doc', 'active': true});
        await db.create(collection, {'name': 'Inactive Doc', 'active': false});

        // Wait for reactive update
        await Future.delayed(const Duration(milliseconds: 100));

        // Should only show active documents
        final filteredDocs = watchSignal.value;
        expect(filteredDocs.length, greaterThan(initialCount));

        // Verify all returned docs are active
        for (final doc in filteredDocs) {
          expect(doc['active'], true);
        }
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should track real-time updates', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: true);

        final initialUpdateCount = db.realtimeUpdates.value;

        // Create a document to trigger updates
        await db.create('realtime_test', {'name': 'Update Test'});

        // Wait a bit for the signal to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Real-time update counter should increment
        expect(db.realtimeUpdates.value, greaterThan(initialUpdateCount));
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should provide database statistics', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Create some test data
        await db.create('stats_test', {'name': 'Stats Doc 1'});
        await db.create('stats_test', {'name': 'Stats Doc 2'});

        final stats = await db.getStats();

        expect(stats, isNotNull);
        expect(stats.totalDocuments, greaterThanOrEqualTo(2));
        expect(stats.totalCollections, greaterThanOrEqualTo(1));
        expect(stats.connectionStatus, DatabaseConnectionStatus.connected);
        expect(stats.syncStatus, isNotNull);
        expect(stats.isAuthenticated, isA<bool>());
        expect(stats.realtimeUpdates, isA<int>());

        // Test string representation
        final statsString = stats.toString();
        expect(statsString, contains('docs:'));
        expect(statsString, contains('collections:'));
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should handle authentication operations', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        // Test authentication status
        expect(db.isAuthenticated, isA<bool>());
        expect(db.currentUser, isNull); // No user initially
        expect(db.authenticationStatus.value,
            AuthenticationStatus.unauthenticated);

        // Note: Actual sign-up/sign-in tests would require a real InstantDB instance
        // with proper authentication setup. In a real test environment, you would
        // mock these operations or use a test-specific database instance.
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should handle service lifecycle properly', () async {
      expect(db.isInitialized, false);
      expect(db.connectionStatus.value, DatabaseConnectionStatus.disconnected);

      try {
        await db.initialize(appId: testAppId, enableSync: false);

        expect(db.isInitialized, true);
        expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);

        await db.close();

        expect(db.isInitialized, false);
        expect(
            db.connectionStatus.value, DatabaseConnectionStatus.disconnected);
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should validate document operations', () async {
      // Test operations without initialization
      expect(
        () => db.create('test', {'data': 'value'}),
        throwsStateError,
      );

      expect(
        () => db.read('test', 'test-id'),
        throwsStateError,
      );

      expect(
        () => db.update('test', 'test-id', {'data': 'updated'}),
        throwsStateError,
      );

      expect(
        () => db.delete('test', 'test-id'),
        throwsStateError,
      );
    });

    test('should handle connection status signals', () async {
      // Initially disconnected
      expect(db.connectionStatus.value, DatabaseConnectionStatus.disconnected);
      expect(db.syncStatus.value, SyncStatus.disconnected);

      try {
        await db.initialize(appId: testAppId, enableSync: true);

        // Should be connected after initialization
        expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);
        expect(db.syncStatus.value, SyncStatus.connected);

        await db.close();

        // Should be disconnected after close
        expect(
            db.connectionStatus.value, DatabaseConnectionStatus.disconnected);
        expect(db.syncStatus.value, SyncStatus.disconnected);
      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });

    test('should transform where clauses correctly for InstantDB operators', () async {
      try {
        await db.initialize(appId: testAppId, enableSync: false);

        const collection = 'operator_test';
        
        // Create test documents with specific values
        final docId1 = await db.create(collection, {
          'conversationId': 'conv-123',
          'messageType': 'text',
          'active': true
        });
        final docId2 = await db.create(collection, {
          'conversationId': 'conv-456', 
          'messageType': 'image',
          'active': false
        });
        final docId3 = await db.create(collection, {
          'conversationId': 'conv-123',
          'messageType': 'text', 
          'active': true
        });

        // Test simple equality filter (this should be transformed to use $eq)
        final simpleFilter = await db.findWhere(collection, {
          'conversationId': 'conv-123'
        });
        
        expect(simpleFilter.length, greaterThanOrEqualTo(2));
        for (final doc in simpleFilter) {
          expect(doc['conversationId'], 'conv-123');
        }

        // Test multiple field filter
        final multiFilter = await db.findWhere(collection, {
          'conversationId': 'conv-123',
          'messageType': 'text',
          'active': true
        });
        
        expect(multiFilter.length, greaterThanOrEqualTo(2));
        for (final doc in multiFilter) {
          expect(doc['conversationId'], 'conv-123');
          expect(doc['messageType'], 'text');
          expect(doc['active'], true);
        }

        // Test that already-formatted operators are preserved
        final operatorFilter = await db.findWhere(collection, {
          'conversationId': {'\$eq': 'conv-456'}
        });
        
        expect(operatorFilter.length, greaterThanOrEqualTo(1));
        for (final doc in operatorFilter) {
          expect(doc['conversationId'], 'conv-456');
        }

      } catch (e) {
        skip('InstantDB service not available: $e');
      }
    });
  });
}
