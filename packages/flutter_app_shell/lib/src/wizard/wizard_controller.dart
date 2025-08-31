import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'wizard_models.dart';
import '../services/preferences_service.dart';
import '../utils/logger.dart';
import 'package:logging/logging.dart';

/// Controller for managing wizard flow and state
class WizardController {
  // Service-specific logger
  static final Logger _logger = createServiceLogger('WizardController');

  /// The wizard flow configuration
  final WizardFlow flow;

  /// Preferences service for saving/loading progress
  final PreferencesService? _preferencesService;

  /// Current wizard state as a reactive signal
  late final Signal<WizardState> state;

  /// Internal data storage
  final Map<String, dynamic> _data = {};

  /// Visible steps (filtered by shouldShow conditions)
  late final List<WizardStep> _visibleSteps;

  /// Stream controller for wizard events
  final _eventController = StreamController<WizardEvent>.broadcast();

  /// Stream of wizard events
  Stream<WizardEvent> get events => _eventController.stream;

  WizardController({
    required this.flow,
    PreferencesService? preferencesService,
  }) : _preferencesService = preferencesService {
    _initializeWizard();
  }

  void _initializeWizard() {
    // Initialize visible steps
    _visibleSteps = flow.getVisibleSteps(this);

    // Initialize state
    state = signal(WizardState(
      currentStepIndex: flow.initialStepIndex,
      totalSteps: _visibleSteps.length,
    ));

    // Load saved progress if auto-save is enabled
    if (flow.autoSaveProgress && _preferencesService != null) {
      _loadProgress();
    }

    _logger.fine(
        'Wizard initialized: ${flow.id} with ${_visibleSteps.length} steps');
  }

  /// Get the current step
  WizardStep get currentStep {
    final index = state.value.currentStepIndex;
    if (index < 0 || index >= _visibleSteps.length) {
      throw WizardException('Invalid step index: $index');
    }
    return _visibleSteps[index];
  }

  /// Get all visible steps
  List<WizardStep> get visibleSteps => List.unmodifiable(_visibleSteps);

  /// Get data value by key
  T? getData<T>(String key) {
    return _data[key] as T?;
  }

  /// Set data value
  void setData(String key, dynamic value) {
    _data[key] = value;
    state.value = state.value.copyWith(
      data: Map<String, dynamic>.from(_data),
    );

    // Auto-save if enabled
    if (flow.autoSaveProgress) {
      _saveProgress();
    }

    _eventController.add(WizardDataChangedEvent(key, value));
    _logger.fine('Wizard data updated: $key = $value');
  }

  /// Set multiple data values
  void setDataMap(Map<String, dynamic> data) {
    _data.addAll(data);
    state.value = state.value.copyWith(
      data: Map<String, dynamic>.from(_data),
    );

    if (flow.autoSaveProgress) {
      _saveProgress();
    }

    for (final entry in data.entries) {
      _eventController.add(WizardDataChangedEvent(entry.key, entry.value));
    }

    _logger.fine('Wizard data batch updated: ${data.keys}');
  }

  /// Get all collected data
  Map<String, dynamic> getAllData() {
    return Map<String, dynamic>.unmodifiable(_data);
  }

  /// Clear specific data key
  void clearData(String key) {
    _data.remove(key);
    state.value = state.value.copyWith(
      data: Map<String, dynamic>.from(_data),
    );

    if (flow.autoSaveProgress) {
      _saveProgress();
    }

    _eventController.add(WizardDataClearedEvent(key));
  }

  /// Clear all data
  void clearAllData() {
    final keys = _data.keys.toList();
    _data.clear();
    state.value = state.value.copyWith(
      data: {},
    );

    if (flow.autoSaveProgress) {
      _saveProgress();
    }

    for (final key in keys) {
      _eventController.add(WizardDataClearedEvent(key));
    }
  }

  /// Validate current step
  bool validateCurrentStep() {
    final step = currentStep;
    final validator = step.validator;

    if (validator == null) return true;

    final errorMessage = validator(this);
    if (errorMessage != null) {
      state.value = state.value.copyWith(
        errors: {...state.value.errors, step.id: errorMessage},
      );
      _eventController.add(WizardValidationErrorEvent(step.id, errorMessage));
      return false;
    }

    // Clear any existing errors for this step
    final newErrors = Map<String, String>.from(state.value.errors);
    newErrors.remove(step.id);
    state.value = state.value.copyWith(errors: newErrors);

    return true;
  }

