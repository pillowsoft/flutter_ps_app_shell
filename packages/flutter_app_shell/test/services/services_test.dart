import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  group('Service Tests', () {
    setUpAll(() async {
      // Initialize services
      await setupLocator();
    });

    group('DatabaseService', () {
      test('should initialize and create documents', () async {
        final dbService = getIt<DatabaseService>();

        expect(dbService.isInitialized, isTrue);

        // Create a test document
        final docId = await dbService.create('test', {
          'name': 'Test Document',
          'value': 123,
          'active': true,
        });

        expect(docId, greaterThan(0));

        // Read the document back
        final doc = await dbService.read(docId);
        expect(doc, isNotNull);
        expect(doc!['name'], equals('Test Document'));
        expect(doc['value'], equals(123));
        expect(doc['active'], equals(true));
        expect(doc['_id'], equals(docId));
        expect(doc['_type'], equals('test'));

        // Update the document
        final updated = await dbService.update(docId, {
          'name': 'Updated Document',
          'value': 456,
          'active': false,
        });

        expect(updated, isTrue);

        // Verify update
        final updatedDoc = await dbService.read(docId);
        expect(updatedDoc!['name'], equals('Updated Document'));
        expect(updatedDoc['value'], equals(456));
        expect(updatedDoc['active'], equals(false));
        expect(updatedDoc['_version'], equals(2));

        // Delete the document
        final deleted = await dbService.delete(docId);
        expect(deleted, isTrue);

        // Verify deletion (soft delete)
        final deletedDoc = await dbService.read(docId);
        expect(deletedDoc, isNull);

        // Get stats
        final stats = await dbService.getStats();
        expect(stats.totalDocuments, greaterThanOrEqualTo(1));
        expect(stats.deletedDocuments, greaterThanOrEqualTo(1));
      });

      test('should find documents by type', () async {
        final dbService = getIt<DatabaseService>();

        // Create multiple documents of same type
        await dbService.create('user', {'name': 'John', 'age': 30});
        await dbService.create('user', {'name': 'Jane', 'age': 25});
        await dbService.create('post', {'title': 'Hello World'});

        // Find users
        final users = await dbService.findByType('user');
        expect(users.length, equals(2));
        expect(users.every((user) => user['_type'] == 'user'), isTrue);

        // Find posts
        final posts = await dbService.findByType('post');
        expect(posts.length, equals(1));
        expect(posts.first['title'], equals('Hello World'));

        // Count users
        final userCount = await dbService.countByType('user');
        expect(userCount, equals(2));
      });
    });

    group('PreferencesService', () {
      test('should handle string preferences with signals', () async {
        final prefsService = getIt<PreferencesService>();

        expect(prefsService.isInitialized, isTrue);

        // Test string preferences
        final nameSignal =
            prefsService.getString('test_name', defaultValue: 'Default');
        expect(nameSignal.value, equals('Default'));

        await prefsService.setString('test_name', 'Test User');
        expect(nameSignal.value, equals('Test User'));

        // Test boolean preferences
        final activeSignal = prefsService.getBool('test_active');
        expect(activeSignal.value, isFalse);

        await prefsService.setBool('test_active', true);
        expect(activeSignal.value, isTrue);

        // Test integer preferences
        final countSignal = prefsService.getInt('test_count', defaultValue: 5);
        expect(countSignal.value, equals(5));

        await prefsService.setInt('test_count', 10);
        expect(countSignal.value, equals(10));

        // Test JSON preferences
        final jsonSignal = prefsService.getJson('test_json');
        expect(jsonSignal.value, isNull);

        final testData = {
          'name': 'Test',
          'values': [1, 2, 3]
        };
        await prefsService.setJson('test_json', testData);
        expect(jsonSignal.value, equals(testData));
      });

      test('should provide preferences statistics', () {
        final prefsService = getIt<PreferencesService>();
        final stats = prefsService.getStats();

        expect(stats.totalKeys, greaterThan(0));
        expect(stats.reactiveSignals, greaterThan(0));
      });
    });

    group('NetworkService', () {
      test('should initialize with correct status', () {
        final networkService = getIt<NetworkService>();

        expect(networkService.isInitialized, isTrue);
        expect(networkService.connectionStatus.value, isNotNull);

        final stats = networkService.getStats();
        expect(stats.queuedRequests, equals(0));
      });
    });

    group('AuthenticationService', () {
      test('should handle authentication flow', () async {
        final authService = getIt<AuthenticationService>();

        expect(authService.isInitialized, isTrue);
        expect(authService.isAuthenticated.value, isFalse);
        expect(authService.currentUser.value, isNull);

        // Test sign up
        final signUpResult = await authService.signUp(
            'test@example.com', 'password123', 'Test User');

        expect(signUpResult.success, isTrue);
        expect(signUpResult.user, isNotNull);
        expect(authService.isAuthenticated.value, isTrue);
        expect(
            authService.currentUser.value?.email, equals('test@example.com'));
        expect(authService.currentUser.value?.name, equals('Test User'));

        // Test token validity
        expect(authService.isTokenValid(), isTrue);
        expect(authService.getAuthToken(), isNotNull);

        // Test sign out
        await authService.signOut();
        expect(authService.isAuthenticated.value, isFalse);
        expect(authService.currentUser.value, isNull);
        expect(authService.getAuthToken(), isNull);

        // Test sign in
        final signInResult =
            await authService.signIn('test@example.com', 'password123');

        expect(signInResult.success, isTrue);
        expect(authService.isAuthenticated.value, isTrue);
      });

      test('should validate credentials properly', () async {
        final authService = getIt<AuthenticationService>();

        // Test invalid email
        final invalidEmail = await authService.signIn('invalid', 'password123');
        expect(invalidEmail.success, isFalse);
        expect(invalidEmail.error, contains('email'));

        // Test short password
        final shortPassword =
            await authService.signIn('test@example.com', '123');
        expect(shortPassword.success, isFalse);
        expect(shortPassword.error, contains('password'));
      });
    });
  });
}
