// ignore_for_file: unused_element, unused_field

/// Example of a reactive service following Signals best practices.
///
/// This file demonstrates the CORRECT pattern for creating reactive effects
/// that transform data from database watchers into app-level signals without
/// causing SignalEffectException.
///
/// **Key Pattern**: ALL signal writes inside effects must use untracked()
///
/// See docs/signals-best-practices.md for comprehensive documentation.

import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:signals/signals.dart';

/// Example User model
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Example reactive user service following Signals best practices
///
/// This service demonstrates:
/// 1. ✅ Correct use of untracked() for ALL signal writes in effects
/// 2. ✅ Synchronous data transformations wrapped in untracked()
/// 3. ✅ Multiple derived signals updated atomically
/// 4. ✅ Proper cleanup on dispose
class ReactiveUserService {
  final DatabaseService _db;

  // Source signal (from database watcher)
  late final ReadonlySignal<List<Map<String, dynamic>>> _usersWatcher;

  // Derived signals (transformed data)
  // These are updated by effects and read by Watch widgets
  final users = signal<List<User>>([]);
  final activeUser = signal<User?>(null);
  final userCount = signal<int>(0);
  final isEmpty = signal<bool>(true);

  // Effect cleanup
  EffectCleanup? _effectCleanup;

  ReactiveUserService(this._db);

  /// Initialize the service and set up reactive effects
  ///
  /// This method:
  /// 1. Creates database watcher (source signal)
  /// 2. Sets up effect to transform data (with proper untracked() usage)
  /// 3. Returns immediately - effects run asynchronously
  Future<void> initialize() async {
    // Set up database watcher for users collection
    _usersWatcher = _db.watchWhere('users', {});

    // ✅ CORRECT PATTERN - Create effect with untracked() for writes
    _effectCleanup = effect(() {
      // 1. Read trigger signal (creates dependency on database changes)
      final rawUsers = _usersWatcher.value;

      // 2. Process data and update ALL derived signals in untracked()
      //    This is CRITICAL - prevents reactive cycles when Watch widgets
      //    read these signals
      untracked(() {
        // Transform raw database data to User objects
        final parsed = rawUsers.map((data) => User.fromJson(data)).toList();

        // Update all derived signals
        // These can be safely read by Watch widgets now
        users.value = parsed;
        userCount.value = parsed.length;
        isEmpty.value = parsed.isEmpty;

        // Update active user if needed
        final currentActive = activeUser.value;
        if (currentActive != null) {
          final updated = parsed.firstWhere(
            (u) => u.id == currentActive.id,
            orElse: () => parsed.isEmpty ? null : parsed.first,
          );
          activeUser.value = updated;
        } else if (parsed.isNotEmpty) {
          // Set first user as active if none selected
          activeUser.value = parsed.first;
        }
      });
    });
  }

  /// Set the active user
  void setActiveUser(String userId) {
    final user = users.value.firstWhere(
      (u) => u.id == userId,
      orElse: () => users.value.first,
    );
    activeUser.value = user;
  }

  /// Clean up effects when disposing
  void dispose() {
    _effectCleanup?.call();
  }
}

/// Example of WRONG pattern (for comparison)
///
/// ❌ DO NOT USE THIS PATTERN
class WrongReactiveUserService {
  final DatabaseService _db;

  late final ReadonlySignal<List<Map<String, dynamic>>> _usersWatcher;
  final users = signal<List<User>>([]);

  WrongReactiveUserService(this._db);

  Future<void> initialize() async {
    _usersWatcher = _db.watchWhere('users', {});

    // ❌ WRONG - Missing untracked() for signal write
    effect(() {
      final rawUsers = _usersWatcher.value;

      // Direct write without untracked() - causes SignalEffectException
      // when Watch widgets are active!
      users.value = rawUsers.map((data) => User.fromJson(data)).toList();
    });
  }
}

/// Example of conditional updates with correct pattern
class ConditionalUpdateExample {
  final DatabaseService _db;

  final currentUser = signal<User?>(null);
  final isLoggedIn = signal<bool>(false);
  final userDisplayName = signal<String>('Guest');

  EffectCleanup? _effectCleanup;

  ConditionalUpdateExample(this._db);

  Future<void> initialize() async {
    final authWatcher = _db.watchWhere('auth', {});

    // ✅ CORRECT - Wrap ALL writes in untracked, even conditional ones
    _effectCleanup = effect(() {
      final authData = authWatcher.value;

      untracked(() {
        if (authData.isEmpty) {
          // User logged out - update all related signals
          currentUser.value = null;
          isLoggedIn.value = false;
          userDisplayName.value = 'Guest';
        } else {
          // User logged in - update from data
          final user = User.fromJson(authData.first);
          currentUser.value = user;
          isLoggedIn.value = true;
          userDisplayName.value = user.name;
        }
      });
    });
  }

  void dispose() {
    _effectCleanup?.call();
  }
}

/// Example with multiple source signals
class MultiSourceExample {
  final DatabaseService _db;

  late final ReadonlySignal<List<Map<String, dynamic>>> _usersWatcher;
  late final ReadonlySignal<List<Map<String, dynamic>>> _settingsWatcher;

  final combinedData = signal<String>('Loading...');

  EffectCleanup? _effectCleanup;

  MultiSourceExample(this._db);

  Future<void> initialize() async {
    _usersWatcher = _db.watchWhere('users', {});
    _settingsWatcher = _db.watchWhere('settings', {});

    // ✅ CORRECT - Read multiple sources, write in untracked
    _effectCleanup = effect(() {
      // Read both trigger signals
      final users = _usersWatcher.value;
      final settings = _settingsWatcher.value;

      // Process and write in untracked
      untracked(() {
        final userCount = users.length;
        final settingCount = settings.length;
        combinedData.value = 'Users: $userCount, Settings: $settingCount';
      });
    });
  }

  void dispose() {
    _effectCleanup?.call();
  }
}

/// Example showing why untracked() is needed (explanation)
///
/// Without untracked():
/// 1. Effect reads usersWatcher.value (creates dependency on DB changes)
/// 2. Effect writes to users signal WITHOUT untracked()
/// 3. Signals library tracks this write as part of effect evaluation
/// 4. Watch widget in UI reads users signal
/// 5. Signals library detects concurrent dependency tracking:
///    - Effect is modifying users while tracking dependencies
///    - Watch widget is reading users and creating its own tracking
/// 6. Throws SignalEffectException to prevent potential infinite loop
///
/// With untracked():
/// 1. Effect reads usersWatcher.value (creates dependency on DB changes)
/// 2. Effect writes to users signal INSIDE untracked()
/// 3. untracked() tells Signals: "don't track this write"
/// 4. Watch widget reads users signal independently
/// 5. No conflict - effect subscribes to DB, Watch subscribes to users
/// 6. No SignalEffectException!

/// Summary of the pattern:
///
/// ```dart
/// effect(() {
///   // 1. Read trigger signal(s) - creates dependencies
///   final data = sourceSignal.value;
///
///   // 2. Process and write in untracked() - prevents cycles
///   untracked(() {
///     targetSignal.value = processData(data);
///     derivedSignal1.value = computeValue1(data);
///     derivedSignal2.value = computeValue2(data);
///   });
/// });
/// ```
///
/// This applies to:
/// - ✅ Synchronous data transformations (like these examples)
/// - ✅ Async callback writes
/// - ✅ Conditional updates
/// - ✅ Error handler writes
/// - ✅ Any signal mutation inside an effect
///
/// See docs/signals-best-practices.md for comprehensive patterns and examples.
