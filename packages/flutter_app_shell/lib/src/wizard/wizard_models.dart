import 'package:flutter/material.dart';

/// Represents a single step in a wizard flow
class WizardStep {
  /// Unique identifier for this step
  final String id;

  /// Display title for this step
  final String title;

  /// Optional subtitle or description
  final String? subtitle;

  /// Icon to display for this step (optional)
  final IconData? icon;

  /// Widget builder for the step content
  final Widget Function(BuildContext context, dynamic controller) builder;

  /// Validation function - returns null if valid, error message if invalid
  final String? Function(dynamic controller)? validator;

  /// Whether this step can be skipped
  final bool canSkip;

  /// Whether this step should be shown (for conditional logic)
  final bool Function(dynamic controller)? shouldShow;

  /// Custom action for the next button (optional)
  final Future<bool> Function(dynamic controller)? onNext;

  /// Custom action for the back button (optional)
  final Future<bool> Function(dynamic controller)? onBack;

  const WizardStep({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    required this.builder,
    this.validator,
    this.canSkip = false,
    this.shouldShow,
    this.onNext,
    this.onBack,
  });
}

/// Configuration for a complete wizard flow
class WizardFlow {
  /// Unique identifier for this wizard
  final String id;

  /// Title of the wizard
  final String title;

  /// Optional description
  final String? description;

  /// List of steps in order
  final List<WizardStep> steps;

  /// Initial step index (default: 0)
  final int initialStepIndex;

  /// Whether to show progress indicator
  final bool showProgress;

  /// Progress indicator style
  final WizardProgressStyle progressStyle;

  /// Whether to allow going back to previous steps
  final bool allowBack;

  /// Whether to save progress automatically
  final bool autoSaveProgress;

  /// Callback when wizard is completed
  final Future<void> Function(dynamic controller)? onComplete;

  /// Callback when wizard is cancelled
  final Future<void> Function(dynamic controller)? onCancel;

  const WizardFlow({
    required this.id,
    required this.title,
    this.description,
    required this.steps,
    this.initialStepIndex = 0,
    this.showProgress = true,
    this.progressStyle = WizardProgressStyle.linear,
    this.allowBack = true,
    this.autoSaveProgress = true,
    this.onComplete,
    this.onCancel,
  });

  /// Get visible steps based on current wizard state
  List<WizardStep> getVisibleSteps(dynamic controller) {
    return steps.where((step) {
      return step.shouldShow?.call(controller) ?? true;
    }).toList();
  }
}

/// Style options for wizard progress indicators
enum WizardProgressStyle {
  /// Linear progress bar
  linear,

  /// Circular progress indicator
  circular,

  /// Step-by-step indicators (dots)
  steps,

  /// Numbered steps
  numbered,

  /// No progress indicator
  none,
}

/// Current state of a wizard
class WizardState {
  /// Current step index in the visible steps
  final int currentStepIndex;

  /// Total number of visible steps
  final int totalSteps;

  /// Whether the wizard is loading/processing
  final bool isLoading;

  /// Current validation errors
  final Map<String, String> errors;

  /// User data collected so far
  final Map<String, dynamic> data;

  /// Whether the wizard is completed
  final bool isCompleted;

  /// Whether the wizard was cancelled
  final bool isCancelled;

  const WizardState({
    required this.currentStepIndex,
    required this.totalSteps,
    this.isLoading = false,
    this.errors = const {},
    this.data = const {},
    this.isCompleted = false,
    this.isCancelled = false,
  });

  /// Create a copy with updated values
  WizardState copyWith({
    int? currentStepIndex,
    int? totalSteps,
    bool? isLoading,
    Map<String, String>? errors,
    Map<String, dynamic>? data,
    bool? isCompleted,
    bool? isCancelled,
  }) {
    return WizardState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      data: data ?? this.data,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// Get progress as a value between 0.0 and 1.0
  double get progress {
    if (totalSteps == 0) return 0.0;
    return (currentStepIndex + 1) / totalSteps;
  }

  /// Whether we can go to the next step
  bool get canGoNext {
    return currentStepIndex < totalSteps - 1;
  }

  /// Whether we can go to the previous step
  bool get canGoBack {
    return currentStepIndex > 0;
  }

  /// Whether this is the first step
  bool get isFirstStep {
    return currentStepIndex == 0;
  }

  /// Whether this is the last step
  bool get isLastStep {
    return currentStepIndex == totalSteps - 1;
  }
}

/// Exception thrown by wizard operations
class WizardException implements Exception {
  final String message;
  final String? stepId;
  final dynamic cause;

  const WizardException(this.message, {this.stepId, this.cause});

  @override
  String toString() {
    if (stepId != null) {
      return 'WizardException in step $stepId: $message';
    }
    return 'WizardException: $message';
  }
}
