import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:get_it/get_it.dart';

class ServiceInspectorScreen extends StatelessWidget {
  const ServiceInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();
    final styles = context.adaptiveStyle;

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final ui = getAdaptiveFactory(context);

      return ui.scaffold(
        key: ValueKey('service_inspector_scaffold_$uiSystem'),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.developer_board,
                    size: 32,
                    color: styles.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Inspector',
                          style: styles.headlineLarge,
                        ),
                        Text(
                          'Debug and monitor all registered services',
                          style: styles.bodyMedium.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ui.button(
                    label: 'Refresh All',
                    onPressed: () {
                      // Trigger a rebuild to refresh all service statuses
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Services and Plugins Tabs
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Material(
                        child: TabBar(
                          labelColor: styles.primary,
                          unselectedLabelColor: styles.onSurfaceVariant,
                          indicatorColor: styles.primary,
                          tabs: const [
                            Tab(text: 'Core Services'),
                            Tab(text: 'Plugins'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildServiceGrid(context, ui, styles),
                            _buildPluginGrid(context, ui, styles),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildServiceGrid(BuildContext context, AdaptiveWidgetFactory ui,
      AdaptiveStyleProvider styles) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridCount(screenWidth);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Navigation Service',
          serviceType: NavigationService,
          icon: Icons.navigation,
          description: 'GoRouter-based navigation',
          actions: [
            ('Test Navigation', () => _testNavigationService()),
          ],
        ),
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Settings Store',
          serviceType: AppShellSettingsStore,
          icon: Icons.settings,
          description: 'App preferences & configuration',
          actions: [
            ('View Settings', () => _openSettingsDialog(context)),
          ],
        ),
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Preferences Service',
          serviceType: PreferencesService,
          icon: Icons.storage,
          description: 'SharedPreferences wrapper',
          actions: [
            ('View Stats', () => _showPreferencesStats(context)),
            ('Test Storage', () => _testPreferencesService()),
          ],
        ),
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Database Service',
          serviceType: DatabaseService,
          icon: Icons.storage,
          description: 'InstantDB with local-only or cloud-sync modes',
          actions: [
            ('Test CRUD', () => _testDatabaseService()),
            ('View Stats', () => _showDatabaseStats(context)),
          ],
        ),
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Network Service',
          serviceType: NetworkService,
          icon: Icons.cloud_outlined,
          description: 'HTTP client with offline queue',
          actions: [
            ('Test Request', () => _testNetworkService()),
            ('View Queue', () => _showNetworkQueue(context)),
          ],
        ),
        _buildServiceCard(
          context,
          ui,
          styles,
          title: 'Authentication',
          serviceType: AuthenticationService,
          icon: Icons.security,
          description: 'User auth & biometrics',
          actions: [
            ('Test Login', () => _testAuthService()),
            ('View Tokens', () => _showAuthDetails(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildPluginGrid(BuildContext context, AdaptiveWidgetFactory ui,
      AdaptiveStyleProvider styles) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getGridCount(screenWidth);

    // Check if PluginManager is available
    final isPluginManagerRegistered =
        GetIt.instance.isRegistered<PluginManager>();

    if (!isPluginManagerRegistered) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off,
              size: 64,
              color: styles.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Plugin System Not Available',
              style: styles.titleLarge.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The plugin system has not been initialized.',
              style: styles.bodyMedium.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ui.button(
              label: 'Learn More',
              onPressed: () => _showPluginSystemInfo(context),
            ),
          ],
        ),
      );
    }

    return Watch((context) {
      final pluginManager = getIt<PluginManager>();
      final allPlugins = pluginManager.registry.allPlugins;

      if (allPlugins.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.extension,
                size: 64,
                color: styles.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Plugins Loaded',
                style: styles.titleLarge.copyWith(
                  color: styles.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No plugins have been discovered or registered.',
                style: styles.bodyMedium.copyWith(
                  color: styles.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ui.button(
                label: 'Plugin Development Guide',
                onPressed: () => _showPluginDevelopmentInfo(context),
              ),
            ],
          ),
        );
      }

      return GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: allPlugins.map((plugin) {
          return _buildPluginCard(context, ui, styles, plugin);
        }).toList(),
      );
    });
  }

  int _getGridCount(double width) {
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildServiceCard(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles, {
    required String title,
    required Type serviceType,
    required IconData icon,
    required String description,
    required List<(String, VoidCallback)> actions,
  }) {
    final isRegistered = GetIt.instance.isRegistered(type: serviceType);
    final status = _getServiceStatus(serviceType);

    return ui.card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: _getStatusColor(status, styles),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: styles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(status, styles),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(status, isRegistered),
                          style: styles.bodySmall.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: styles.bodySmall.copyWith(
              color: styles.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Action buttons
          if (isRegistered && actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((action) {
                return ui.outlinedButton(
                  label: action.$1,
                  onPressed: action.$2,
                );
              }).toList(),
            ),
          ] else if (!isRegistered) ...[
            const SizedBox(height: 16),
            Text(
              'Service not registered',
              style: styles.bodySmall.copyWith(
                color: styles.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ServiceStatus _getServiceStatus(Type serviceType) {
    if (!GetIt.instance.isRegistered(type: serviceType)) {
      return ServiceStatus.notRegistered;
    }

    try {
      final service = GetIt.instance.get(type: serviceType);

      // Check specific service types for their status
      if (service is DatabaseService) {
        return service.isInitialized
            ? ServiceStatus.healthy
            : ServiceStatus.initializing;
      } else if (service is NetworkService) {
        return service.isInitialized
            ? ServiceStatus.healthy
            : ServiceStatus.initializing;
      } else if (service is AuthenticationService) {
        return service.isInitialized
            ? ServiceStatus.healthy
            : ServiceStatus.initializing;
      } else if (service is PreferencesService) {
        return service.isInitialized
            ? ServiceStatus.healthy
            : ServiceStatus.initializing;
      }

      // For other services, assume healthy if we can get them
      return ServiceStatus.healthy;
    } catch (e) {
      return ServiceStatus.error;
    }
  }

  Color _getStatusColor(ServiceStatus status, AdaptiveStyleProvider styles) {
    switch (status) {
      case ServiceStatus.healthy:
        return Colors.green;
      case ServiceStatus.initializing:
        return Colors.orange;
      case ServiceStatus.error:
        return styles.error;
      case ServiceStatus.notRegistered:
        return styles.onSurfaceVariant;
    }
  }

  String _getStatusText(ServiceStatus status, bool isRegistered) {
    if (!isRegistered) return 'Not Registered';

    switch (status) {
      case ServiceStatus.healthy:
        return 'Healthy';
      case ServiceStatus.initializing:
        return 'Initializing';
      case ServiceStatus.error:
        return 'Error';
      case ServiceStatus.notRegistered:
        return 'Not Registered';
    }
  }

  // Service testing methods
  void _testNavigationService() {
    final nav = getIt<NavigationService>();
    AppShellLogger.i(
        'Testing NavigationService: Current path: ${nav.currentPath}');
  }

  void _openSettingsDialog(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final settingsStore = getIt<AppShellSettingsStore>();

    ui.showDialog(
      context: context,
      title: const Text('Current Settings'),
      content: Watch((context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme Mode: ${settingsStore.themeMode.value}'),
            Text('UI System: ${settingsStore.uiSystem.value}'),
            Text('Debug Mode: ${settingsStore.debugMode.value}'),
            Text('Log Level: ${settingsStore.logLevel.value}'),
            Text(
                'Show Nav Labels: ${settingsStore.showNavigationLabels.value}'),
            Text('Sidebar Collapsed: ${settingsStore.sidebarCollapsed.value}'),
          ],
        );
      }),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            // Use the root navigator to safely close the dialog
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _showPreferencesStats(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final prefs = getIt<PreferencesService>();
    final stats = prefs.getStats();

    ui.showDialog(
      context: context,
      title: const Text('Preferences Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Keys: ${stats.totalKeys}'),
          Text('String Keys: ${stats.stringKeys}'),
          Text('Bool Keys: ${stats.boolKeys}'),
          Text('Int Keys: ${stats.intKeys}'),
          Text('Double Keys: ${stats.doubleKeys}'),
          Text('List Keys: ${stats.listKeys}'),
          Text('Reactive Signals: ${stats.reactiveSignals}'),
        ],
      ),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            // Use the root navigator to safely close the dialog
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _testPreferencesService() {
    final prefs = getIt<PreferencesService>();
    final testKey = 'service_inspector_test';
    final testValue = 'Test value ${DateTime.now().millisecondsSinceEpoch}';

    prefs.setString(testKey, testValue);
    final retrieved = prefs.getString(testKey).value;

    AppShellLogger.i(
        'PreferencesService test: Stored "$testValue", Retrieved "$retrieved"');
  }

  void _testDatabaseService() async {
    try {
      final db = getIt<DatabaseService>();
      final testData = {
        'message': 'Service inspector test',
        'timestamp': DateTime.now().toIso8601String(),
        'count': 42,
      };

      final id = await db.create('test_collection', testData);
      final retrieved = await db.read('test_collection', id);

      AppShellLogger.i(
          'DatabaseService test: Created document $id, Retrieved: $retrieved');
    } catch (e) {
      AppShellLogger.e('DatabaseService test failed', e);
    }
  }

  void _showDatabaseStats(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final db = getIt<DatabaseService>();

    ui.showDialog(
      context: context,
      title: const Text('Database Statistics'),
      content: FutureBuilder(
        future: db.getStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const Text('No data available');
          }

          final stats = snapshot.data!;
          return Watch((context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection: ${db.connectionStatus.value.name}'),
                Text('Sync Status: ${db.syncStatus.value.name}'),
                Text('Authenticated: ${stats.isAuthenticated}'),
                Text('Total Documents: ${stats.totalDocuments}'),
                Text('Total Collections: ${stats.totalCollections}'),
                Text('Real-time Updates: ${db.realtimeUpdates.value}'),
                if (db.lastSyncTime.value != null)
                  Text('Last Sync: ${db.lastSyncTime.value}'),
                const SizedBox(height: 16),
                const Text('Features:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Real-time synchronization'),
                const Text('• Built-in authentication'),
                const Text('• Offline-first storage'),
                const Text('• Reactive queries'),
                const Text('• Local-only or cloud-sync modes'),
              ],
            );
          });
        },
      ),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _testNetworkService() async {
    try {
      final network = getIt<NetworkService>();
      final response = await network.get('https://httpbin.org/json');

      AppShellLogger.i(
          'NetworkService test successful: ${response.statusCode}');
    } catch (e) {
      AppShellLogger.e('NetworkService test failed', e);
    }
  }

  void _showNetworkQueue(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final network = getIt<NetworkService>();

    ui.showDialog(
      context: context,
      title: const Text('Network Queue Status'),
      content: Watch((context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection Status: ${network.connectionStatus.value}'),
            const Text('Queue details coming soon...'),
            const SizedBox(height: 16),
            const Text('Recent activity will be shown here...'),
          ],
        );
      }),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            // Use the root navigator to safely close the dialog
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _testAuthService() async {
    try {
      final auth = getIt<AuthenticationService>();
      final isAuthenticated = auth.isAuthenticated.value;

      if (!isAuthenticated) {
        // Test login with demo credentials
        await auth.signIn('demo@example.com', 'password123');
        AppShellLogger.i('AuthenticationService test: Login successful');
      } else {
        AppShellLogger.i('AuthenticationService test: Already authenticated');
      }
    } catch (e) {
      AppShellLogger.e('AuthenticationService test failed', e);
    }
  }

  void _showAuthDetails(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final auth = getIt<AuthenticationService>();

    ui.showDialog(
      context: context,
      title: const Text('Authentication Details'),
      content: Watch((context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Is Authenticated: ${auth.isAuthenticated.value}'),
            Text('Current User: ${auth.currentUser.value?.email ?? 'None'}'),
            Text('Biometric Available: ${auth.biometricAvailable.value}'),
            const SizedBox(height: 16),
            if (auth.currentUser.value != null)
              const Text(
                  'Token details and session info would be shown here...')
            else
              const Text('No active session'),
          ],
        );
      }),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            // Use the root navigator to safely close the dialog
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  Widget _buildPluginCard(
    BuildContext context,
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    BasePlugin plugin,
  ) {
    final state = getIt<PluginManager>().registry.getPluginState(plugin.id) ??
        PluginState.unloaded;
    final icon = _getPluginIcon(plugin.type);

    return ui.card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with plugin type badge
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: _getPluginStateColor(state, styles),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plugin.name,
                            style: styles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: styles.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            plugin.type.name.toUpperCase(),
                            style: styles.labelSmall.copyWith(
                              color: styles.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPluginStateColor(state, styles),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPluginStateText(state),
                          style: styles.bodySmall.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'v${plugin.version}',
                          style: styles.bodySmall.copyWith(
                            color: styles.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            plugin.description,
            style: styles.bodySmall.copyWith(
              color: styles.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Author
          if (plugin.author.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'by ${plugin.author}',
              style: styles.bodySmall.copyWith(
                color: styles.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const Spacer(),

          // Action buttons
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ui.outlinedButton(
                label: 'Details',
                onPressed: () => _showPluginDetails(context, plugin),
              ),
              if (state == PluginState.ready)
                ui.outlinedButton(
                  label: 'Health Check',
                  onPressed: () => _performPluginHealthCheck(plugin),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPluginIcon(PluginType type) {
    switch (type) {
      case PluginType.service:
        return Icons.api;
      case PluginType.widget:
        return Icons.widgets;
      case PluginType.theme:
        return Icons.palette;
      case PluginType.workflow:
        return Icons.auto_awesome;
    }
  }

  Color _getPluginStateColor(PluginState state, AdaptiveStyleProvider styles) {
    switch (state) {
      case PluginState.ready:
        return Colors.green;
      case PluginState.loading:
      case PluginState.initializing:
        return Colors.orange;
      case PluginState.error:
        return styles.error;
      case PluginState.unloaded:
      case PluginState.disposed:
        return styles.onSurfaceVariant;
      case PluginState.loaded:
        return Colors.blue;
      case PluginState.disposing:
        return Colors.grey;
    }
  }

  String _getPluginStateText(PluginState state) {
    switch (state) {
      case PluginState.unloaded:
        return 'Unloaded';
      case PluginState.loading:
        return 'Loading';
      case PluginState.loaded:
        return 'Loaded';
      case PluginState.initializing:
        return 'Initializing';
      case PluginState.ready:
        return 'Ready';
      case PluginState.error:
        return 'Error';
      case PluginState.disposing:
        return 'Disposing';
      case PluginState.disposed:
        return 'Disposed';
    }
  }

  void _showPluginDetails(BuildContext context, BasePlugin plugin) {
    final ui = getAdaptiveFactory(context);
    final manager = getIt<PluginManager>();
    final state =
        manager.registry.getPluginState(plugin.id) ?? PluginState.unloaded;
    final status = plugin.getStatus();

    ui.showDialog(
      context: context,
      title: Text('Plugin: ${plugin.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', plugin.id),
            _buildDetailRow('Version', plugin.version),
            _buildDetailRow('Author', plugin.author),
            _buildDetailRow('Type', plugin.type.name),
            _buildDetailRow('State', _getPluginStateText(state)),
            _buildDetailRow('Min App Shell Version', plugin.minAppShellVersion),
            if (plugin.dependencies.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Dependencies:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...plugin.dependencies.map((dep) => Text('• $dep')),
            ],
            const SizedBox(height: 12),
            const Text('Status Details:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...status.entries
                .map((entry) => Text('${entry.key}: ${entry.value}')),
            const SizedBox(height: 12),
            const Text('Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(plugin.description),
          ],
        ),
      ),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _performPluginHealthCheck(BasePlugin plugin) async {
    try {
      final isHealthy = await plugin.healthCheck();
      AppShellLogger.i(
          'Plugin ${plugin.name} health check: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');
    } catch (e) {
      AppShellLogger.e('Plugin ${plugin.name} health check failed', e);
    }
  }

  void _showPluginSystemInfo(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    ui.showDialog(
      context: context,
      title: const Text('Plugin System'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Flutter App Shell Plugin System extends the framework with:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          Text(
              '• Service Plugins - Third-party business logic and data access'),
          Text('• Widget Extensions - Custom adaptive UI components'),
          Text('• Theme Plugins - Custom UI systems and styling'),
          Text('• Workflow Plugins - Automation and background processing'),
          SizedBox(height: 12),
          Text(
              'To enable plugins, initialize App Shell with enablePlugins: true'),
        ],
      ),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }

  void _showPluginDevelopmentInfo(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    ui.showDialog(
      context: context,
      title: const Text('Plugin Development'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create plugins by implementing plugin interfaces:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          Text('• ServicePlugin - for business logic services'),
          Text('• WidgetExtensionPlugin - for UI components'),
          Text('• ThemePlugin - for custom themes'),
          Text('• WorkflowPlugin - for automation'),
          SizedBox(height: 12),
          Text(
              'Plugins are auto-discovered from dependencies or manually registered.'),
        ],
      ),
      actions: [
        ui.textButton(
          label: 'Close',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    );
  }
}

enum ServiceStatus {
  healthy,
  initializing,
  error,
  notRegistered,
}
