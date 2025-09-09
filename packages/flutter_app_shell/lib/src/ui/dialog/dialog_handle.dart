import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/navigation_service.dart';

/// Handle for managing dialog lifecycle and updates
class DialogHandle {
  final BuildContext _context;
  final bool _dismissible;
  final NavigationService? _navigationService;
  bool _isDismissed = false;
  VoidCallback? _onDismiss;

  // Dialog context and future tracking for proper dismissal
  BuildContext? _dialogContext;
  Future? _dialogFuture;

  // For progress dialogs
  final ValueNotifier<String?> _messageNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<double?> _progressNotifier = ValueNotifier<double?>(null);

  DialogHandle({
    required BuildContext context,
    bool dismissible = true,
    NavigationService? navigationService,
  })  : _context = context,
        _dismissible = dismissible,
        _navigationService = navigationService ?? _tryGetNavigationService() {
    // Register dialog as active
    _navigationService?.setDialogActive(true);
  }

  static NavigationService? _tryGetNavigationService() {
    try {
      return GetIt.instance.get<NavigationService>();
    } catch (_) {
      return null;
    }
  }

  /// Get the message notifier for reactive updates
  ValueNotifier<String?> get messageNotifier => _messageNotifier;

  /// Get the progress notifier for reactive updates
  ValueNotifier<double?> get progressNotifier => _progressNotifier;

  /// Check if dialog has been dismissed
  bool get isDismissed => _isDismissed;

  /// Set callback for when dialog is dismissed
  void onDismiss(VoidCallback callback) {
    _onDismiss = callback;
  }

  /// Internal method to set the dialog context for proper dismissal
  /// This method is used internally by the adaptive widget factories
  void setDialogContext(BuildContext context) {
    _dialogContext = context;
  }

  /// Internal method to set the dialog future for tracking
  /// This method is used internally by the adaptive widget factories
  void setDialogFuture(Future future) {
    _dialogFuture = future;
  }

  /// Update the message displayed in the dialog
  void updateMessage(String message) {
    if (!_isDismissed) {
      _messageNotifier.value = message;
    }
  }

  /// Update the progress value (0.0 to 1.0)
  void updateProgress(double? progress) {
    if (!_isDismissed && progress != null) {
      _progressNotifier.value = progress.clamp(0.0, 1.0);
    }
  }

  /// Dismiss the dialog safely
  void dismiss() {
    if (_isDismissed) return;

    _isDismissed = true;

    // Notify navigation service
    _navigationService?.setDialogActive(false);

    // Use dialog context if available, fallback to original context
    final contextToUse = _dialogContext ?? _context;
    if (contextToUse.mounted) {
      Navigator.of(contextToUse, rootNavigator: true).pop();
    }

    // Call dismiss callback
    _onDismiss?.call();

    // Clean up notifiers
    _messageNotifier.dispose();
    _progressNotifier.dispose();
  }

  /// Dismiss only if dialog is showing
  void dismissIfShowing() {
    if (!_isDismissed) {
      final contextToUse = _dialogContext ?? _context;
      if (contextToUse.mounted) {
        final navigator = Navigator.of(contextToUse, rootNavigator: true);
        if (navigator.canPop()) {
          dismiss();
        }
      }
    }
  }
}

/// Controller for managing loading dialogs with state updates
class LoadingDialogController extends DialogHandle {
  LoadingDialogController({
    required BuildContext context,
    String? initialMessage,
    bool dismissible = false,
  }) : super(context: context, dismissible: dismissible) {
    if (initialMessage != null) {
      _messageNotifier.value = initialMessage;
    }
  }

  /// Show a success message briefly before dismissing
  Future<void> showSuccessAndDismiss(String message, {Duration? delay}) async {
    updateMessage(message);
    await Future.delayed(delay ?? const Duration(seconds: 1));
    dismiss();
  }

  /// Show an error message briefly before dismissing
  Future<void> showErrorAndDismiss(String message, {Duration? delay}) async {
    updateMessage(message);
    await Future.delayed(delay ?? const Duration(seconds: 2));
    dismiss();
  }
}

/// Controller for managing progress dialogs
class ProgressDialogController extends DialogHandle {
  int _currentStep = 0;
  int _totalSteps = 1;

  ProgressDialogController({
    required BuildContext context,
    String? initialMessage,
    int totalSteps = 1,
    bool dismissible = false,
  })  : _totalSteps = totalSteps,
        super(context: context, dismissible: dismissible) {
    if (initialMessage != null) {
      _messageNotifier.value = initialMessage;
    }
  }

  /// Set the total number of steps
  void setTotalSteps(int steps) {
    _totalSteps = steps;
    _updateProgress();
  }

  /// Increment the current step
  void incrementStep([String? message]) {
    _currentStep++;
    _updateProgress();
    if (message != null) {
      updateMessage(message);
    }
  }

  /// Set the current step directly
  void setStep(int step, [String? message]) {
    _currentStep = step;
    _updateProgress();
    if (message != null) {
      updateMessage(message);
    }
  }

  void _updateProgress() {
    if (_totalSteps > 0) {
      updateProgress(_currentStep / _totalSteps);
    }
  }
}
