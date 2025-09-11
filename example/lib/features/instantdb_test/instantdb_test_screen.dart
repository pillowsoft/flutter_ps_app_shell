import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

/// Comprehensive test screen for InstantDB query issues
/// This reproduces the exact bug reported by users and helps verify fixes
class InstantDBTestScreen extends StatefulWidget {
  const InstantDBTestScreen({super.key});

  @override
  State<InstantDBTestScreen> createState() => _InstantDBTestScreenState();
}

class _InstantDBTestScreenState extends State<InstantDBTestScreen> {
  final DatabaseService _db = GetIt.I<DatabaseService>();
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  
  // Test data IDs for cleanup
  final List<String> _testConversationIds = [];
  final List<String> _testMessageIds = [];
  
  // Reactive signals for UI updates - using simple signals to avoid computed cycles
  late final Signal<List<Map<String, dynamic>>> _conversations;
  late final Signal<List<Map<String, dynamic>>> _messages;
  late final Signal<bool> _isRunning;

  @override
  void initState() {
    super.initState();
    print('[InstantDBTest] initState: Starting signal initialization');
    
    try {
      // Initialize all signals with empty/default values
      _conversations = signal<List<Map<String, dynamic>>>([]);
      print('[InstantDBTest] initState: _conversations signal created');
      
      _messages = signal<List<Map<String, dynamic>>>([]);
      print('[InstantDBTest] initState: _messages signal created');
      
      _isRunning = signal(false);
      print('[InstantDBTest] initState: _isRunning signal created');
      
      print('[InstantDBTest] initState: All signals initialized successfully');
    } catch (e, stack) {
      print('[InstantDBTest] initState ERROR: $e');
      print('[InstantDBTest] initState STACK: $stack');
    }
  }

  void _addLog(String message) {
    // Use untracked to prevent logging from creating reactive dependencies
    untracked(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _logs.add('[$timestamp] $message');
      });
      
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  /// Diagnostic wrapper for safe signal reads with cycle detection
  T _safeSignalRead<T>(String location, T Function() reader) {
    try {
      return reader();
    } catch (e) {
      if (e.toString().contains('Cycle detected')) {
        _addLog('🔴 CYCLE DETECTED at: $location');
        _addLog('   Error: ${e.toString()}');
        if (e is Error) {
          final stackLines = e.stackTrace?.toString().split('\n').take(5).join('\n   ');
          _addLog('   Stack:\n   $stackLines');
        }
      }
      rethrow;
    }
  }

