import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';
import 'task_form_screen.dart';

/// Detailed task view with rich information display
class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with TickerProviderStateMixin {
  final TaskRepository _repository = TaskRepository.instance;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _progressController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _currentTask.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _editTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: _currentTask),
      ),
    );

    if (result != null) {
      await _repository.updateTask(_currentTask.id, result);
      setState(() => _currentTask = result);
      _showSnackBar('Task updated successfully');
    }
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    final updatedTask = _currentTask.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.done ? DateTime.now() : null,
      progress: newStatus == TaskStatus.done ? 1.0 : _currentTask.progress,
    );

    await _repository.updateTask(_currentTask.id, updatedTask);
    setState(() => _currentTask = updatedTask);

    // Animate progress change
    _progressController.animateTo(updatedTask.progress);

    _showSnackBar('Task ${newStatus.label.toLowerCase()}');
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content:
            Text('Are you sure you want to delete "${_currentTask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteTask(_currentTask.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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

      return Scaffold(
        key: ValueKey('task_detail_scaffold_$uiSystem'),
        appBar: AppBar(
          title: const Text('Task Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editTask,
              tooltip: 'Edit Task',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editTask();
                    break;
                  case 'delete':
                    _deleteTask();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  _buildHeaderCard(theme, ui),

                  const SizedBox(height: 16),

                  // Status and progress
                  _buildStatusCard(theme, ui),

                  const SizedBox(height: 16),

                  // Details
                  _buildDetailsCard(theme, ui),

                  const SizedBox(height: 16),

                  // Time tracking
                  if (_currentTask.estimatedHours != null ||
                      _currentTask.actualHours != null)
                    _buildTimeTrackingCard(theme, ui),

                  // Assignees
                  if (_currentTask.assignees.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAssigneesCard(theme, ui),
                  ],

                  // Tags
                  if (_currentTask.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTagsCard(theme, ui),
                  ],

                  // Recurrence
                  if (_currentTask.isRecurring) ...[
                    const SizedBox(height: 16),
                    _buildRecurrenceCard(theme, ui),
                  ],

                  // Reminders
                  if (_currentTask.reminders.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildRemindersCard(theme, ui),
                  ],

                  // Attachments
                  if (_currentTask.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAttachmentsCard(theme, ui),
                  ],

                  // Comments
                  if (_currentTask.comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCommentsCard(theme, ui),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomActions(theme, ui),
      );
    });
  }

  Widget _buildHeaderCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentTask.category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentTask.category.icon,
                  color: _currentTask.category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTask.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: _currentTask.status == TaskStatus.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _currentTask.priority.color
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentTask.priority.icon,
                                size: 14,
                                color: _currentTask.priority.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentTask.priority.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _currentTask.priority.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTask.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentTask.description != null) ...[
            const SizedBox(height: 16),
            Text(
              _currentTask.description!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _currentTask.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentTask.status.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _currentTask.status.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_currentTask.progress > 0) ...[
            const SizedBox(height: 16),
            Text(
              'Progress',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation(_currentTask.status.color),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_currentTask.progress * 100).toInt()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Created date
          _buildDetailRow(
            icon: Icons.event,
            label: 'Created',
            value: _formatDateTime(_currentTask.createdAt),
            theme: theme,
          ),

          // Due date
          if (_currentTask.dueDate != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.schedule,
              label: 'Due',
              value: _formatDateTime(_currentTask.dueDate!),
              theme: theme,
              valueColor: _currentTask.isOverdue ? Colors.red : null,
            ),
          ],

          // Completed date
          if (_currentTask.completedAt != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.check_circle,
              label: 'Completed',
              value: _formatDateTime(_currentTask.completedAt!),
              theme: theme,
              valueColor: Colors.green,
            ),
          ],

          // Custom fields
          if (_currentTask.customFields != null) ...[
            const SizedBox(height: 16),
            ..._currentTask.customFields!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDetailRow(
                  icon: Icons.info,
                  label: _formatFieldName(entry.key),
                  value: entry.value.toString(),
                  theme: theme,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTrackingCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Tracking',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentTask.estimatedHours != null) ...[
                Expanded(
                  child: _buildTimeStatCard(
                    icon: Icons.timer,
                    label: 'Estimated',
                    value: '${_currentTask.estimatedHours}h',
                    color: Colors.blue,
                    theme: theme,
                  ),
                ),
              ],
              if (_currentTask.actualHours != null) ...[
                if (_currentTask.estimatedHours != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeStatCard(
                    icon: Icons.timer_outlined,
                    label: 'Actual',
                    value: '${_currentTask.actualHours}h',
                    color: Colors.orange,
                    theme: theme,
                  ),
                ),
              ],
              if (_currentTask.estimatedHours != null &&
                  _currentTask.actualHours != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeStatCard(
                    icon: Icons.analytics,
                    label: 'Variance',
                    value: _getTimeVariance(),
                    color: _getVarianceColor(),
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneesCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignees',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentTask.assignees.map((assignee) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        assignee[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assignee,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentTask.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: theme.colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    final recurrence = _currentTask.recurrence!;

    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recurring Task',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Frequency',
            value:
                'Every ${recurrence.interval} ${recurrence.type.name}${recurrence.interval > 1 ? 's' : ''}',
            theme: theme,
          ),
          if (recurrence.endDate != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.event,
              label: 'Until',
              value: _formatDate(recurrence.endDate!),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemindersCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reminders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._currentTask.reminders.map((reminder) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getReminderIcon(reminder.type),
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(reminder.reminderTime),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: reminder.isActive
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reminder.isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: reminder.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._currentTask.attachments.map((attachment) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _getAttachmentIcon(attachment.fileType),
                color: theme.colorScheme.primary,
              ),
              title: Text(attachment.fileName),
              subtitle: Text(
                '${_formatFileSize(attachment.fileSize)} • ${_formatDate(attachment.uploadedAt)}',
              ),
              trailing: const Icon(Icons.download),
              onTap: () {
                // Handle file download/open
                _showSnackBar('File download not implemented in demo');
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentsCard(ThemeData theme, AdaptiveWidgetFactory ui) {
    return ui.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._currentTask.comments.map((comment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      comment.authorName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.authorName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(comment.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (comment.editedAt != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(edited)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme, AdaptiveWidgetFactory ui) {
    if (_currentTask.status == TaskStatus.done) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ui.button(
                  label: 'Mark as To Do',
                  onPressed: () => _updateTaskStatus(TaskStatus.todo),
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ui.button(
                  label: 'Edit Task',
                  onPressed: _editTask,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ui.button(
                label: 'Mark as Done',
                onPressed: () => _updateTaskStatus(TaskStatus.done),
                variant: ButtonVariant.primary,
              ),
            ),
            if (_currentTask.status != TaskStatus.inProgress) ...[
              const SizedBox(width: 8),
              ui.button(
                label: 'Start',
                onPressed: () => _updateTaskStatus(TaskStatus.inProgress),
                variant: ButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Today at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatFieldName(String key) {
    // Convert camelCase to readable format
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _getTimeVariance() {
    if (_currentTask.estimatedHours == null ||
        _currentTask.actualHours == null) {
      return '—';
    }

    final variance = _currentTask.actualHours! - _currentTask.estimatedHours!;
    if (variance == 0) return '±0h';
    if (variance > 0) return '+${variance}h';
    return '${variance}h';
  }

  Color _getVarianceColor() {
    if (_currentTask.estimatedHours == null ||
        _currentTask.actualHours == null) {
      return Colors.grey;
    }

    final variance = _currentTask.actualHours! - _currentTask.estimatedHours!;
    if (variance == 0) return Colors.green;
    if (variance > 0) return Colors.red;
    return Colors.green;
  }

  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.notification:
        return Icons.notifications;
      case ReminderType.email:
        return Icons.email;
      case ReminderType.sms:
        return Icons.sms;
    }
  }

  IconData _getAttachmentIcon(String fileType) {
    if (fileType.startsWith('image/')) return Icons.image;
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('excel') || fileType.contains('spreadsheet'))
      return Icons.table_chart;
    if (fileType.contains('powerpoint') || fileType.contains('presentation'))
      return Icons.slideshow;
    if (fileType.contains('word') || fileType.contains('document'))
      return Icons.description;
    return Icons.attach_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
