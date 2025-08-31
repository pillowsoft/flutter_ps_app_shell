import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import '../../models/task_model.dart';
import 'dart:math';

/// Advanced task form with validation and conditional fields
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedHoursController;
  late TextEditingController _tagsController;

  // Form data
  late TaskPriority _priority;
  late TaskStatus _status;
  late TaskCategory _category;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  double _progress = 0.0;
  final List<String> _assignees = [];
  final List<TaskReminder> _reminders = [];

  // Validation state
  bool _hasChanges = false;
  bool _showAdvancedOptions = false;
  Map<String, String?> _fieldErrors = {};

  // Custom fields for specific categories
  Map<String, dynamic> _customFields = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    final task = widget.task;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _estimatedHoursController = TextEditingController(
      text: task?.estimatedHours?.toString() ?? '',
    );
    _tagsController = TextEditingController(
      text: task?.tags.join(', ') ?? '',
    );

    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    _category = task?.category ?? TaskCategory.personal;
    _dueDate = task?.dueDate;
    _progress = task?.progress ?? 0.0;
    _isRecurring = task?.isRecurring ?? false;

    if (task?.recurrence != null) {
      _recurrenceType = task!.recurrence!.type;
      _recurrenceInterval = task.recurrence!.interval;
      _recurrenceEndDate = task.recurrence!.endDate;
    }

    if (task?.assignees != null) {
      _assignees.addAll(task!.assignees);
    }

    if (task?.reminders != null) {
      _reminders.addAll(task!.reminders);
    }

    if (task?.customFields != null) {
      _customFields = Map.from(task!.customFields!);
    }

    // Add listeners for change detection
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _estimatedHoursController.addListener(_onFormChanged);
    _tagsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _saveTask() {
    // Clear previous errors
    setState(() => _fieldErrors.clear());

    if (!_formKey.currentState!.validate()) {
      // Show validation error
      _showSnackBar('Please fix the errors in the form', isError: true);
      return;
    }

    // Additional validation
    if (!_validateForm()) {
      return;
    }

    // Parse tags
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    // Parse estimated hours
    int? estimatedHours;
    if (_estimatedHoursController.text.isNotEmpty) {
      estimatedHours = int.tryParse(_estimatedHoursController.text);
    }

    // Create recurrence pattern if needed
    RecurrencePattern? recurrence;
    if (_isRecurring) {
      recurrence = RecurrencePattern(
        type: _recurrenceType,
        interval: _recurrenceInterval,
        endDate: _recurrenceEndDate,
      );
    }

    // Combine date and time for due date
    DateTime? finalDueDate;
    if (_dueDate != null) {
      finalDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 0,
        _dueTime?.minute ?? 0,
      );
    }

    // Create or update task
    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      category: _category,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      dueDate: finalDueDate,
      completedAt: _status == TaskStatus.done ? DateTime.now() : null,
      tags: tags,
      assignees: _assignees,
      estimatedHours: estimatedHours,
      progress: _progress,
      isRecurring: _isRecurring,
      recurrence: recurrence,
      reminders: _reminders,
      customFields: _customFields.isNotEmpty ? _customFields : null,
      attachments: widget.task?.attachments ?? [],
      comments: widget.task?.comments ?? [],
      subtaskIds: widget.task?.subtaskIds ?? [],
    );

    // Return the task
    Navigator.pop(context, task);
  }

  bool _validateForm() {
    final errors = <String, String?>{};

    // Title validation
    if (_titleController.text.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (_titleController.text.trim().length < 3) {
      errors['title'] = 'Title must be at least 3 characters';
    }

    // Due date validation
    if (_dueDate != null &&
        _dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      if (widget.task == null) {
        // Only for new tasks
        errors['dueDate'] = 'Due date cannot be in the past';
      }
    }

    // Estimated hours validation
    if (_estimatedHoursController.text.isNotEmpty) {
      final hours = int.tryParse(_estimatedHoursController.text);
      if (hours == null || hours < 1 || hours > 999) {
        errors['estimatedHours'] = 'Enter a valid number between 1 and 999';
      }
    }

    // Recurrence validation
    if (_isRecurring) {
      if (_recurrenceInterval < 1 || _recurrenceInterval > 99) {
        errors['recurrenceInterval'] = 'Interval must be between 1 and 99';
      }

      if (_recurrenceEndDate != null && _dueDate != null) {
        if (_recurrenceEndDate!.isBefore(_dueDate!)) {
          errors['recurrenceEndDate'] = 'End date must be after due date';
        }
      }
    }

    // Category-specific validation
    _validateCategorySpecificFields(errors);

    setState(() => _fieldErrors = errors);

    return errors.isEmpty;
  }

  void _validateCategorySpecificFields(Map<String, String?> errors) {
    switch (_category) {
      case TaskCategory.work:
        if (_customFields['projectCode'] == null ||
            _customFields['projectCode'].isEmpty) {
          errors['projectCode'] = 'Project code is required for work tasks';
        }
        break;
      case TaskCategory.finance:
        if (_customFields['amount'] != null) {
          final amount = double.tryParse(_customFields['amount'].toString());
          if (amount == null || amount < 0) {
            errors['amount'] = 'Enter a valid amount';
          }
        }
        break;
      default:
        break;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _hasChanges = true;
      });

      // Auto-select time if not set
      if (_dueTime == null) {
        _selectDueTime();
      }
    }
  }

  Future<void> _selectDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _dueTime = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _dueDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
        _hasChanges = true;
      });
    }
  }

  void _addReminder() {
    if (_dueDate == null) {
      _showSnackBar('Please set a due date first', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        dueDate: _dueDate!,
        onAdd: (reminder) {
          setState(() {
            _reminders.add(reminder);
            _hasChanges = true;
          });
        },
      ),
    );
  }

  void _addAssignee() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Assignee'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name or Email',
            hintText: 'john.doe@example.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _assignees.add(controller.text.trim());
                  _hasChanges = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<AppShellSettingsStore>();

    return Watch((context) {
      // Get current UI system to force rebuilds
      final uiSystem = settingsStore.uiSystem.value;
      final theme = Theme.of(context);
      final ui = getAdaptiveFactory(context);

      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: ValueKey('task_form_scaffold_$uiSystem'),
          appBar: AppBar(
            title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _saveTask,
                  child: const Text('Save'),
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title field
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter task title',
                    required: true,
                    error: _fieldErrors['title'],
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description field
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter task description (optional)',
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: 24),

                  // Priority, Status, Category row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown<TaskPriority>(
                          label: 'Priority',
                          value: _priority,
                          items: TaskPriority.values,
                          onChanged: (value) {
                            setState(() {
                              _priority = value!;
                              _hasChanges = true;
                            });
                          },
                          itemBuilder: (priority) => Row(
                            children: [
                              Icon(priority.icon,
                                  size: 20, color: priority.color),
                              const SizedBox(width: 8),
                              Text(priority.label),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown<TaskStatus>(
                          label: 'Status',
                          value: _status,
                          items: TaskStatus.values
                              .where((s) => s != TaskStatus.archived)
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _status = value!;
                              _hasChanges = true;
                              // Auto-update progress based on status
                              if (_status == TaskStatus.done) {
                                _progress = 1.0;
                              } else if (_status == TaskStatus.todo) {
                                _progress = 0.0;
                              }
                            });
                          },
                          itemBuilder: (status) => Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category dropdown with conditional fields
                  _buildDropdown<TaskCategory>(
                    label: 'Category',
                    value: _category,
                    items: TaskCategory.values,
                    onChanged: (value) {
                      setState(() {
                        _category = value!;
                        _hasChanges = true;
                        // Clear custom fields when category changes
                        _customFields.clear();
                      });
                    },
                    itemBuilder: (category) => Row(
                      children: [
                        Icon(category.icon, size: 20, color: category.color),
                        const SizedBox(width: 8),
                        Text(category.label),
                      ],
                    ),
                  ),

                  // Category-specific fields
                  if (_category == TaskCategory.work) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Project Code',
                      hint: 'e.g., PROJ-123',
                      required: true,
                      error: _fieldErrors['projectCode'],
                      onChanged: (value) {
                        _customFields['projectCode'] = value;
                        _hasChanges = true;
                      },
                      initialValue: _customFields['projectCode']?.toString(),
                    ),
                  ],

                  if (_category == TaskCategory.finance) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Amount',
                      hint: 'e.g., 1000.00',
                      keyboardType: TextInputType.number,
                      error: _fieldErrors['amount'],
                      onChanged: (value) {
                        _customFields['amount'] = value;
                        _hasChanges = true;
                      },
                      initialValue: _customFields['amount']?.toString(),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Due date and time
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Due Date',
                          value: _dueDate,
                          onTap: _selectDueDate,
                          error: _fieldErrors['dueDate'],
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeField(
                            label: 'Due Time',
                            value: _dueTime,
                            onTap: _selectDueTime,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress slider (only if status is in progress)
                  if (_status == TaskStatus.inProgress ||
                      _status == TaskStatus.review) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _progress,
                          onChanged: (value) {
                            setState(() {
                              _progress = value;
                              _hasChanges = true;
                            });
                          },
                          divisions: 10,
                          label: '${(_progress * 100).toInt()}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Estimated hours
                  _buildTextField(
                    controller: _estimatedHoursController,
                    label: 'Estimated Hours',
                    hint: 'e.g., 8',
                    keyboardType: TextInputType.number,
                    error: _fieldErrors['estimatedHours'],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  _buildTextField(
                    controller: _tagsController,
                    label: 'Tags',
                    hint:
                        'Separate with commas (e.g., urgent, review, frontend)',
                    helperText: 'Add tags to organize your tasks',
                  ),

                  const SizedBox(height: 24),

                  // Assignees
                  _buildSection(
                    title: 'Assignees',
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addAssignee,
                    ),
                    child: _assignees.isEmpty
                        ? Text(
                            'No assignees',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            children: _assignees.map((assignee) {
                              return Chip(
                                label: Text(assignee),
                                onDeleted: () {
                                  setState(() {
                                    _assignees.remove(assignee);
                                    _hasChanges = true;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Reminders
                  if (_dueDate != null)
                    _buildSection(
                      title: 'Reminders',
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addReminder,
                      ),
                      child: _reminders.isEmpty
                          ? Text(
                              'No reminders',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Column(
                              children: _reminders.map((reminder) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.notifications,
                                    color: theme.colorScheme.primary,
                                  ),
                                  title: Text(_formatReminderTime(reminder)),
                                  subtitle: Text(reminder.type.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _reminders.remove(reminder);
                                        _hasChanges = true;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                  const SizedBox(height: 24),

                  // Advanced options
                  ExpansionTile(
                    title: const Text('Advanced Options'),
                    initiallyExpanded: _showAdvancedOptions,
                    onExpansionChanged: (expanded) {
                      setState(() => _showAdvancedOptions = expanded);
                    },
                    children: [
                      // Recurring task
                      SwitchListTile(
                        title: const Text('Recurring Task'),
                        subtitle: const Text('Repeat this task on a schedule'),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                            _hasChanges = true;
                          });
                        },
                      ),

                      if (_isRecurring) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown<RecurrenceType>(
                                      label: 'Repeat',
                                      value: _recurrenceType,
                                      items: RecurrenceType.values,
                                      onChanged: (value) {
                                        setState(() {
                                          _recurrenceType = value!;
                                          _hasChanges = true;
                                        });
                                      },
                                      itemBuilder: (type) => Text(type.name),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 100,
                                    child: _buildTextField(
                                      label: 'Interval',
                                      hint: '1',
                                      keyboardType: TextInputType.number,
                                      error: _fieldErrors['recurrenceInterval'],
                                      onChanged: (value) {
                                        _recurrenceInterval =
                                            int.tryParse(value) ?? 1;
                                        _hasChanges = true;
                                      },
                                      initialValue:
                                          _recurrenceInterval.toString(),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDateField(
                                label: 'End Date',
                                value: _recurrenceEndDate,
                                onTap: _selectRecurrenceEndDate,
                                error: _fieldErrors['recurrenceEndDate'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ui.button(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          variant: ButtonVariant.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ui.button(
                          label: widget.task == null
                              ? 'Create Task'
                              : 'Update Task',
                          onPressed: _saveTask,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? label,
    String? hint,
    String? helperText,
    String? error,
    String? initialValue,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label != null ? '$label${required ? ' *' : ''}' : null,
        hintText: hint,
        helperText: helperText,
        errorText: error,
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: itemBuilder(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    String? error,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Select date',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: value != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null ? value.format(context) : 'Select time',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: value != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  String _formatReminderTime(TaskReminder reminder) {
    final now = DateTime.now();
    final diff = reminder.reminderTime.difference(now);

    if (diff.isNegative) {
      return 'Past reminder';
    }

    if (diff.inDays > 0) {
      return '${diff.inDays} days before';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours before';
    } else {
      return '${diff.inMinutes} minutes before';
    }
  }
}

/// Dialog for adding reminders
class _ReminderDialog extends StatefulWidget {
  final DateTime dueDate;
  final Function(TaskReminder) onAdd;

  const _ReminderDialog({
    required this.dueDate,
    required this.onAdd,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  int _daysBefore = 1;
  int _hoursBefore = 0;
  ReminderType _type = ReminderType.notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days before',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _daysBefore,
                      items: List.generate(7, (i) => i).map((days) {
                        return DropdownMenuItem(
                          value: days,
                          child: Text('$days'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _daysBefore = value!);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours before',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _hoursBefore,
                      items: List.generate(24, (i) => i).map((hours) {
                        return DropdownMenuItem(
                          value: hours,
                          child: Text('$hours'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _hoursBefore = value!);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReminderType>(
            value: _type,
            items: ReminderType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _type = value!);
            },
            decoration: const InputDecoration(
              labelText: 'Reminder Type',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reminderTime = widget.dueDate.subtract(
              Duration(days: _daysBefore, hours: _hoursBefore),
            );

            final reminder = TaskReminder(
              id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
              reminderTime: reminderTime,
              type: _type,
            );

            widget.onAdd(reminder);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
