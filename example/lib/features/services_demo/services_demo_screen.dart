import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

class ServicesDemoScreen extends StatefulWidget {
  const ServicesDemoScreen({super.key});

  @override
  State<ServicesDemoScreen> createState() => _ServicesDemoScreenState();
}

class _ServicesDemoScreenState extends State<ServicesDemoScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _databaseResult = '';
  String _networkResult = '';
  String _authResult = '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return ui.scaffold(
        key: ValueKey('services_demo_scaffold_$uiSystem'),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Services Demo',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Test the advanced services in the app shell framework',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // Database Service Demo
            _buildServiceSection(
              ui: ui,
              title: 'Database Service',
              description: 'InstantDB with local-only or cloud-sync modes',
              result: _databaseResult,
              actions: [
                ui.button(
                  label: 'Test Database',
                  onPressed: _testDatabase,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Network Service Demo
            _buildServiceSection(
              ui: ui,
              title: 'Network Service',
              description: 'HTTP client with offline queueing and retry logic',
              result: _networkResult,
              actions: [
                ui.button(
                  label: 'Test Network',
                  onPressed: _testNetwork,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Authentication Service Demo
            _buildServiceSection(
              ui: ui,
              title: 'Authentication Service',
              description: 'User authentication with token management',
              result: _authResult,
              child: Watch((context) {
                final authService = getIt<AuthenticationService>();
                final isAuthenticated = authService.isAuthenticated.value;
                final currentUser = authService.currentUser.value;

                if (isAuthenticated && currentUser != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ui.listTile(
                        leading: const Icon(Icons.person),
                        title: Text(currentUser.name),
                        subtitle: Text(currentUser.email),
                      ),
                      const SizedBox(height: 16),
                      ui.button(
                        label: 'Sign Out',
                        onPressed: _signOut,
                      ),
                    ],
                  );
                }

                return ui.form(
                  formKey: GlobalKey<FormState>(),
                  child: Column(
                    children: [
                      ui.textField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      ui.textField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      ui.textField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ui.button(
                            label: 'Sign Up',
                            onPressed: _isLoading ? () {} : () => _signUp(),
                          ),
                          ui.textButton(
                            label: 'Sign In',
                            onPressed: _isLoading ? () {} : () => _signIn(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Service Statistics
            _buildServiceStats(ui),
          ],
        ),
      );
    });
  }

  Widget _buildServiceSection({
    required AdaptiveWidgetFactory ui,
    required String title,
    required String description,
    required String result,
    List<Widget>? actions,
    Widget? child,
  }) {
    return ui.listSection(
      header: Text(title),
      children: [
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (result.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: 16),
                  child,
                ],
                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceStats(AdaptiveWidgetFactory ui) {
    return ui.listSection(
      header: const Text('Service Statistics'),
      children: [
        ui.card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time service status and statistics',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Watch((context) {
                  final dbService = getIt<DatabaseService>();
                  final networkService = getIt<NetworkService>();
                  final authService = getIt<AuthenticationService>();
                  final prefsService = getIt<PreferencesService>();

                  return Column(
                    children: [
                      _buildStatRow(
                          'Database', dbService.connectionStatus.value.name),
                      _buildStatRow('Network',
                          networkService.connectionStatus.value.name),
                      _buildStatRow(
                          'Authentication',
                          authService.isAuthenticated.value
                              ? 'Authenticated'
                              : 'Not authenticated'),
                      _buildStatRow('Preferences',
                          '${prefsService.getStats().totalKeys} keys'),
                      _buildStatRow('Network Queue',
                          '${networkService.queueSize.value} requests'),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _testDatabase() async {
    setState(() => _databaseResult = 'Testing database...');

    try {
      final dbService = getIt<DatabaseService>();

      // Create a test document
      final docId = await dbService.create('demo', {
        'title': 'Test Document',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'count': 1, 'active': true},
      });

      // Read it back
      final doc = await dbService.read('demo', docId);

      // Update it
      await dbService.update('demo', docId, {
        'title': 'Updated Document',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'count': 2, 'active': true},
      });

      // Get statistics
      final stats = await dbService.getStats();

      setState(() {
        _databaseResult = '''✅ Database test successful!
Created document ID: $docId
Document title: ${doc?['title']}
Database stats: ${stats.totalDocuments} total docs, ${stats.totalCollections} collections
Connection: ${stats.connectionStatus.name}
Sync Status: ${stats.syncStatus.name}
Real-time updates: ${stats.realtimeUpdates}
Authenticated: ${stats.isAuthenticated}''';
      });
    } catch (e) {
      setState(() => _databaseResult = '❌ Database test failed: $e');
    }
  }

  Future<void> _testNetwork() async {
    setState(() => _networkResult = 'Testing network...');

    try {
      final networkService = getIt<NetworkService>();

      // Test a simple GET request to a public API
      final response = await networkService.get<Map<String, dynamic>>(
          'https://jsonplaceholder.typicode.com/posts/1');

      if (response.success && response.data != null) {
        final post = response.data!;
        setState(() {
          _networkResult = '''✅ Network test successful!
Status: ${response.statusCode}
Post title: ${post['title']}
Post body: ${post['body']?.toString().substring(0, 50)}...
Network status: ${networkService.isOnline ? 'Online' : 'Offline'}''';
        });
      } else {
        setState(() {
          _networkResult = '''❌ Network test failed!
Error: ${response.error?.message ?? 'Unknown error'}
Status: ${response.statusCode ?? 'N/A'}''';
        });
      }
    } catch (e) {
      setState(() => _networkResult = '❌ Network test failed: $e');
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.trim().isEmpty) {
      setState(() => _authResult = '❌ Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _authResult = 'Creating account...';
    });

    try {
      final authService = getIt<AuthenticationService>();
      final result = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (result.success) {
        _clearControllers();
        setState(() => _authResult = '✅ Account created successfully!');
      } else {
        setState(() => _authResult = '❌ Sign up failed: ${result.error}');
      }
    } catch (e) {
      setState(() => _authResult = '❌ Sign up failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _authResult = '❌ Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _authResult = 'Signing in...';
    });

    try {
      final authService = getIt<AuthenticationService>();
      final result = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result.success) {
        _clearControllers();
        setState(() => _authResult = '✅ Signed in successfully!');
      } else {
        setState(() => _authResult = '❌ Sign in failed: ${result.error}');
      }
    } catch (e) {
      setState(() => _authResult = '❌ Sign in failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = getIt<AuthenticationService>();
      await authService.signOut();
      setState(() => _authResult = '✅ Signed out successfully!');
    } catch (e) {
      setState(() => _authResult = '❌ Sign out failed: $e');
    }
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
