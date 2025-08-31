import 'dart:async';
import 'base_plugin.dart';

/// Interface for workflow plugins that provide automation and business logic
abstract class WorkflowPlugin extends BasePlugin {
  @override
  PluginType get type => PluginType.workflow;

  /// Workflows provided by this plugin
  List<WorkflowDefinition> get workflows;

  /// Register workflows with the workflow manager
  Future<void> registerWorkflows();

  /// Unregister workflows from the workflow manager
  Future<void> unregisterWorkflows();

  /// Execute a specific workflow
  Future<WorkflowResult> executeWorkflow(
    String workflowId,
    Map<String, dynamic> parameters,
  );

  /// Cancel a running workflow
  Future<void> cancelWorkflow(String executionId);

  /// Get status of a workflow execution
  Future<WorkflowExecutionStatus> getWorkflowStatus(String executionId);
}

/// Definition of a workflow
class WorkflowDefinition {
  final String id;
  final String name;
  final String description;
  final List<WorkflowParameter> parameters;
  final List<WorkflowTrigger> triggers;
  final WorkflowCategory category;
  final Duration? timeout;
  final bool canCancel;
  final bool canRetry;

  const WorkflowDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.parameters = const [],
    this.triggers = const [],
    this.category = WorkflowCategory.general,
    this.timeout,
    this.canCancel = true,
    this.canRetry = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'triggers': triggers.map((t) => t.toJson()).toList(),
        'category': category.name,
        'timeout': timeout?.inMilliseconds,
        'canCancel': canCancel,
        'canRetry': canRetry,
      };
}

/// Parameter definition for workflows
class WorkflowParameter {
  final String name;
  final String description;
  final WorkflowParameterType type;
  final bool required;
  final dynamic defaultValue;
  final List<dynamic>? allowedValues;

  const WorkflowParameter({
    required this.name,
    required this.description,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.allowedValues,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'type': type.name,
        'required': required,
        'defaultValue': defaultValue,
        'allowedValues': allowedValues,
      };
}

/// Types of workflow parameters
enum WorkflowParameterType {
  string,
  number,
  boolean,
  list,
  object,
  file,
  date,
  duration,
}

/// Workflow trigger definitions
class WorkflowTrigger {
  final String id;
  final WorkflowTriggerType type;
  final Map<String, dynamic> configuration;

  const WorkflowTrigger({
    required this.id,
    required this.type,
    this.configuration = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'configuration': configuration,
      };
}

/// Types of workflow triggers
enum WorkflowTriggerType {
  manual, // User-initiated
  scheduled, // Time-based (cron, interval)
  event, // Event-driven (data changes, user actions)
  webhook, // HTTP webhook
  fileChange, // File system changes
  startup, // App startup
  background, // Background app state
}

/// Categories for organizing workflows
enum WorkflowCategory {
  general,
  dataSync,
  automation,
  integration,
  maintenance,
  security,
  analytics,
  backup,
}

/// Result of workflow execution
class WorkflowResult {
  final String executionId;
  final bool success;
  final Map<String, dynamic> output;
  final String? error;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  WorkflowResult({
    required this.executionId,
    required this.success,
    this.output = const {},
    this.error,
    required this.startTime,
    required this.endTime,
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'executionId': executionId,
        'success': success,
        'output': output,
        'error': error,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'duration': duration.inMilliseconds,
      };
}

/// Status of a workflow execution
class WorkflowExecutionStatus {
  final String executionId;
  final String workflowId;
  final WorkflowExecutionState state;
  final double progress;
  final String? currentStep;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;
  final Map<String, dynamic> metadata;

  const WorkflowExecutionStatus({
    required this.executionId,
    required this.workflowId,
    required this.state,
    this.progress = 0.0,
    this.currentStep,
    required this.startTime,
    this.endTime,
    this.error,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'executionId': executionId,
        'workflowId': workflowId,
        'state': state.name,
        'progress': progress,
        'currentStep': currentStep,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'error': error,
        'metadata': metadata,
      };
}

/// States of workflow execution
enum WorkflowExecutionState {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
  timeout,
}

/// Base class for workflow plugin implementations
abstract class BaseWorkflowPlugin extends WorkflowPlugin {
  PluginState _state = PluginState.unloaded;
  Exception? _lastError;
  final Map<String, StreamController<WorkflowExecutionStatus>>
      _executionStreams = {};

  PluginState get state => _state;
  Exception? get lastError => _lastError;

  @override
  Future<void> initialize() async {
    try {
      _state = PluginState.initializing;
      await registerWorkflows();
      await onInitialize();
      _state = PluginState.ready;
      _lastError = null;
    } catch (e) {
      _lastError = e is Exception ? e : Exception(e.toString());
      _state = PluginState.error;
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      _state = PluginState.disposing;
      await unregisterWorkflows();

      // Close all execution streams
      for (final controller in _executionStreams.values) {
        await controller.close();
      }
      _executionStreams.clear();

      await onDispose();
      _state = PluginState.disposed;
    } catch (e) {
      _lastError = e is Exception ? e : Exception(e.toString());
      _state = PluginState.error;
      rethrow;
    }
  }

  @override
  Future<bool> healthCheck() async {
    return _state == PluginState.ready && _lastError == null;
  }

  @override
  Map<String, dynamic> getStatus() => {
        'state': _state.name,
        'lastError': _lastError?.toString(),
        'workflowCount': workflows.length,
        'activeExecutions': _executionStreams.length,
        'workflows': workflows
            .map((w) => {
                  'id': w.id,
                  'name': w.name,
                  'category': w.category.name,
                })
            .toList(),
      };

  /// Watch workflow execution status
  Stream<WorkflowExecutionStatus> watchExecution(String executionId) {
    final controller = _executionStreams.putIfAbsent(
      executionId,
      () => StreamController<WorkflowExecutionStatus>.broadcast(),
    );
    return controller.stream;
  }

  /// Update execution status and notify watchers
  void updateExecutionStatus(WorkflowExecutionStatus status) {
    final controller = _executionStreams[status.executionId];
    if (controller != null) {
      controller.add(status);

      // Clean up completed executions
      if (status.state == WorkflowExecutionState.completed ||
          status.state == WorkflowExecutionState.failed ||
          status.state == WorkflowExecutionState.cancelled) {
        _cleanupExecution(status.executionId);
      }
    }
  }

  void _cleanupExecution(String executionId) {
    final controller = _executionStreams.remove(executionId);
    controller?.close();
  }

  /// Override to implement plugin-specific initialization
  Future<void> onInitialize() async {}

  /// Override to implement plugin-specific disposal
  Future<void> onDispose() async {}
}
