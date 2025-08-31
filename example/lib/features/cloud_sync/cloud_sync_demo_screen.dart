import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'dart:math';

/// Demo screen showcasing offline-first architecture with cloud sync
class CloudSyncDemoScreen extends StatefulWidget {
  const CloudSyncDemoScreen({super.key});

  @override
  State<CloudSyncDemoScreen> createState() => _CloudSyncDemoScreenState();
}

class _CloudSyncDemoScreenState extends State<CloudSyncDemoScreen> {
  late DatabaseService _databaseService;

  bool _isAuthenticated = false;

  // Demo data
  final List<Map<String, dynamic>> _localDocuments = [];
  String _syncStatus = 'Not initialized';
  String? _lastMessage;
  DateTime? _messageTime;

  @override
  void initState() {
    super.initState();
    _initializeServices();

    // Set up periodic refresh for reactive updates
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _startPeriodicRefresh();
      }
    });
  }

  void _startPeriodicRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;

      setState(() {
        _isAuthenticated = _databaseService.isAuthenticated;
        _syncStatus =
            _databaseService.syncStatus.value.toString().split('.').last;
      });

      return mounted;
    });
  }

  Future<void> _initializeServices() async {
    try {
      _databaseService = getIt<DatabaseService>();

      // Check initial auth state
      _isAuthenticated = _databaseService.isAuthenticated;

      // Check initial sync status
      _syncStatus =
          _databaseService.syncStatus.value.toString().split('.').last;

      _loadData();
    } catch (e) {
      // Don't show message during initState, just log it
      print('[Cloud Sync Demo] Failed to initialize services: $e');
      // Schedule the message to be shown after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage('Failed to initialize services: $e');
      });
    }
  }

  Future<void> _enableCloudSync() async {
    try {
      _showMessage('Cloud sync is managed through InstantDB configuration.');
      _showMessage(
          'To enable cloud sync, configure INSTANTDB_APP_ID in your .env file');
    } catch (e) {
      _showMessage('Failed to show cloud sync info: $e');
    }
  }

  Future<void> _signIn() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: '••••••',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = await _databaseService.signIn(
          email: emailController.text,
          password: passwordController.text,
        );

        if (user != null) {
          _showMessage('Signed in successfully!');
          _loadData();
        } else {
          _showMessage('Sign in failed');
        }
      } catch (e) {
        _showMessage('Sign in failed: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _databaseService.signOut();
      _showMessage('Signed out successfully');
      _loadData();
    } catch (e) {
      _showMessage('Sign out failed: $e');
    }
  }

  Future<void> _createDocument() async {
    final random = Random();
    final doc = {
      'title': 'Document ${random.nextInt(1000)}',
      'content': 'This is a sample document created at ${DateTime.now()}',
      'value': random.nextInt(100),
      'tags': ['demo', 'test'],
    };

    try {
      final id = await _databaseService.create('demo_document', doc);

      _showMessage('Document created with ID: $id');
      _loadData();
    } catch (e) {
      _showMessage('Failed to create document: $e');
    }
  }

  Future<void> _updateDocument(String id) async {
    final random = Random();
    final updatedData = {
      'title': 'Updated Document ${random.nextInt(1000)}',
      'content': 'This document was updated at ${DateTime.now()}',
      'value': random.nextInt(100),
      'lastModified': DateTime.now().toIso8601String(),
    };

    try {
      final success =
          await _databaseService.update('demo_document', id, updatedData);
      if (success) {
        _showMessage('Document updated successfully');
        _loadData();
      } else {
        _showMessage('Document not found');
      }
    } catch (e) {
      _showMessage('Failed to update document: $e');
    }
  }

  Future<void> _deleteDocument(String id) async {
    try {
      final success = await _databaseService.delete('demo_document', id);
      if (success) {
        _showMessage('Document deleted successfully');
        _loadData();
      } else {
        _showMessage('Document not found');
      }
    } catch (e) {
      _showMessage('Failed to delete document: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      // Load documents
      final docs = await _databaseService.findAll('demo_document');

      setState(() {
        _localDocuments.clear();
        _localDocuments.addAll(docs);
      });
    } catch (e) {
      _showMessage('Failed to load data: $e');
    }
  }

  Future<void> _syncNow() async {
    if (_databaseService.syncStatus.value == SyncStatus.disconnected) {
      _showMessage('Cloud sync is not enabled');
      return;
    }

    try {
      _showMessage('InstantDB handles real-time sync automatically!');
      _loadData();
    } catch (e) {
      _showMessage('Sync failed: $e');
    }
  }

  void _showMessage(String message) {
    // Defer showing message until after the current build
    if (!mounted) return;

    setState(() {
      _lastMessage = message;
      _messageTime = DateTime.now();
    });

    print('[Cloud Sync Demo] $message');

    // Auto-hide message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _lastMessage == message) {
        setState(() {
          _lastMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final theme = Theme.of(context);
      final ui = getAdaptiveFactory(context);

      return Scaffold(
        key: ValueKey('cloud_sync_scaffold_$uiSystem'),
        appBar: AppBar(
          title: const Text('Cloud Sync Demo'),
          actions: [
            if (_isAuthenticated)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
                tooltip: 'Sign Out',
              ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message display
                  if (_lastMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),

                  // Status Card
                  ui.card(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                            'Cloud Sync',
                            _databaseService.syncStatus.value ==
                                    SyncStatus.connected
                                ? 'Enabled'
                                : 'Local-only'),
                        _buildStatusRow('Authentication',
                            _isAuthenticated ? 'Signed In' : 'Not Signed In'),
                        _buildStatusRow('Sync Status', _syncStatus),
                        _buildStatusRow(
                            'Documents', '${_localDocuments.length} local'),
                        if (_databaseService.lastSyncTime.value != null)
                          _buildStatusRow(
                            'Last Sync',
                            _formatTime(_databaseService.lastSyncTime.value!),
                          ),
                        if (_databaseService.realtimeUpdates.value > 0)
                          _buildStatusRow(
                            'Real-time Updates',
                            '${_databaseService.realtimeUpdates.value} received',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  Text(
                    'Actions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Cloud Setup info
                  if (_databaseService.syncStatus.value ==
                      SyncStatus.disconnected) ...[
                    ui.button(
                      label: 'Cloud Sync Info',
                      onPressed: _enableCloudSync,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Authentication
                  if (_databaseService.syncStatus.value ==
                          SyncStatus.connected &&
                      !_isAuthenticated) ...[
                    ui.button(
                      label: 'Sign In',
                      onPressed: _signIn,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Database Operations
                  ui.button(
                    label: 'Create Document',
                    onPressed: _createDocument,
                  ),
                  const SizedBox(height: 8),
                  if (_databaseService.syncStatus.value == SyncStatus.connected)
                    ui.button(
                      label: 'Real-time Sync Info',
                      onPressed: _syncNow,
                    ),

                  const SizedBox(height: 24),

                  // Documents List
                  if (_localDocuments.isNotEmpty) ...[
                    Text(
                      'Documents (${_localDocuments.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._localDocuments.map((doc) => ui.card(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      doc['title'] ?? 'Untitled',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${doc['_id']}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doc['content'] ?? '',
                                style: theme.textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'v${doc['_version']} • ${_formatTime(DateTime.parse(doc['_updatedAt']))}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () =>
                                        _updateDocument(doc['_id'] ?? ''),
                                    tooltip: 'Update',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () =>
                                        _deleteDocument(doc['_id'] ?? ''),
                                    tooltip: 'Delete',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ], // End of documents list
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