  /// Go to next step
  Future<bool> goToNext() async {
    try {
      state.value = state.value.copyWith(isLoading: true);

      // Validate current step
      if (!validateCurrentStep()) {
        state.value = state.value.copyWith(isLoading: false);
        return false;
      }

      final step = currentStep;

      // Execute custom onNext if provided
      if (step.onNext != null) {
        final success = await step.onNext!(this);
        if (!success) {
          state.value = state.value.copyWith(isLoading: false);
          return false;
        }
      }

      // Check if this is the last step
      if (state.value.isLastStep) {
        return await _completeWizard();
      }

      // Move to next step
      final newIndex = state.value.currentStepIndex + 1;
      state.value = state.value.copyWith(
        currentStepIndex: newIndex,
        isLoading: false,
      );

      if (flow.autoSaveProgress) {
        _saveProgress();
      }

      _eventController.add(WizardStepChangedEvent(
        step.id,
        newIndex < _visibleSteps.length ? _visibleSteps[newIndex].id : null,
        WizardDirection.forward,
      ));

      _logger
          .fine('Wizard moved to step ${newIndex + 1}/${_visibleSteps.length}');
      return true;
    } catch (e, stackTrace) {
      state.value = state.value.copyWith(isLoading: false);
      _logger.severe('Error going to next step', e, stackTrace);
      _eventController.add(WizardErrorEvent(e.toString(), currentStep.id));
      return false;
    }
  }

  /// Go to previous step
  Future<bool> goToPrevious() async {
    if (!flow.allowBack || state.value.isFirstStep) {
      return false;
    }

    try {
      state.value = state.value.copyWith(isLoading: true);

      final step = currentStep;

      // Execute custom onBack if provided
      if (step.onBack != null) {
        final success = await step.onBack!(this);
        if (!success) {
          state.value = state.value.copyWith(isLoading: false);
          return false;
        }
      }

      // Move to previous step
      final newIndex = state.value.currentStepIndex - 1;
      state.value = state.value.copyWith(
        currentStepIndex: newIndex,
        isLoading: false,
      );

      if (flow.autoSaveProgress) {
        _saveProgress();
      }

      _eventController.add(WizardStepChangedEvent(
        step.id,
        _visibleSteps[newIndex].id,
        WizardDirection.backward,
      ));

      _logger.fine(
          'Wizard moved back to step ${newIndex + 1}/${_visibleSteps.length}');
      return true;
    } catch (e, stackTrace) {
      state.value = state.value.copyWith(isLoading: false);
      _logger.severe('Error going to previous step', e, stackTrace);
      _eventController.add(WizardErrorEvent(e.toString(), currentStep.id));
      return false;
    }
  }

  /// Skip current step (if allowed)
  Future<bool> skipStep() async {
    if (!currentStep.canSkip) {
      return false;
    }

    _logger.fine('Skipping wizard step: ${currentStep.id}');
    _eventController.add(WizardStepSkippedEvent(currentStep.id));

    return await goToNext();
  }

  /// Go to specific step by index
  Future<bool> goToStep(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= _visibleSteps.length) {
      return false;
    }

    if (stepIndex == state.value.currentStepIndex) {
      return true;
    }

