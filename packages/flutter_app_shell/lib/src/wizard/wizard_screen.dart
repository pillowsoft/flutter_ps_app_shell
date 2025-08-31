import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'wizard_controller.dart';
import 'wizard_models.dart';
import '../ui/adaptive/adaptive_widget_factory.dart';
import '../ui/adaptive/adaptive_style_provider.dart';
import '../ui/adaptive/adaptive_widgets.dart';

/// Main wizard screen that displays the current step and navigation
class WizardScreen extends StatefulWidget {
  /// The wizard controller managing the flow
  final WizardController controller;

  /// Whether to show the app bar
  final bool showAppBar;

  /// Custom app bar title (defaults to wizard flow title)
  final Widget? title;

  /// Custom actions for the app bar
  final List<Widget>? actions;

  /// Whether to show the cancel button
  final bool showCancel;

  /// Custom cancel button text
  final String cancelText;

  /// Callback when cancel is pressed
  final VoidCallback? onCancel;

  /// Whether to show navigation buttons
  final bool showNavigationButtons;

  /// Custom next button text
  final String nextText;

  /// Custom back button text
  final String backText;

  /// Custom complete button text
  final String completeText;

  /// Custom skip button text
  final String skipText;

  /// Padding around the wizard content
  final EdgeInsets? padding;

  /// Background color override
  final Color? backgroundColor;

  const WizardScreen({
    super.key,
    required this.controller,
    this.showAppBar = true,
    this.title,
    this.actions,
    this.showCancel = true,
    this.cancelText = 'Cancel',
    this.onCancel,
    this.showNavigationButtons = true,
    this.nextText = 'Next',
    this.backText = 'Back',
    this.completeText = 'Complete',
    this.skipText = 'Skip',
    this.padding,
    this.backgroundColor,
  });

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  @override
  void dispose() {
    // Don't dispose controller here - it might be used elsewhere
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;

    return Watch((context) {
      final state = widget.controller.state.value;

      if (state.isCompleted) {
        return _buildCompletedScreen(ui, styles);
      }

      if (state.isCancelled) {
        return _buildCancelledScreen(ui, styles);
      }

      return ui.scaffold(
        backgroundColor: widget.backgroundColor,
        appBar: widget.showAppBar ? _buildAppBar(ui, styles) : null,
        body: Column(
          children: [
            // Progress indicator
            if (widget.controller.flow.showProgress &&
                widget.controller.flow.progressStyle !=
                    WizardProgressStyle.none)
              _buildProgressIndicator(ui, styles, state),

            // Step content
            Expanded(
              child: _buildStepContent(ui, styles, state),
            ),

            // Navigation buttons
            if (widget.showNavigationButtons)
              _buildNavigationButtons(ui, styles, state),
          ],
        ),
      );
    });
  }

  Widget? _buildAppBar(AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    return ui.appBar(
      title: widget.title ?? Text(widget.controller.flow.title),
      actions: [
        if (widget.showCancel)
          ui.textButton(
            label: widget.cancelText,
            onPressed: () => _handleCancel(),
          ),
        ...?widget.actions,
      ],
    );
  }

  Widget _buildProgressIndicator(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    switch (widget.controller.flow.progressStyle) {
      case WizardProgressStyle.linear:
        return _buildLinearProgress(ui, styles, state);
      case WizardProgressStyle.circular:
        return _buildCircularProgress(ui, styles, state);
      case WizardProgressStyle.steps:
        return _buildStepsProgress(ui, styles, state);
      case WizardProgressStyle.numbered:
        return _buildNumberedProgress(ui, styles, state);
      case WizardProgressStyle.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLinearProgress(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${state.currentStepIndex + 1} of ${state.totalSteps}',
                style: styles.bodyMedium,
              ),
              Text(
                '${(state.progress * 100).round()}%',
                style: styles.bodyMedium.copyWith(
                  color: styles.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: styles.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(styles.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: state.progress,
              backgroundColor: styles.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(styles.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Step ${state.currentStepIndex + 1} of ${state.totalSteps}',
            style: styles.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsProgress(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(state.totalSteps, (index) {
          final isCompleted = index < state.currentStepIndex;
          final isCurrent = index == state.currentStepIndex;

          return Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent
                      ? styles.primary
                      : styles.surfaceVariant,
                ),
              ),
              if (index < state.totalSteps - 1)
                Container(
                  width: 24,
                  height: 2,
                  color: isCompleted ? styles.primary : styles.surfaceVariant,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNumberedProgress(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(state.totalSteps, (index) {
          final isCompleted = index < state.currentStepIndex;
          final isCurrent = index == state.currentStepIndex;

          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent
                      ? styles.primary
                      : styles.surfaceVariant,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: styles.bodyMedium.copyWith(
                    color: isCompleted || isCurrent
                        ? styles.onPrimary
                        : styles.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (index < state.totalSteps - 1)
                Container(
                  width: 24,
                  height: 2,
                  color: isCompleted ? styles.primary : styles.surfaceVariant,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    final step = widget.controller.currentStep;

    return SingleChildScrollView(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and subtitle
          if (step.icon != null) ...[
            Row(
              children: [
                Icon(
                  step.icon!,
                  size: 32,
                  color: styles.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    step.title,
                    style: styles.headlineMedium,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              step.title,
              style: styles.headlineMedium,
            ),
          ],

          if (step.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              step.subtitle!,
              style: styles.bodyLarge.copyWith(
                color: styles.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Error display
          if (state.errors.containsKey(step.id)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: styles.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: styles.error),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: styles.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errors[step.id]!,
                      style: styles.bodyMedium.copyWith(color: styles.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Loading overlay
          if (state.isLoading) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
          ] else ...[
            // Step content
            step.builder(context, widget.controller),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    AdaptiveWidgetFactory ui,
    AdaptiveStyleProvider styles,
    WizardState state,
  ) {
    final step = widget.controller.currentStep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: styles.surface,
        border: Border(
          top: BorderSide(
            color: styles.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (state.canGoBack && widget.controller.flow.allowBack)
            ui.outlinedButton(
              label: widget.backText,
              onPressed: state.isLoading ? () {} : () => _handleBack(),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Skip button (if applicable)
          if (step.canSkip) ...[
            ui.textButton(
              label: widget.skipText,
              onPressed: state.isLoading ? () {} : () => _handleSkip(),
            ),
            const SizedBox(width: 12),
          ],

          // Next/Complete button
          ui.button(
            label: state.isLastStep ? widget.completeText : widget.nextText,
            onPressed: state.isLoading ? () {} : () => _handleNext(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    return ui.scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Wizard Completed!',
                style: styles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for completing the ${widget.controller.flow.title}.',
                style: styles.bodyLarge.copyWith(
                  color: styles.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ui.button(
                label: 'Done',
                onPressed: () {
                  widget.controller.dispose();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledScreen(
      AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    return ui.scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel,
                size: 80,
                color: styles.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Wizard Cancelled',
                style: styles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'The ${widget.controller.flow.title} was cancelled.',
                style: styles.bodyLarge.copyWith(
                  color: styles.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ui.button(
                label: 'Go Back',
                onPressed: () {
                  widget.controller.dispose();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    await widget.controller.goToNext();
  }

  Future<void> _handleBack() async {
    await widget.controller.goToPrevious();
  }

  Future<void> _handleSkip() async {
    await widget.controller.skipStep();
  }

  Future<void> _handleCancel() async {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      await widget.controller.cancel();
    }
  }
}
