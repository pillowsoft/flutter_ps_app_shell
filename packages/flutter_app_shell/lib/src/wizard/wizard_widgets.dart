import 'package:flutter/material.dart';
import 'wizard_controller.dart';
import '../ui/adaptive/adaptive_widget_factory.dart';
import '../ui/adaptive/adaptive_style_provider.dart';
import '../ui/adaptive/adaptive_widgets.dart';

/// A form step widget that handles form validation and data collection
class WizardFormStep extends StatefulWidget {
  /// The wizard controller
  final WizardController controller;

  /// Form fields to display
  final List<Widget> children;

  /// Whether to automatically validate on change
  final bool autoValidate;

  /// Form key for validation
  final GlobalKey<FormState>? formKey;

  /// Padding around the form
  final EdgeInsets padding;

  const WizardFormStep({
    super.key,
    required this.controller,
    required this.children,
    this.autoValidate = false,
    this.formKey,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<WizardFormStep> createState() => _WizardFormStepState();
}

class _WizardFormStepState extends State<WizardFormStep> {
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ui.form(
      formKey: _formKey,
      child: Padding(
        padding: widget.padding,
        child: Column(
          children: widget.children,
        ),
      ),
    );
  }
}

/// A choice selection step (radio buttons, checkboxes, etc.)
class WizardChoiceStep extends StatelessWidget {
  /// The wizard controller
  final WizardController controller;

  /// Data key to store the selection
  final String dataKey;

  /// Available choices
  final List<WizardChoice> choices;

  /// Whether to allow multiple selections
  final bool multiSelect;

  /// Title for the choice group
  final String? title;

  /// Minimum number of selections required
  final int minSelections;

  /// Maximum number of selections allowed
  final int? maxSelections;

  const WizardChoiceStep({
    super.key,
    required this.controller,
    required this.dataKey,
    required this.choices,
    this.multiSelect = false,
    this.title,
    this.minSelections = 1,
    this.maxSelections,
  });

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;

    if (title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title!, style: styles.titleLarge),
          const SizedBox(height: 16),
          _buildChoices(ui, styles),
        ],
      );
    }

    return _buildChoices(ui, styles);
  }

  Widget _buildChoices(AdaptiveWidgetFactory ui, AdaptiveStyleProvider styles) {
    if (multiSelect) {
      return _buildMultiSelectChoices(ui);
    } else {
      return _buildSingleSelectChoices(ui);
    }
  }

  Widget _buildSingleSelectChoices(AdaptiveWidgetFactory ui) {
    final currentValue = controller.getData<String>(dataKey);

    return Column(
      children: choices.map<Widget>((choice) {
        return ui.radioListTile<String>(
          value: choice.value,
          groupValue: currentValue,
          title: Text(choice.title),
          subtitle: choice.subtitle != null ? Text(choice.subtitle!) : null,
          leading: choice.icon != null ? Icon(choice.icon) : null,
          onChanged: (value) {
            if (value != null) {
              controller.setData(dataKey, value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectChoices(AdaptiveWidgetFactory ui) {
    final currentValues =
        controller.getData<List<String>>(dataKey) ?? <String>[];

    return Column(
      children: choices.map<Widget>((choice) {
        final isSelected = currentValues.contains(choice.value);

        return ui.listTile(
          leading: choice.icon != null ? Icon(choice.icon) : null,
          title: Text(choice.title),
          subtitle: choice.subtitle != null ? Text(choice.subtitle!) : null,
          trailing: ui.switch_(
            value: isSelected,
            onChanged: (selected) {
              final newValues = List<String>.from(currentValues);
              if (selected) {
                if (!newValues.contains(choice.value)) {
                  newValues.add(choice.value);
                }
              } else {
                newValues.remove(choice.value);
              }
              controller.setData(dataKey, newValues);
            },
          ),
          onTap: () {
            final newValues = List<String>.from(currentValues);
            if (currentValues.contains(choice.value)) {
              newValues.remove(choice.value);
            } else {
              newValues.add(choice.value);
            }
            controller.setData(dataKey, newValues);
          },
        );
      }).toList(),
    );
  }
}

/// A text input step with validation
class WizardTextInputStep extends StatefulWidget {
  /// The wizard controller
  final WizardController controller;

  /// Data key to store the input
  final String dataKey;

  /// Label for the input field
  final String label;

  /// Hint text for the input field
  final String? hint;

  /// Whether the input is required
  final bool required;

  /// Custom validator function
  final String? Function(String?)? validator;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Maximum number of lines
  final int? maxLines;

  /// Initial value
  final String? initialValue;

  const WizardTextInputStep({
    super.key,
    required this.controller,
    required this.dataKey,
    required this.label,
    this.hint,
    this.required = false,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines,
    this.initialValue,
  });

  @override
  State<WizardTextInputStep> createState() => _WizardTextInputStepState();
}

class _WizardTextInputStepState extends State<WizardTextInputStep> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final currentValue = widget.controller.getData<String>(widget.dataKey) ??
        widget.initialValue ??
        '';
    _textController = TextEditingController(text: currentValue);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ui.textField(
      controller: _textController,
      labelText: widget.label,
      hintText: widget.hint,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      validator: (value) {
        if (widget.required && (value == null || value.trim().isEmpty)) {
          return '${widget.label} is required';
        }
        return widget.validator?.call(value);
      },
      onChanged: (value) {
        widget.controller.setData(widget.dataKey, value);
      },
    );
  }
}

/// Information/welcome step with just content
class WizardInfoStep extends StatelessWidget {
  /// The wizard controller
  final WizardController controller;

  /// Content to display
  final Widget child;

  /// Padding around the content
  final EdgeInsets padding;

  const WizardInfoStep({
    super.key,
    required this.controller,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// A step that displays a summary of collected data
class WizardSummaryStep extends StatelessWidget {
  /// The wizard controller
  final WizardController controller;

  /// Fields to display in the summary
  final List<WizardSummaryField> fields;

  /// Title for the summary
  final String title;

  /// Whether to show raw data keys
  final bool showKeys;

  const WizardSummaryStep({
    super.key,
    required this.controller,
    required this.fields,
    this.title = 'Summary',
    this.showKeys = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final styles = context.adaptiveStyle;
    final data = controller.getAllData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: styles.headlineMedium),
        const SizedBox(height: 24),
        ui.card(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: fields.map((field) {
              final value = data[field.key];
              final displayValue = field.formatter?.call(value) ??
                  value?.toString() ??
                  'Not provided';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (field.icon != null) ...[
                      Icon(field.icon, size: 20),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: Text(
                        field.label,
                        style: styles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayValue,
                            style: styles.bodyMedium,
                          ),
                          if (showKeys)
                            Text(
                              'Key: ${field.key}',
                              style: styles.bodySmall.copyWith(
                                color: styles.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Represents a choice in a wizard choice step
class WizardChoice {
  final String value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool enabled;

  const WizardChoice({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });
}

/// Represents a field in a wizard summary
class WizardSummaryField {
  final String key;
  final String label;
  final IconData? icon;
  final String Function(dynamic value)? formatter;

  const WizardSummaryField({
    required this.key,
    required this.label,
    this.icon,
    this.formatter,
  });
}