  Future<void> _createTestData() async {
    _addLog('🔧 Creating test data...');
    
    try {
      // Create test conversations
      final conv1Id = await _db.create('test_conversations', {
        'title': 'Test Conversation 1',
        'description': 'This is the first test conversation',
        'active': true,
        'priority': 1,
      });
      _testConversationIds.add(conv1Id);
      _addLog('✅ Created conversation 1: $conv1Id');
      
      final conv2Id = await _db.create('test_conversations', {
        'title': 'Test Conversation 2',
        'description': 'This is the second test conversation',
        'active': true,
        'priority': 2,
      });
      _testConversationIds.add(conv2Id);
      _addLog('✅ Created conversation 2: $conv2Id');
      
      // Create test messages
      final msg1Id = await _db.create('test_messages', {
        'conversationId': conv1Id,
        'content': 'Hello from conversation 1',
        'sender': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _testMessageIds.add(msg1Id);
      _addLog('✅ Created message 1: $msg1Id');
      
      final msg2Id = await _db.create('test_messages', {
        'conversationId': conv2Id,
        'content': 'Hello from conversation 2',
        'sender': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _testMessageIds.add(msg2Id);
      _addLog('✅ Created message 2: $msg2Id');
      
      final msg3Id = await _db.create('test_messages', {
        'conversationId': conv1Id,
        'content': 'Another message in conversation 1',
        'sender': 'assistant',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _testMessageIds.add(msg3Id);
      _addLog('✅ Created message 3: $msg3Id');
      
      _addLog('🎉 Test data created successfully');
      
    } catch (e, stackTrace) {
      _addLog('❌ Error creating test data: $e');
      _addLog('📚 Stack trace: ${stackTrace.toString().substring(0, 300)}...');
    }
  }

  Future<void> _testQueryMethods() async {
    _addLog('🔍 Testing query methods...');
    
    if (_testConversationIds.isEmpty) {
      _addLog('⚠️  No test data found. Creating test data first...');
      await _createTestData();
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for reactive updates
    }
    
    try {
      // Test 1: findAll (should work)
      _addLog('📋 Testing findAll...');
      final allConversations = await _db.findAll('test_conversations');
      _addLog('✅ findAll returned ${allConversations.length} conversations');
      
      // Update signal to reflect current data (batched to prevent cascading updates)
      batch(() {
        _conversations.value = allConversations;
      });
      
      // Test 2: read method (should work - this is our baseline)
      if (_testConversationIds.isNotEmpty) {
        _addLog('📖 Testing read method...');
        final readResult = await _db.read('test_conversations', _testConversationIds.first);
        _addLog('✅ read returned: ${readResult != null ? readResult['title'] : 'null'}');
      }
      
      // Test 3: findWhere with simple equality (THIS WAS THE BUG!)
      _addLog('🔍 Testing findWhere with simple equality...');
      final whereResult = await _db.findWhere('test_messages', {
        'conversationId': _testConversationIds.first
      });
      _addLog('📊 findWhere returned ${whereResult.length} messages');
      if (whereResult.isEmpty) {
        _addLog('❌ BUG DETECTED: findWhere returned 0 results despite data existing!');
      } else {
        _addLog('✅ findWhere working correctly!');
      }
      
      // Update messages signal with current data (batched to prevent cascading updates)
      final allMessages = await _db.findAll('test_messages');
      batch(() {
        _messages.value = allMessages;
      });
      
      // Test 4: findWhere with multiple conditions
      _addLog('🔍 Testing findWhere with multiple conditions...');
      final multiWhereResult = await _db.findWhere('test_messages', {
        'conversationId': _testConversationIds.first,
        'sender': 'user'
      });
      _addLog('📊 Multi-condition findWhere returned ${multiWhereResult.length} messages');
      
      // Test 5: findWhere with explicit $eq operator
      _addLog('🔍 Testing findWhere with explicit \$eq operator...');
      final explicitEqResult = await _db.findWhere('test_messages', {
        'conversationId': {'\$eq': _testConversationIds.first}
      });
      _addLog('📊 Explicit \$eq findWhere returned ${explicitEqResult.length} messages');
      
      // Test 6: watchWhere reactive query
      _addLog('👁️  Testing watchWhere reactive query...');
      
      // Create the watchWhere signal but don't read its value to avoid cycles
      // The act of reading a computed signal's value can trigger cycles even with untracked
      try {
        final watchSignal = _db.watchWhere('test_messages', {
          'conversationId': _testConversationIds.first
        });
        
        // Verify signal was created successfully without reading its value
        _addLog('✅ watchWhere signal created successfully');
        
        // Note: We can't safely read the signal value here without causing a cycle
        // In real usage, this signal would be used in a Watch widget which handles
        // the reactive context properly
        _addLog('📡 watchWhere returns Computed<List> signal for reactive UI updates');
      } catch (e) {
        _addLog('❌ Failed to create watchWhere signal: $e');
      }
      
      _addLog('🎉 Query method testing completed');
      
    } catch (e, stackTrace) {
      _addLog('❌ Error during query testing: $e');
      _addLog('📚 Stack trace: ${stackTrace.toString().substring(0, 300)}...');
    }
  }

  Future<void> _testCachePollution() async {
    _addLog('🚨 Testing for cache pollution...');
    
    try {
      // Get initial conversation count
      final initialConversations = await _db.findAll('test_conversations');
      final initialCount = initialConversations.length;
      _addLog('📊 Initial conversation count: $initialCount');
      
      // Perform operations that might cause cache pollution
      for (int i = 0; i < 3; i++) {
        _addLog('🔄 Cache pollution test iteration ${i + 1}...');
        
        // This should potentially trigger validation errors and retract events
        await _db.findWhere('test_messages', {
          'conversationId': _testConversationIds.isNotEmpty ? _testConversationIds.first : 'non-existent'
        });
        
        // Check if conversation count has decreased (indicates cache pollution)
        final currentConversations = await _db.findAll('test_conversations');
        final currentCount = currentConversations.length;
        _addLog('📊 After iteration ${i + 1}: $currentCount conversations');
        
        if (currentCount < initialCount) {
          _addLog('❌ CACHE POLLUTION DETECTED! Conversations disappeared from cache');
          _addLog('🔍 Lost ${initialCount - currentCount} conversations');
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      _addLog('🎉 Cache pollution testing completed');
      
    } catch (e, stackTrace) {
      _addLog('❌ Error during cache pollution test: $e');
      _addLog('📚 Stack trace: ${stackTrace.toString().substring(0, 300)}...');
    }
  }

  Future<void> _runFullTest() async {
    if (_isRunning.value) return;
    
    _isRunning.value = true;
    setState(() {
      _logs.clear();
    });
    
    try {
      _addLog('🚀 Starting comprehensive InstantDB test...');
      _addLog('📱 App Shell Version: v0.7.21+');
      _addLog('💾 InstantDB Version: v0.2.4');
      _addLog('🔗 Database initialized: ${_db.isInitialized}');
      _addLog('📡 Connection status: ${_db.connectionStatus.value.name}');
      
      await _createTestData();
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _testQueryMethods();
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _testCachePollution();
      
      _addLog('');
      _addLog('🎯 TEST SUMMARY:');
      _addLog('If you see "BUG DETECTED" messages above, our fix needs work.');
      _addLog('If you see "CACHE POLLUTION DETECTED", validation errors are occurring.');
      _addLog('Check the console/logs for InstantDB validation-failed errors.');
      
    } catch (e, stackTrace) {
      _addLog('💥 Test suite failed: $e');
      _addLog('📚 Stack trace: ${stackTrace.toString().substring(0, 500)}...');
    } finally {
      _isRunning.value = false;
    }
  }

  Future<void> _clearTestData() async {
    _addLog('🧹 Clearing test data...');
    
    try {
      // Delete test messages
      for (final messageId in _testMessageIds) {
        await _db.delete('test_messages', messageId);
      }
      _testMessageIds.clear();
      
      // Delete test conversations
      for (final conversationId in _testConversationIds) {
        await _db.delete('test_conversations', conversationId);
      }
      _testConversationIds.clear();
      
      _addLog('✅ Test data cleared successfully');
      
    } catch (e) {
      _addLog('❌ Error clearing test data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    
    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('InstantDB Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and description
            ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'InstantDB Query Testing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen tests findWhere/watchWhere methods for InstantDB '
                      'validation errors, cache pollution, and UI bugs.',
                    ),
                    const SizedBox(height: 8),
                    Watch((context) {
                      try {
                        final convCount = _safeSignalRead(
                          'Status display - conversations count',
                          () => _conversations.value.length,
                        );
                        final msgCount = _safeSignalRead(
                          'Status display - messages count',
                          () => _messages.value.length,
                        );
                        return Text(
                          'Status: ${_db.isInitialized ? "Connected" : "Disconnected"} • '
                          'Conversations: $convCount • '
                          'Messages: $msgCount',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        );
                      } catch (e) {
                        return Text(
                          'Status: Error reading signals - $e',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: Watch((context) {
                    try {
                      final isRunning = _safeSignalRead(
                        'Run button - isRunning check',
                        () => _isRunning.value,
                      );
                      return ui.button(
                        onPressed: isRunning ? () {} : _runFullTest,
                        child: isRunning 
                          ? const Text('Running Tests...')
                          : const Text('Run Full Test'),
                      );
                    } catch (e) {
                      return ui.button(
                        onPressed: () {},
                        child: const Text('Error - Check Logs'),
                      );
                    }
                  }),
                ),
                const SizedBox(width: 8),
                ui.button(
                  onPressed: _clearTestData,
                  child: const Text('Clear Data'),
                ),
                const SizedBox(width: 8),
                ui.button(
                  onPressed: () async {
                    final logsText = _logs.join('\n');
                    await Clipboard.setData(ClipboardData(text: logsText));
                    if (context.mounted) {
                      ui.showSnackBar(
                        context,
                        'Logs copied to clipboard',
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  child: const Text('Copy Logs'),
                ),
                const SizedBox(width: 8),
                ui.button(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Test results log
            Expanded(
              child: ui.card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _logs.isEmpty 
                          ? const Center(
                              child: Text(
                                'No test results yet.\nClick "Run Full Test" to begin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                Color? textColor;
                                
                                if (log.contains('❌') || log.contains('BUG DETECTED')) {
                                  textColor = Colors.red;
                                } else if (log.contains('⚠️') || log.contains('POLLUTION')) {
                                  textColor = Colors.orange;
                                } else if (log.contains('✅') || log.contains('🎉')) {
                                  textColor = Colors.green;
                                } else if (log.contains('🔍') || log.contains('📊')) {
                                  textColor = Theme.of(context).colorScheme.primary;
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}