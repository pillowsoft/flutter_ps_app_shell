import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:instantdb_flutter/instantdb_flutter.dart';
import '../services/database_service.dart';
import '../ui/adaptive/adaptive_widgets.dart';

/// Screen for investigating InstantDB datalog handling
/// This helps us verify whether the developer's claims are accurate
class DatalogInvestigationScreen extends StatefulWidget {
  const DatalogInvestigationScreen({super.key});

  @override
  State<DatalogInvestigationScreen> createState() =>
      _DatalogInvestigationScreenState();
}

class _DatalogInvestigationScreenState
    extends State<DatalogInvestigationScreen> {
  final _investigationResults = signal<List<String>>([]);
  final _isRunning = signal(false);

  DatabaseService get _dbService => GetIt.I<DatabaseService>();

  void _addResult(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _investigationResults.value = [
      ..._investigationResults.value,
      '[$timestamp] $message'
    ];
  }

  Future<void> _runInvestigation() async {
    if (_isRunning.value) return;

    _isRunning.value = true;
    _investigationResults.value = [];

    try {
      _addResult('🔍 Starting InstantDB Datalog Investigation');

      // Test 1: Check current connection status
      await _testConnectionStatus();

      // Test 2: Test basic queries without our workaround
      await _testNativeQueries();

      // Test 3: Test queries with our workaround
      await _testWorkaroundQueries();

      // Test 4: Create documents and test reactive updates
      await _testReactiveUpdates();

      // Test 5: Monitor raw query results
      await _testRawQueryMonitoring();
      
      // Test 6: Run diagnostic analysis
      await _testDiagnosticAnalysis();

      _addResult('✅ Investigation completed');
    } catch (e, stackTrace) {
      _addResult('❌ Investigation failed: $e');
      _addResult(
          '📚 Stack trace: ${stackTrace.toString().substring(0, 200)}...');
    } finally {
      _isRunning.value = false;
    }
  }

  Future<void> _testConnectionStatus() async {
    _addResult('📡 Testing connection status...');

    final isInitialized = _dbService.isInitialized;
    final connectionStatus = _dbService.connectionStatus.value;
    final isAuthenticated = _dbService.isAuthenticated;

    _addResult('   • DatabaseService initialized: $isInitialized');
    _addResult('   • Connection status: ${connectionStatus.name}');
    _addResult('   • Authentication status: $isAuthenticated');

    if (!isInitialized) {
      _addResult(
          '⚠️  DatabaseService not initialized - this could cause issues');
    }
  }

  Future<void> _testNativeQueries() async {
    _addResult('🔍 Testing native InstantDB queries...');

    try {
      // Get the underlying InstantDB instance
      final db = _dbService.db;

      _addResult('   • InstantDB ready: ${db.isReady.value}');

      // Test a simple query
      final queryResult = db.query({'test_conversations': {}});

      _addResult('   📊 Native query created, monitoring results...');

      // Monitor the query for a few seconds
      var resultCount = 0;
      final stopwatch = Stopwatch()..start();

      final subscription = effect(() {
        final result = queryResult.value;
        resultCount++;

        _addResult('   📋 Native result #$resultCount:');
        _addResult('      - isLoading: ${result.isLoading}');
        _addResult('      - hasData: ${result.hasData}');
        _addResult('      - hasError: ${result.hasError}');

        if (result.hasData && result.data != null) {
          final data = result.data!;
          _addResult('      - data keys: ${data.keys.toList()}');

          // Check for collection format
          if (data['test_conversations'] != null) {
            final collection = data['test_conversations'] as List?;
            _addResult('      - collection items: ${collection?.length ?? 0}');
          }

          // Check for datalog format
          if (data['datalog-result'] != null) {
            _addResult('      - ⚠️  DATALOG FORMAT DETECTED');
            final datalogResult = data['datalog-result'] as Map?;
            if (datalogResult?['join-rows'] is List) {
              final joinRows = datalogResult!['join-rows'] as List;
              _addResult('      - join-rows count: ${joinRows.length}');
            }
          }
        }

        if (result.hasError) {
          _addResult('      - error: ${result.error}');
        }
      });

      // Wait a bit for results
      await Future.delayed(const Duration(seconds: 2));
      subscription(); // Dispose the effect

      _addResult('   ✅ Native query test completed');
    } catch (e) {
      _addResult('   ❌ Native query test failed: $e');
    }
  }

  Future<void> _testWorkaroundQueries() async {
    _addResult('🛠️  Testing DatabaseService queries (with workaround)...');

    try {
      final results = await _dbService.findAll('test_conversations');
      _addResult('   📊 DatabaseService returned ${results.length} documents');

      if (results.isNotEmpty) {
        _addResult('   📦 Sample document: ${results.first.keys.toList()}');
      }

      _addResult('   ✅ DatabaseService query test completed');
    } catch (e) {
      _addResult('   ❌ DatabaseService query test failed: $e');
    }
  }

  Future<void> _testReactiveUpdates() async {
    _addResult('⚡ Testing reactive updates...');

    try {
      // Set up reactive query
      final reactiveQuery = _dbService.watchCollection('test_conversations');

      var updateCount = 0;
      final subscription = effect(() {
        final results = reactiveQuery.value;
        updateCount++;
        _addResult(
            '   📡 Reactive update #$updateCount: ${results.length} documents');
      });

      // Create a test document to trigger updates
      _addResult('   📝 Creating test document...');
      final docId = await _dbService.create('test_conversations', {
        'title': 'Investigation Test Document',
        'createdAt': DateTime.now().toIso8601String(),
      });

      _addResult('   📄 Created document: $docId');

      // Wait for updates
      await Future.delayed(const Duration(seconds: 1));

      subscription(); // Dispose the effect

      _addResult('   ✅ Reactive updates test completed');
    } catch (e) {
      _addResult('   ❌ Reactive updates test failed: $e');
    }
  }

  Future<void> _testRawQueryMonitoring() async {
    _addResult('🔬 Testing raw query monitoring...');

    try {
      // This test attempts to catch the exact moment when datalog format appears
      final db = _dbService.db;

      // Create multiple queries to increase chance of catching datalog format
      final queries = [
        db.query({'test_conversations': {}}),
        db.query({
          'test_conversations': {
            '\$': {'limit': 10}
          }
        }),
        db.query({
          'test_conversations': {
            '\$': {
              'where': {
                'title': {'!=': null}
              }
            }
          }
        }),
      ];

      _addResult('   📊 Created ${queries.length} different query types');

      var datalogDetected = false;
      final subscriptions = <VoidCallback>[];

      for (int i = 0; i < queries.length; i++) {
        final query = queries[i];
        final subscription = effect(() {
          final result = query.value;

          if (result.hasData && result.data != null) {
            final data = result.data!;

            // Check specifically for datalog format
            if (data['datalog-result'] != null && !datalogDetected) {
              datalogDetected = true;
              _addResult('   🎯 DATALOG FORMAT DETECTED in query #${i + 1}!');
              _addResult('   📋 Data keys: ${data.keys.toList()}');

              final datalogResult = data['datalog-result'] as Map?;
              if (datalogResult?['join-rows'] is List) {
                final joinRows = datalogResult!['join-rows'] as List;
                _addResult('   📊 Join-rows count: ${joinRows.length}');

                if (joinRows.isNotEmpty) {
                  _addResult('   📦 Sample join-row: ${joinRows.first}');
                }
              }
            }
          }
        });

        subscriptions.add(subscription);
      }

      // Monitor for a while
      await Future.delayed(const Duration(seconds: 3));

      // Clean up subscriptions
      for (final subscription in subscriptions) {
        subscription();
      }

      if (datalogDetected) {
        _addResult('   ✅ Successfully detected datalog format!');
      } else {
        _addResult('   ℹ️  No datalog format detected in this test');
      }

      _addResult('   ✅ Raw query monitoring completed');
    } catch (e) {
      _addResult('   ❌ Raw query monitoring failed: $e');
    }
  }

  Future<void> _testDiagnosticAnalysis() async {
    _addResult('🔬 Running diagnostic analysis...');
    
    try {
      // Test with different collections
      final collections = ['test_conversations', 'conversations', 'todos'];
      
      for (final collection in collections) {
        _addResult('');
        _addResult('📊 Diagnosing collection: $collection');
        
        final diagnosis = await _dbService.diagnoseDatalogParsing(collection);
        
        _addResult('   • Format: ${diagnosis['format'] ?? 'unknown'}');
        _addResult('   • Parsed documents: ${diagnosis['parsedDocuments']}');
        
        if (diagnosis['joinRowCount'] != null) {
          _addResult('   • Join-rows: ${diagnosis['joinRowCount']}');
        }
        
        // Show attribute mappings
        final mappings = diagnosis['attributeMappings'] as Map?;
        if (mappings != null && mappings.isNotEmpty) {
          _addResult('   • Configured mappings: ${mappings.length}');
        }
        
        // Show found attribute IDs
        final foundIds = diagnosis['foundAttributeIds'] as Map?;
        if (foundIds != null && foundIds.isNotEmpty) {
          _addResult('   • Unique attribute IDs found: ${foundIds.length}');
          
          foundIds.forEach((attrId, info) {
            final isMapped = info['isMapped'] as bool;
            final mappedTo = info['mappedTo'];
            final valueType = info['valueType'];
            final occurrences = info['occurrences'];
            
            if (isMapped) {
              _addResult('     ✅ $attrId → $mappedTo ($valueType, $occurrences occurrences)');
            } else {
              final sampleValue = info['sampleValue'];
              _addResult('     ⚠️  $attrId → UNMAPPED ($valueType, $occurrences occurrences)');
              _addResult('        Sample: "$sampleValue"');
            }
          });
        }
        
        // Show unmapped attributes summary
        final unmapped = diagnosis['unmappedAttributes'] as List?;
        if (unmapped != null && unmapped.isNotEmpty) {
          _addResult('   ⚠️  ${unmapped.length} unmapped attribute IDs need attention!');
          _addResult('   📝 Add these to _getAttributeMappings() in DatabaseService');
        }
        
        // Show sample document if parsed
        if (diagnosis['sampleDocument'] != null) {
          final fields = diagnosis['documentFields'] as List?;
          _addResult('   • Document fields: ${fields?.join(', ') ?? 'none'}');
        }
        
        // Show any errors
        final errors = diagnosis['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          for (final error in errors) {
            _addResult('   ❌ Error: ${error['message']}');
          }
        }
      }
      
      _addResult('');
      _addResult('✅ Diagnostic analysis completed');
      
    } catch (e) {
      _addResult('❌ Diagnostic analysis failed: $e');
    }
  }

  void _clearResults() {
    _investigationResults.value = [];
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ui.scaffold(
      appBar: ui.appBar(
        title: const Text('Datalog Investigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: Watch((context) {
                    return ui.button(
                      onPressed: _isRunning.value
                          ? () {}  // Disabled button - empty callback
                          : () {
                              _runInvestigation();
                            },
                      child: _isRunning.value
                          ? const Text('Running Investigation...')
                          : const Text('Start Investigation'),
                    );
                  }),
                ),
                const SizedBox(width: 16),
                ui.button(
                  onPressed: _clearResults,
                  child: const Text('Clear'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investigation Purpose',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This investigation tests whether InstantDB returns datalog-result format '
                      'instead of the expected collection format, and whether our workaround is needed.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: ui.card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investigation Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Watch((context) {
                          final results = _investigationResults.value;

                          if (results.isEmpty) {
                            return const Center(
                              child: Text(
                                  'No results yet. Click "Start Investigation" to begin.'),
                            );
                          }

                          return ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final result = results[index];
                              final isError = result.contains('❌');
                              final isWarning = result.contains('⚠️');
                              final isSuccess = result.contains('✅');
                              final isImportant = result.contains('🎯');

                              Color? textColor;
                              if (isError) {
                                textColor = Theme.of(context).colorScheme.error;
                              } else if (isWarning) {
                                textColor =
                                    Theme.of(context).colorScheme.secondary;
                              } else if (isSuccess) {
                                textColor = Colors.green;
                              } else if (isImportant) {
                                textColor =
                                    Theme.of(context).colorScheme.primary;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  result,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
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
}
