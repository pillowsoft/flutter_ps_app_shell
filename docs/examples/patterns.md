# Common Patterns & Examples

This guide provides practical examples and recommended patterns for building applications with Flutter App Shell. Use these patterns as starting points for your own implementations.

## 🎯 Table of Contents

- [Authentication Patterns](#authentication-patterns)
- [Data Management Patterns](#data-management-patterns)
- [UI Patterns](#ui-patterns)
- [Navigation Patterns](#navigation-patterns)
- [Service Integration Patterns](#service-integration-patterns)
- [Performance Patterns](#performance-patterns)

## 🔐 Authentication Patterns

### Basic Login/Logout Flow
```dart
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthenticationService>();
    final ui = getAdaptiveFactory(context);
    
    return Watch((context) {
      final isLoading = auth.isLoading.value;
      final isAuthenticated = auth.isAuthenticated.value;
      
      // Redirect if already authenticated
      if (isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getIt<NavigationService>().goToPath('/dashboard');
        });
      }
      
      return ui.scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ui.textField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ui.textField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password required';
                    if (value!.length < 6) return 'Password too short';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ui.button(
                    label: isLoading ? 'Signing In...' : 'Sign In',
                    onPressed: isLoading ? null : _handleLogin,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = getIt<AuthenticationService>();
    final ui = getAdaptiveFactory(context);
    
    try {
      await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      ui.showSnackBar(
        context: context,
        content: Text('Login failed: ${e.toString()}'),
      );
    }
  }
}
```

### Protected Route Pattern
```dart
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String redirectPath;
  
  const ProtectedRoute({
    Key? key,
    required this.child,
    this.redirectPath = '/auth',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthenticationService>();
    
    return Watch((context) {
      final isAuthenticated = auth.isAuthenticated.value;
      
      if (!isAuthenticated) {
        // Redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getIt<NavigationService>().goToPath(redirectPath);
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      return child;
    });
  }
}

// Usage in routes
AppRoute(
  title: 'Dashboard',
  path: '/dashboard',
  icon: Icons.dashboard,
  builder: (context, state) => ProtectedRoute(
    child: DashboardScreen(),
  ),
),
```

## 📊 Data Management Patterns

### CRUD List Pattern
```dart
class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _titleController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final db = getIt<DatabaseService>();
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('Todos'),
        actions: [
          ui.iconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Document>>(
        stream: db.watchByType('todos'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final todos = snapshot.data ?? [];
          
          if (todos.isEmpty) {
            return const Center(
              child: Text('No todos yet. Add one to get started!'),
            );
          }
          
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _TodoTile(
                todo: todo,
                onToggle: () => _toggleTodo(todo),
                onDelete: () => _deleteTodo(todo),
                onEdit: () => _editTodo(todo),
              );
            },
          );
        },
      ),
    );
  }
  
  Future<void> _toggleTodo(Document todo) async {
    final db = getIt<DatabaseService>();
    await db.update('todos', todo.id, {
      'completed': !(todo.data['completed'] ?? false),
    });
  }
  
  Future<void> _deleteTodo(Document todo) async {
    final db = getIt<DatabaseService>();
    final ui = getAdaptiveFactory(context);
    
    final confirmed = await ui.showDialog<bool>(
      context: context,
      title: const Text('Delete Todo'),
      content: const Text('Are you sure you want to delete this todo?'),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ui.button(
          label: 'Delete',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    
    if (confirmed == true) {
      await db.delete('todos', todo.id);
    }
  }
  
  void _showAddDialog() {
    final ui = getAdaptiveFactory(context);
    
    ui.showDialog(
      context: context,
      title: const Text('Add Todo'),
      content: ui.textField(
        controller: _titleController,
        labelText: 'Title',
        autofocus: true,
      ),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        ui.button(
          label: 'Add',
          onPressed: () => _addTodo(),
        ),
      ],
    );
  }
  
  Future<void> _addTodo() async {
    if (_titleController.text.trim().isEmpty) return;
    
    final db = getIt<DatabaseService>();
    await db.create('todos', {
      'title': _titleController.text.trim(),
      'completed': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    _titleController.clear();
    Navigator.of(context).pop();
  }
}

class _TodoTile extends StatelessWidget {
  final Document todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  
  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });
  
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final isCompleted = todo.data['completed'] ?? false;
    
    return ui.listTile(
      title: Text(
        todo.data['title'] ?? '',
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      leading: ui.checkbox(
        value: isCompleted,
        onChanged: (_) => onToggle(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ui.iconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          ui.iconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
```

### Offline-First Data Pattern
```dart
class OfflineFirstService {
  final DatabaseService _db = getIt<DatabaseService>();
  final NetworkService _network = getIt<NetworkService>();
  
  // Always try local first, then sync if needed
  Future<List<Article>> getArticles({bool forceRefresh = false}) async {
    // 1. Get local data immediately
    final localArticles = await _db.findByType('articles');
    
    // 2. If we have local data and don't need fresh data, return it
    if (localArticles.isNotEmpty && !forceRefresh) {
      // Trigger background sync
      _syncArticlesInBackground();
      return localArticles.map((doc) => Article.fromDocument(doc)).toList();
    }
    
    // 3. Try to fetch from network
    try {
      final response = await _network.get('/articles');
      final articles = (response.data as List)
          .map((json) => Article.fromJson(json))
          .toList();
      
      // 4. Save to local database
      await _saveArticlesToLocal(articles);
      
      return articles;
    } catch (e) {
      // 5. Network failed, return local data as fallback
      return localArticles.map((doc) => Article.fromDocument(doc)).toList();
    }
  }
  
  Future<void> _syncArticlesInBackground() async {
    try {
      final response = await _network.get('/articles');
      final articles = (response.data as List)
          .map((json) => Article.fromJson(json))
          .toList();
      
      await _saveArticlesToLocal(articles);
    } catch (e) {
      // Sync failed, but that's ok for background sync
      print('Background sync failed: $e');
    }
  }
  
  Future<void> _saveArticlesToLocal(List<Article> articles) async {
    for (final article in articles) {
      await _db.create('articles', article.toJson());
    }
  }
}
```

## 🎨 UI Patterns

### Adaptive Form Pattern
```dart
class AdaptiveForm extends StatefulWidget {
  @override
  _AdaptiveFormState createState() => _AdaptiveFormState();
}

class _AdaptiveFormState extends State<AdaptiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;
    
    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('Profile Form'),
        actions: [
          ui.textButton(
            label: 'Save',
            onPressed: _saveForm,
          ),
        ],
      ),
      body: ui.form(
        formKey: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ui.listSection(
              header: const Text('Personal Information'),
              children: [
                ui.textField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name required';
                    return null;
                  },
                ),
                ui.textField(
                  controller: _emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                ui.textField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ui.listSection(
              header: const Text('Preferences'),
              children: [
                ui.checkboxListTile(
                  title: const Text('Email Notifications'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value ?? false;
                    });
                  },
                ),
                ui.checkboxListTile(
                  title: const Text('Push Notifications'),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  
  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final ui = getAdaptiveFactory(context);
      
      // Save form data
      final formData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
      };
      
      // Show success message
      ui.showSnackBar(
        context: context,
        content: const Text('Profile saved successfully!'),
      );
    }
  }
}
```

### Responsive Layout Pattern
```dart
class ResponsiveDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout
            return _MobileLayout();
          } else if (constraints.maxWidth < 1200) {
            // Tablet layout
            return _TabletLayout();
          } else {
            // Desktop layout
            return _DesktopLayout();
          }
        },
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderCard(),
        Expanded(
          child: ListView(
            children: [
              _StatsCard(),
              _RecentActivityCard(),
              _QuickActionsCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderCard(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _StatsCard(),
                    _RecentActivityCard(),
                  ],
                ),
              ),
              Expanded(
                child: _QuickActionsCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              _HeaderCard(),
              _QuickActionsCard(),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _StatsCard(),
              Expanded(child: _RecentActivityCard()),
            ],
          ),
        ),
      ],
    );
  }
}
```

## 🧭 Navigation Patterns

### Tab Navigation with State Preservation
```dart
class MainTabScreen extends StatefulWidget {
  @override
  _MainTabScreenState createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _screens.length,
      vsync: this,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      body: TabBarView(
        controller: _tabController,
        children: _screens.map((screen) => 
          // Preserve state using AutomaticKeepAliveClientMixin
          _KeepAliveWrapper(child: screen)
        ).toList(),
      ),
      bottomNavBar: ui.tabBar(
        controller: _tabController,
        tabs: [
          Tab(icon: Icon(Icons.home), text: 'Home'),
          Tab(icon: Icon(Icons.search), text: 'Search'),
          Tab(icon: Icon(Icons.person), text: 'Profile'),
          Tab(icon: Icon(Icons.settings), text: 'Settings'),
        ],
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const _KeepAliveWrapper({required this.child});
  
  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
```

### Deep Linking Pattern
```dart
class DeepLinkHandler {
  static void handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final navigation = getIt<NavigationService>();
    
    switch (uri.pathSegments.first) {
      case 'article':
        final articleId = uri.pathSegments.length > 1 
            ? uri.pathSegments[1] 
            : null;
        if (articleId != null) {
          navigation.goToPath('/article/$articleId');
        }
        break;
        
      case 'user':
        final userId = uri.pathSegments.length > 1 
            ? uri.pathSegments[1] 
            : null;
        if (userId != null) {
          navigation.goToPath('/profile/$userId');
        }
        break;
        
      case 'settings':
        final section = uri.queryParameters['section'];
        navigation.goToPath('/settings${section != null ? '?section=$section' : ''}');
        break;
        
      default:
        navigation.goToPath('/');
    }
  }
}

// Usage in main.dart
void main() {
  runShellApp(() async {
    // Handle app launch from deep link
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      DeepLinkHandler.handleDeepLink(initialLink);
    }
    
    // Listen for incoming links while app is running
    getLinksStream().listen((String link) {
      DeepLinkHandler.handleDeepLink(link);
    });
    
    return AppConfig(
      title: 'My App',
      routes: [...],
    );
  });
}
```

## 🔧 Service Integration Patterns

### Service Composition Pattern
```dart
class UserManager {
  final AuthenticationService _auth = getIt<AuthenticationService>();
  final DatabaseService _db = getIt<DatabaseService>();
  final FileStorageService _storage = getIt<FileStorageService>();
  final NetworkService _network = getIt<NetworkService>();
  
  // Signals for reactive state
  final _userProfile = signal<UserProfile?>(null);
  final _isLoading = signal(false);
  
  Signal<UserProfile?> get userProfile => _userProfile;
  Signal<bool> get isLoading => _isLoading;
  
  UserManager() {
    // React to authentication changes
    effect(() {
      final user = _auth.currentUser.value;
      if (user != null) {
        _loadUserProfile(user.id);
      } else {
        _userProfile.value = null;
      }
    });
  }
  
  Future<void> _loadUserProfile(String userId) async {
    _isLoading.value = true;
    
    try {
      // Try local first
      final localProfile = await _db.findById('user_profiles', userId);
      if (localProfile != null) {
        _userProfile.value = UserProfile.fromDocument(localProfile);
      }
      
      // Sync from cloud in background
      _syncProfileFromCloud(userId);
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<void> _syncProfileFromCloud(String userId) async {
    try {
      final response = await _network.get('/users/$userId/profile');
      final profileData = response.data;
      
      // Save to local database
      await _db.update('user_profiles', userId, profileData);
      
      // Update reactive state
      _userProfile.value = UserProfile.fromJson(profileData);
    } catch (e) {
      // Background sync failed, but local data is still available
      print('Profile sync failed: $e');
    }
  }
  
  Future<void> updateAvatar(File imageFile) async {
    _isLoading.value = true;
    
    try {
      final user = _auth.currentUser.value;
      if (user == null) throw Exception('Not authenticated');
      
      // Upload image to storage
      final result = await _storage.uploadFile(
        file: imageFile,
        folder: 'avatars',
        fileName: 'avatar_${user.id}.jpg',
      );
      
      // Update user profile with new avatar URL
      await _db.update('user_profiles', user.id, {
        'avatarUrl': result.publicUrl,
      });
      
      // Sync to cloud
      await _network.put('/users/${user.id}/profile', {
        'avatarUrl': result.publicUrl,
      });
      
      // Update local state
      final currentProfile = _userProfile.value;
      if (currentProfile != null) {
        _userProfile.value = currentProfile.copyWith(
          avatarUrl: result.publicUrl,
        );
      }
    } catch (e) {
      throw Exception('Failed to update avatar: $e');
    } finally {
      _isLoading.value = false;
    }
  }
}
```

### Event-Driven Service Communication
```dart
class EventBus {
  static final _instance = EventBus._();
  static EventBus get instance => _instance;
  EventBus._();
  
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get events => _controller.stream;
  
  void emit(AppEvent event) {
    _controller.add(event);
  }
  
  Stream<T> on<T extends AppEvent>() {
    return events.where((event) => event is T).cast<T>();
  }
}

abstract class AppEvent {}

class UserLoggedInEvent extends AppEvent {
  final User user;
  UserLoggedInEvent(this.user);
}

class DocumentCreatedEvent extends AppEvent {
  final Document document;
  DocumentCreatedEvent(this.document);
}

// Services listen for events
class NotificationService {
  void initialize() {
    EventBus.instance.on<UserLoggedInEvent>().listen((event) {
      _sendWelcomeNotification(event.user);
    });
    
    EventBus.instance.on<DocumentCreatedEvent>().listen((event) {
      _notifyDocumentCreated(event.document);
    });
  }
}

// Services emit events
class AuthenticationService {
  Future<void> signIn(String email, String password) async {
    final user = await _performSignIn(email, password);
    _currentUser.value = user;
    
    // Emit event for other services
    EventBus.instance.emit(UserLoggedInEvent(user));
  }
}
```

## 🚀 Performance Patterns

### Lazy Loading Pattern
```dart
class LazyListScreen extends StatefulWidget {
  @override
  _LazyListScreenState createState() => _LazyListScreenState();
}

class _LazyListScreenState extends State<LazyListScreen> {
  final List<Article> _articles = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  
  @override
  void initState() {
    super.initState();
    _loadMoreArticles();
  }
  
  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      appBar: ui.appBar(title: const Text('Articles')),
      body: ListView.builder(
        itemCount: _articles.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _articles.length) {
            // Load more indicator
            _loadMoreArticles();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _ArticleTile(article: _articles[index]);
        },
      ),
    );
  }
  
  Future<void> _loadMoreArticles() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final network = getIt<NetworkService>();
      final response = await network.get('/articles', queryParameters: {
        'page': _page,
        'limit': 20,
      });
      
      final newArticles = (response.data['articles'] as List)
          .map((json) => Article.fromJson(json))
          .toList();
      
      setState(() {
        _articles.addAll(newArticles);
        _page++;
        _hasMore = newArticles.length == 20; // Assume 20 per page
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }
}
```

### Caching Pattern
```dart
class CachedDataService {
  final NetworkService _network = getIt<NetworkService>();
  final Map<String, CacheEntry> _cache = {};
  final Duration _cacheDuration = Duration(minutes: 5);
  
  Future<T> getCachedData<T>(
    String key,
    Future<T> Function() fetcher,
    T Function(dynamic) parser,
  ) async {
    final entry = _cache[key];
    
    // Check if cache is valid
    if (entry != null && DateTime.now().isBefore(entry.expiry)) {
      return parser(entry.data);
    }
    
    // Fetch fresh data
    final freshData = await fetcher();
    
    // Cache the result
    _cache[key] = CacheEntry(
      data: freshData,
      expiry: DateTime.now().add(_cacheDuration),
    );
    
    return freshData;
  }
  
  void clearCache() {
    _cache.clear();
  }
  
  void removeCacheEntry(String key) {
    _cache.remove(key);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  CacheEntry({required this.data, required this.expiry});
}

// Usage
final dataService = CachedDataService();

final articles = await dataService.getCachedData(
  'articles_page_1',
  () => _network.get('/articles?page=1'),
  (data) => (data['articles'] as List)
      .map((json) => Article.fromJson(json))
      .toList(),
);
```

## 🔗 Related Documentation

- **[Getting Started](../getting-started.md)** - Basic setup and first app
- **[Architecture Overview](../architecture.md)** - Understanding the framework structure
- **[Services Documentation](../services/README.md)** - Detailed service guides
- **[UI Systems Guide](../ui-systems/README.md)** - Adaptive UI patterns
- **[Best Practices](../reference/best-practices.md)** - Framework-specific recommendations

These patterns provide a solid foundation for building robust, maintainable Flutter applications with App Shell. Mix and match them based on your specific needs, and don't hesitate to adapt them to your use case! 🚀