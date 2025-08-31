import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/di/service_locator.dart';
import '../../services/cloud_storage_service.dart';
import '../../services/auth_service.dart';

class CloudStorageScreen extends StatefulWidget {
  const CloudStorageScreen({super.key});

  @override
  State<CloudStorageScreen> createState() => _CloudStorageScreenState();
}

class _CloudStorageScreenState extends State<CloudStorageScreen> {
  late final CloudStorageService _cloudStorageService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _cloudStorageService = getIt<CloudStorageService>();
    _authService = getIt<AuthService>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Watch((context) {
        final isEnabled = _cloudStorageService.isEnabled.value;
        final autoUpload = _cloudStorageService.autoUploadEnabled.value;
        final wifiOnly = _cloudStorageService.uploadOnWifiOnly.value;
        final isUploading = _cloudStorageService.isUploading.value;
        final queueLength = _cloudStorageService.uploadQueue.value.length;
        final completedUploads = _cloudStorageService.completedUploads.value;
        final isAuthenticated = _authService.isAuthenticated;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Authentication section
              if (!isAuthenticated) ...[
                _buildAuthenticationCard(),
                const SizedBox(height: 16),
              ],

              // Cloud storage settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upload Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enable cloud storage
                      SwitchListTile(
                        title: const Text('Enable Cloud Storage'),
                        subtitle:
                            const Text('Automatically backup videos to cloud'),
                        value: isEnabled,
                        onChanged: (value) {
                          _cloudStorageService.updateSettings(enabled: value);
                        },
                      ),

                      if (isEnabled) ...[
                        // Auto upload
                        SwitchListTile(
                          title: const Text('Auto Upload'),
                          subtitle: const Text(
                              'Automatically upload after recording'),
                          value: autoUpload,
                          onChanged: (value) {
                            _cloudStorageService.updateSettings(
                                autoUpload: value);
                          },
                        ),

                        // WiFi only
                        SwitchListTile(
                          title: const Text('WiFi Only'),
                          subtitle:
                              const Text('Only upload when connected to WiFi'),
                          value: wifiOnly,
                          onChanged: (value) {
                            _cloudStorageService.updateSettings(
                                wifiOnly: value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Upload status
              if (isEnabled) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUploading ? Icons.upload : Icons.cloud_done,
                              color: isUploading
                                  ? theme.colorScheme.primary
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Upload Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Queue status
                        ListTile(
                          leading: const Icon(Icons.queue),
                          title: const Text('Queue'),
                          subtitle: Text('$queueLength videos waiting'),
                          trailing: queueLength > 0
                              ? IconButton(
                                  icon: const Icon(Icons.clear_all),
                                  onPressed: () => _showClearQueueDialog(),
                                  tooltip: 'Clear queue',
                                )
                              : null,
                        ),

                        // Upload progress
                        if (isUploading) ...[
                          const Divider(),
                          ListTile(
                            leading: const CircularProgressIndicator(),
                            title: const Text('Uploading...'),
                            subtitle: LinearProgressIndicator(
                              value: _cloudStorageService.getOverallProgress(),
                            ),
                          ),
                        ],

                        // Completed uploads
                        ListTile(
                          leading: const Icon(Icons.cloud_done),
                          title: const Text('Completed'),
                          subtitle: Text(
                              '${completedUploads.length} videos uploaded'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Storage usage
                FutureBuilder<Map<String, dynamic>>(
                  future: _cloudStorageService.getStorageStats(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final stats = snapshot.data!;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.storage,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Storage Usage',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.video_library),
                                title: const Text('Videos'),
                                subtitle: Text('${stats['videoCount']} files'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.data_usage),
                                title: const Text('Total Size'),
                                subtitle: Text(stats['formattedSize']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              if (isEnabled) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            queueLength > 0 ? () => _processQueue() : null,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Now'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showManageCloudFiles(),
                        icon: const Icon(Icons.cloud),
                        label: const Text('Manage Files'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAuthenticationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sign In Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to your account to enable cloud storage and backup your videos.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showSignInDialog(),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => const _SignInDialog(),
    );
  }

  void _showClearQueueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Upload Queue'),
        content: const Text(
          'Are you sure you want to clear all pending uploads? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _cloudStorageService.clearAllUploads();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload queue cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _processQueue() async {
    // This will trigger upload processing
    _cloudStorageService.updateNetworkType('wifi'); // Simulate good network
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting uploads...')),
    );
  }

  void _showManageCloudFiles() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _CloudFilesScreen(),
      ),
    );
  }
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog();

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final authService = getIt<AuthService>();
      final isLoading = authService.isLoading.value;
      final errorMessage = authService.errorMessage.value;

      return AlertDialog(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
              });
              authService.clearError();
            },
            child: Text(_isSignUp ? 'Sign In Instead' : 'Create Account'),
          ),
          ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
          ),
        ],
      );
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = getIt<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isSignUp) {
      success = await authService.signUpWithEmail(
        email: email,
        password: password,
      );
    } else {
      success = await authService.signInWithEmail(
        email: email,
        password: password,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp
              ? 'Account created successfully!'
              : 'Signed in successfully!'),
        ),
      );
    }
  }
}

class _CloudFilesScreen extends StatelessWidget {
  const _CloudFilesScreen();

  @override
  Widget build(BuildContext context) {
    final cloudStorageService = getIt<CloudStorageService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Files'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: cloudStorageService.listCloudVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cloud files',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No cloud files found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: const Icon(Icons.video_file),
                title: Text(file['name'] ?? 'Unknown'),
                subtitle: Text(
                  'Size: ${_formatBytes(file['metadata']?['size'] ?? 0)}\n'
                  'Created: ${file['createdAt']?.toString() ?? 'Unknown'}',
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Download'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleFileAction(context, file, value.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleFileAction(
      BuildContext context, Map<String, dynamic> file, String action) {
    switch (action) {
      case 'download':
        // TODO: Implement download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download not yet implemented')),
        );
        break;
      case 'share':
        // TODO: Implement sharing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share not yet implemented')),
        );
        break;
      case 'delete':
        _showDeleteDialog(context, file);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete "${file['name'] ?? 'this file'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cloudStorageService = getIt<CloudStorageService>();
              final success =
                  await cloudStorageService.deleteFromCloud(file['name'] ?? '');

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'File deleted successfully'
                          : 'Failed to delete file',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(dynamic bytes) {
    final size = (bytes is int) ? bytes : (bytes as num?)?.toInt() ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