    try {
      state.value = state.value.copyWith(isLoading: true);

      final oldStep = currentStep;
      state.value = state.value.copyWith(
        currentStepIndex: stepIndex,
        isLoading: false,
      );

      if (flow.autoSaveProgress) {
        _saveProgress();
      }

      _eventController.add(WizardStepChangedEvent(
        oldStep.id,
        _visibleSteps[stepIndex].id,
        stepIndex > state.value.currentStepIndex
            ? WizardDirection.forward
            : WizardDirection.backward,
      ));

      _logger.fine(
          'Wizard jumped to step ${stepIndex + 1}/${_visibleSteps.length}');
      return true;
    } catch (e, stackTrace) {
      state.value = state.value.copyWith(isLoading: false);
      _logger.severe('Error going to step $stepIndex', e, stackTrace);
      return false;
    }
  }

  /// Complete the wizard
  Future<bool> _completeWizard() async {
    try {
      state.value = state.value.copyWith(
        isCompleted: true,
        isLoading: false,
      );

      // Execute completion callback
      if (flow.onComplete != null) {
        await flow.onComplete!(this);
      }

      _eventController.add(WizardCompletedEvent(getAllData()));
      _logger.info('Wizard completed: ${flow.id}');

      // Clear saved progress
      if (flow.autoSaveProgress) {
        _clearSavedProgress();
      }

      return true;
    } catch (e, stackTrace) {
      state.value = state.value.copyWith(isLoading: false);
      _logger.severe('Error completing wizard', e, stackTrace);
      _eventController.add(WizardErrorEvent(e.toString()));
      return false;
    }
  }

  /// Cancel the wizard
  Future<void> cancel() async {
    try {
      // Execute cancellation callback
      if (flow.onCancel != null) {
        await flow.onCancel!(this);
      }

      state.value = state.value.copyWith(isCancelled: true);
      _eventController.add(WizardCancelledEvent());
      _logger.fine('Wizard cancelled: ${flow.id}');

      // Clear saved progress
      if (flow.autoSaveProgress) {
        _clearSavedProgress();
      }
    } catch (e, stackTrace) {
      _logger.severe('Error cancelling wizard', e, stackTrace);
    }
  }

  /// Reset wizard to initial state
  void reset() {
    _data.clear();
    state.value = WizardState(
      currentStepIndex: flow.initialStepIndex,
      totalSteps: _visibleSteps.length,
    );

    if (flow.autoSaveProgress) {
      _clearSavedProgress();
    }

    _eventController.add(WizardResetEvent());
    _logger.fine('Wizard reset: ${flow.id}');
  }

  /// Save progress to preferences
  void _saveProgress() {
    if (_preferencesService == null) return;

    final progressData = {
      'currentStepIndex': state.value.currentStepIndex,
      'data': _data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _preferencesService!.setJson('wizard_progress_${flow.id}', progressData);
  }

  /// Load progress from preferences
  void _loadProgress() {
    if (_preferencesService == null) return;

    final progressSignal =
        _preferencesService!.getJson('wizard_progress_${flow.id}');
    final progressData = progressSignal.value;

    if (progressData != null) {
      final stepIndex = progressData['currentStepIndex'] as int? ?? 0;
      final data = progressData['data'] as Map<String, dynamic>? ?? {};

      _data.addAll(data);
      state.value = state.value.copyWith(
        currentStepIndex: stepIndex.clamp(0, _visibleSteps.length - 1),
        data: Map<String, dynamic>.from(_data),
      );

      _logger.fine(
          'Loaded wizard progress: step $stepIndex with ${data.length} data items');
    }
  }

  /// Clear saved progress
  void _clearSavedProgress() {
    _preferencesService?.remove('wizard_progress_${flow.id}');
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
  }
}

/// Base class for wizard events
abstract class WizardEvent {
  final DateTime timestamp = DateTime.now();
}

/// Event fired when wizard step changes
class WizardStepChangedEvent extends WizardEvent {
  final String fromStepId;
  final String? toStepId;
  final WizardDirection direction;

  WizardStepChangedEvent(this.fromStepId, this.toStepId, this.direction);
}

/// Event fired when wizard data changes
class WizardDataChangedEvent extends WizardEvent {
  final String key;
  final dynamic value;

  WizardDataChangedEvent(this.key, this.value);
}

/// Event fired when wizard data is cleared
class WizardDataClearedEvent extends WizardEvent {
  final String key;

  WizardDataClearedEvent(this.key);
}

/// Event fired when step is skipped
class WizardStepSkippedEvent extends WizardEvent {
  final String stepId;

  WizardStepSkippedEvent(this.stepId);
}

/// Event fired when validation fails
class WizardValidationErrorEvent extends WizardEvent {
  final String stepId;
  final String message;

  WizardValidationErrorEvent(this.stepId, this.message);
}

/// Event fired when wizard is completed
class WizardCompletedEvent extends WizardEvent {
  final Map<String, dynamic> data;

  WizardCompletedEvent(this.data);
}

/// Event fired when wizard is cancelled
class WizardCancelledEvent extends WizardEvent {}

/// Event fired when wizard is reset
class WizardResetEvent extends WizardEvent {}

/// Event fired when an error occurs
class WizardErrorEvent extends WizardEvent {
  final String message;
  final String? stepId;

  WizardErrorEvent(this.message, [this.stepId]);
}

/// Direction of wizard navigation
enum WizardDirection { forward, backward }
