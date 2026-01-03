/// Example of two-phase reactive service preventing SignalEffectException
///
/// This example demonstrates the correct pattern for reactive services that use
/// database watchers. The key insight: NEVER create signals dynamically inside
/// effects. Always create watchers during initialization, then create effects
/// that read from those pre-existing watchers.
///
/// See `docs/signals-best-practices.md` for comprehensive guide.
library;

import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:signals/signals.dart';

/// Example model class
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Example model class
class Post {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime publishedAt;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.publishedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'content': content,
        'publishedAt': publishedAt.toIso8601String(),
      };
}

/// Example service demonstrating two-phase initialization pattern
///
/// This service follows the correct pattern to prevent SignalEffectException:
/// - Phase 1 (initialize): Create watchers and load initial data
/// - Phase 2 (activateEffects): Create effects that read from watchers
class TwoPhaseReactiveService {
  final DatabaseService _db;

  // Watchers (signals) - created ONCE in initialize(), NOT inside effects
  late final ReadonlySignal<List<Map<String, dynamic>>> _usersWatcher;
  late final ReadonlySignal<List<Map<String, dynamic>>> _postsWatcher;

  // Derived signals - updated by effects
  final users = signal<List<User>>([]);
  final posts = signal<List<Post>>([]);
  final userCount = signal<int>(0);
  final postCount = signal<int>(0);
  final isReady = signal<bool>(false);

  // Effect cleanup functions
  EffectCleanup? _usersEffectCleanup;
  EffectCleanup? _postsEffectCleanup;

  TwoPhaseReactiveService(this._db);

  /// Phase 1: Create watchers and load initial data
  ///
  /// This method:
  /// - Creates database watchers (signals) that will be read by effects
  /// - Loads initial data using one-time queries
  /// - Sets initial values for all derived signals
  /// - Does NOT create any effects (that happens in activateEffects)
  Future<void> initialize() async {
    // Create watchers (signals) that effects will read from
    // These are created ONCE, not dynamically inside effects
    _usersWatcher = _db.watchWhere('users', {});
    _postsWatcher = _db.watchWhere('posts', {});

    // Load initial data using one-time queries (not watchers)
    final initialUsers = await _db.findWhere('users', {});
    final initialPosts = await _db.findWhere('posts', {});

    // Set initial values - no effects exist yet, so this is safe
    users.value = initialUsers.map((u) => User.fromJson(u)).toList();
    posts.value = initialPosts.map((p) => Post.fromJson(p)).toList();
    userCount.value = initialUsers.length;
    postCount.value = initialPosts.length;

    isReady.value = true;

    // IMPORTANT: NO effects created here!
    // Effects will be created in activateEffects() after appReady check
  }

  /// Phase 2: Create effects from pre-existing watchers
  ///
  /// This method is called by the framework via AppConfig.onEffectsActivate
  /// AFTER appReady check passes and BEFORE rendering the AppShell.
  ///
  /// Effects created here read from watchers that were already created in
  /// initialize(). This prevents dynamic signal creation inside effects,
  /// which would cause SignalEffectException.
  void activateEffects() {
    // Users effect - transforms database data into app models
    _usersEffectCleanup = effect(() {
      // Read from PRE-EXISTING watcher signal (not dynamically created!)
      final rawUsers = _usersWatcher.value;

      // Transform data and update derived signals in untracked
      untracked(() {
        final parsed = rawUsers.map((u) => User.fromJson(u)).toList();
        users.value = parsed;
        userCount.value = parsed.length;
      });
    });

    // Posts effect - similar pattern
    _postsEffectCleanup = effect(() {
      // Read from PRE-EXISTING watcher signal
      final rawPosts = _postsWatcher.value;

      // Transform and update in untracked
      untracked(() {
        final parsed = rawPosts.map((p) => Post.fromJson(p)).toList();
        posts.value = parsed;
        postCount.value = parsed.length;
      });
    });
  }

  /// Cleanup - called when service is no longer needed
  void dispose() {
    _usersEffectCleanup?.call();
    _postsEffectCleanup?.call();
  }
}

/// Example of INCORRECT pattern that causes SignalEffectException
///
/// DO NOT USE THIS PATTERN! This is here for educational purposes only.
class IncorrectReactiveService {
  final DatabaseService _db;

  final users = signal<List<User>>([]);
  EffectCleanup? _effectCleanup;

  IncorrectReactiveService(this._db);

  /// ❌ WRONG - Creates dynamic signals inside effect
  Future<void> initialize() async {
    _effectCleanup = effect(() {
      // ❌ PROBLEM: Creates NEW signal every time effect runs!
      final usersWatcher = _db.watchWhere('users', {});

      // ❌ PROBLEM: Reads from dynamically-created signal
      final rawUsers = usersWatcher.value;

      // Even with untracked, the dynamic signal creation above
      // causes reactive cycles when Watch widgets are active
      untracked(() {
        users.value = rawUsers.map((u) => User.fromJson(u)).toList();
      });
    });
  }

  void dispose() {
    _effectCleanup?.call();
  }
}

/// Example usage in main app
///
/// ```dart
/// void main() {
///   runShellApp(() async {
///     // Get database service
///     final db = GetIt.instance<DatabaseService>();
///
///     // Create service instance
///     final reactiveService = TwoPhaseReactiveService(db);
///
///     // Phase 1: Initialize (creates watchers, loads data)
///     await reactiveService.initialize();
///
///     // Wait for service to be ready
///     while (!reactiveService.isReady.value) {
///       await Future.delayed(Duration(milliseconds: 50));
///     }
///
///     return AppConfig(
///       title: 'Two-Phase Example',
///
///       // Phase 2: Activate effects via framework callback
///       onEffectsActivate: () {
///         reactiveService.activateEffects();
///       },
///
///       routes: [
///         // ... your routes
///       ],
///     );
///   });
/// }
/// ```
