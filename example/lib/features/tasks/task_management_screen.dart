import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import '../../models/task_model.dart';
import '../../repositories/task_repository.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';
import 'dart:async';

/// Comprehensive task management screen showcasing advanced features
class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with TickerProviderStateMixin {
  final TaskRepository _repository = TaskRepository.instance;

  // Animation controllers
  late AnimationController _listAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScale;

  // Data
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  TaskStatistics? _statistics;
  bool _isLoading = true;
  String? _error;

  // Filters and sorting
  TaskStatus? _statusFilter;
  TaskCategory? _categoryFilter;
  TaskPriority? _priorityFilter;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dueDate;
  bool _showOverdueOnly = false;

  // UI state
  bool _isGridView = false;
  bool _showStatistics = true;
  final Set<String> _selectedTaskIds = {};
  bool _isSelectionMode = false;

  // Stream subscription
  StreamSubscription<List<Task>>? _taskSubscription;

  // Search debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTasks();
    _setupTaskStream();
  }

  void _initializeAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabAnimationController.forward();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);

      // Check if we need to generate sample data
      final existingTasks = await _repository.getAllTasks();
      if (existingTasks.isEmpty) {
        await _repository.generateSampleData(count: 30);
      }

      final tasks = await _repository.getAllTasks();
      final statistics = await _repository.getStatistics();

      setState(() {
        _tasks = tasks;
        _statistics = statistics;
        _isLoading = false;
        _error = null;
      });

      _applyFilters();
      _listAnimationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupTaskStream() {
    _taskSubscription = _repository.watchTasks().listen((tasks) {
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
        _applyFilters();
        _updateStatistics();
      }
    });
  }

  Future<void> _updateStatistics() async {
    final statistics = await _repository.getStatistics();
    if (mounted) {
      setState(() => _statistics = statistics);
    }
  }

  void _applyFilters() {
    List<Task> filtered = List.from(_tasks);

    // Apply status filter
    if (_statusFilter != null) {
      filtered =
          filtered.where((task) => task.status == _statusFilter).toList();
    }

    // Apply category filter
    if (_categoryFilter != null) {
      filtered =
          filtered.where((task) => task.category == _categoryFilter).toList();
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      filtered =
          filtered.where((task) => task.priority == _priorityFilter).toList();
    }

    // Apply overdue filter
    if (_showOverdueOnly) {
      filtered = filtered.where((task) => task.isOverdue).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
            (task.description?.toLowerCase().contains(query) ?? false) ||
            task.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case SortOption.priority:
          return b.priority.index.compareTo(a.priority.index);
        case SortOption.status:
          return a.status.index.compareTo(b.status.index);
        case SortOption.title:
          return a.title.compareTo(b.title);
        case SortOption.createdDate:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.progress:
          return b.progress.compareTo(a.progress);
      }
    });

    setState(() {
      _filteredTasks = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _applyFilters();
    });
  }

  Future<void> _createTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormScreen(),
      ),
    );

    if (result != null) {
      await _repository.createTask(result);
      _showSnackBar('Task created successfully');
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result != null) {
      await _repository.updateTask(task.id, result);
      _showSnackBar('Task updated successfully');
    }
  }

  Future<void> _viewTaskDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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
      await _repository.deleteTask(task.id);
      _showSnackBar('Task deleted');
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedTaskIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Delete ${_selectedTaskIds.length} selected tasks?'),
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
      for (final id in _selectedTaskIds) {
        await _repository.deleteTask(id);
      }
      setState(() {
        _selectedTaskIds.clear();
        _isSelectionMode = false;
      });
      _showSnackBar('${_selectedTaskIds.length} tasks deleted');
    }
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final updatedTask = task.copyWith(
      status: newStatus,
      completedAt: newStatus == TaskStatus.done ? DateTime.now() : null,
      progress: newStatus == TaskStatus.done ? 1.0 : task.progress,
    );

    await _repository.updateTask(task.id, updatedTask);

    // Haptic feedback
    HapticFeedback.lightImpact();

    _showSnackBar('Task ${newStatus.label.toLowerCase()}');
  }

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedTaskIds.clear();
      _selectedTaskIds.addAll(_filteredTasks.map((t) => t.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTaskIds.clear();
      _isSelectionMode = false;
    });
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
  void dispose() {
    _listAnimationController.dispose();
    _fabAnimationController.dispose();
    _taskSubscription?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
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
        key: ValueKey('task_management_scaffold_$uiSystem'),
        appBar: _buildAppBar(theme),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView(ui)
                : _buildContent(theme, ui),
        floatingActionButton: _buildFAB(theme),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: _isSelectionMode
          ? Text('${_selectedTaskIds.length} selected')
          : const Text('Task Management'),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _bulkDelete,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelection,
            tooltip: 'Cancel',
          ),
        ] else ...[
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: Icon(
                _showStatistics ? Icons.analytics_outlined : Icons.analytics),
            onPressed: () => setState(() => _showStatistics = !_showStatistics),
            tooltip: 'Toggle Statistics',
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (option) {
              setState(() => _sortOption = option);
              _applyFilters();
            },
            itemBuilder: (context) => SortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      _sortOption == option ? Icons.check : null,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Column(
      children: [
        // Search and filters
        _buildSearchAndFilters(theme, ui),

        // Statistics
        if (_showStatistics && _statistics != null) _buildStatistics(theme, ui),

        // Task list/grid
        Expanded(
          child: _filteredTasks.isEmpty
              ? _buildEmptyState(theme)
              : _isGridView
                  ? _buildGridView(theme, ui)
                  : _buildListView(theme, ui),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, AdaptiveWidgetFactory ui) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                _buildFilterChip(
                  label: _statusFilter?.label ?? 'All Status',
                  icon: Icons.flag,
                  isSelected: _statusFilter != null,
                  onTap: () => _showStatusFilterDialog(theme),
                  onClear: _statusFilter != null
                      ? () {
                          setState(() => _statusFilter = null);
                          _applyFilters();
                        }
                      : null,
                ),

                const SizedBox(width: 8),

                // Category filter
                _buildFilterChip(
                  label: _categoryFilter?.label ?? 'All Categories',
                  icon: Icons.category,
                  isSelected: _categoryFilter != null,
                  onTap: () => _showCategoryFilterDialog(theme),
                  onClear: _categoryFilter != null
                      ? () {
                          setState(() => _categoryFilter = null);
                          _applyFilters();
                        }
                      : null,
                ),

                const SizedBox(width: 8),

                // Priority filter
                _buildFilterChip(
                  label: _priorityFilter?.label ?? 'All Priorities',
                  icon: Icons.priority_high,
                  isSelected: _priorityFilter != null,
                  onTap: () => _showPriorityFilterDialog(theme),
                  onClear: _priorityFilter != null
                      ? () {
                          setState(() => _priorityFilter = null);
                          _applyFilters();
                        }
                      : null,
                ),

                const SizedBox(width: 8),

                // Overdue filter
                _buildFilterChip(
                  label: 'Overdue',
                  icon: Icons.warning,
                  isSelected: _showOverdueOnly,
                  color: Colors.red,
                  onTap: () {
                    setState(() => _showOverdueOnly = !_showOverdueOnly);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? (color ?? theme.colorScheme.primary).withValues(alpha: 0.2)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color)),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 16, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme, AdaptiveWidgetFactory ui) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showStatistics ? 120 : 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildStatCard(
              title: 'Total',
              value: _statistics!.totalTasks.toString(),
              icon: Icons.task,
              color: theme.colorScheme.primary,
            ),
            _buildStatCard(
              title: 'To Do',
              value: _statistics!.todoCount.toString(),
              icon: Icons.pending,
              color: Colors.grey,
            ),
            _buildStatCard(
              title: 'In Progress',
              value: _statistics!.inProgressCount.toString(),
              icon: Icons.play_arrow,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Done',
              value: _statistics!.doneCount.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Overdue',
              value: _statistics!.overdueCount.toString(),
              icon: Icons.warning,
              color: Colors.red,
            ),
            _buildStatCard(
              title: 'Completion',
              value:
                  '${(_statistics!.completionRate * 100).toStringAsFixed(0)}%',
              icon: Icons.pie_chart,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ThemeData theme, AdaptiveWidgetFactory ui) {
    return AnimatedList(
      initialItemCount: _filteredTasks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index, animation) {
        if (index >= _filteredTasks.length) return const SizedBox();

        final task = _filteredTasks[index];

        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1, 0), end: Offset.zero).chain(
              CurveTween(curve: Curves.easeOut),
            ),
          ),
          child: _buildTaskCard(task, theme, ui),
        );
      },
    );
  }

  Widget _buildGridView(ThemeData theme, AdaptiveWidgetFactory ui) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskGridCard(task, theme, ui);
      },
    );
  }

  Widget _buildTaskCard(Task task, ThemeData theme, AdaptiveWidgetFactory ui) {
    final isSelected = _selectedTaskIds.contains(task.id);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _updateTaskStatus(task, TaskStatus.done);
          return false;
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: Text('Delete "${task.title}"?'),
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
        }
      },
      onDismissed: (_) => _deleteTask(task),
      child: GestureDetector(
        onLongPress: () {
          setState(() => _isSelectionMode = true);
          _toggleSelection(task.id);
        },
        child: ui.card(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Material(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleSelection(task.id)
                  : () => _viewTaskDetails(task),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status indicator and checkbox
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(task.id),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: task.status.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          task.category.icon,
                          color: task.category.color,
                          size: 20,
                        ),
                      ),

                    const SizedBox(width: 12),

                    // Task details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.status == TaskStatus.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              Icon(
                                task.priority.icon,
                                color: task.priority.color,
                                size: 20,
                              ),
                            ],
                          ),
                          if (task.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Due date
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: task.isOverdue
                                      ? Colors.red
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(task.dueDate!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: task.isOverdue
                                        ? Colors.red
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              // Progress
                              if (task.progress > 0) ...[
                                SizedBox(
                                  width: 50,
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: task.progress,
                                    backgroundColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(
                                      task.status.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(task.progress * 100).toInt()}%',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 12),
                              ],

                              // Tags
                              if (task.tags.isNotEmpty) ...[
                                Icon(
                                  Icons.label,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.tags.length.toString(),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick actions
                    if (!_isSelectionMode)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editTask(task);
                              break;
                            case 'delete':
                              _deleteTask(task);
                              break;
                            case 'done':
                              _updateTaskStatus(task, TaskStatus.done);
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
                          if (task.status != TaskStatus.done)
                            const PopupMenuItem(
                              value: 'done',
                              child: Row(
                                children: [
                                  Icon(Icons.check, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mark Done'),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskGridCard(
      Task task, ThemeData theme, AdaptiveWidgetFactory ui) {
    final isSelected = _selectedTaskIds.contains(task.id);

    return GestureDetector(
      onLongPress: () {
        setState(() => _isSelectionMode = true);
        _toggleSelection(task.id);
      },
      child: ui.card(
        padding: EdgeInsets.zero,
        child: Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _isSelectionMode
                ? () => _toggleSelection(task.id)
                : () => _viewTaskDetails(task),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: task.category.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          task.category.icon,
                          color: task.category.color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      if (_isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(task.id),
                        )
                      else
                        Icon(
                          task.priority.icon,
                          color: task.priority.color,
                          size: 20,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Progress bar
                  if (task.progress > 0) ...[
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(task.status.color),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Due date
                  if (task.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: task.isOverdue
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDueDate(task.dueDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: task.isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _statusFilter != null ||
                    _categoryFilter != null
                ? 'Try adjusting your filters'
                : 'Create your first task to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AdaptiveWidgetFactory ui) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load tasks'),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ui.button(
            label: 'Retry',
            onPressed: _loadTasks,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Future<void> _showStatusFilterDialog(ThemeData theme) async {
    final selected = await showDialog<TaskStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('All Status'),
          ),
          ...TaskStatus.values.map((status) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, status),
                child: Row(
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
              )),
        ],
      ),
    );

    if (selected != _statusFilter) {
      setState(() => _statusFilter = selected);
      _applyFilters();
    }
  }

  Future<void> _showCategoryFilterDialog(ThemeData theme) async {
    final selected = await showDialog<TaskCategory>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Category'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('All Categories'),
          ),
          ...TaskCategory.values.map((category) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, category),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 20),
                    const SizedBox(width: 8),
                    Text(category.label),
                  ],
                ),
              )),
        ],
      ),
    );

    if (selected != _categoryFilter) {
      setState(() => _categoryFilter = selected);
      _applyFilters();
    }
  }

  Future<void> _showPriorityFilterDialog(ThemeData theme) async {
    final selected = await showDialog<TaskPriority>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Priority'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('All Priorities'),
          ),
          ...TaskPriority.values.map((priority) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, priority),
                child: Row(
                  children: [
                    Icon(priority.icon, color: priority.color, size: 20),
                    const SizedBox(width: 8),
                    Text(priority.label),
                  ],
                ),
              )),
        ],
      ),
    );

    if (selected != _priorityFilter) {
      setState(() => _priorityFilter = selected);
      _applyFilters();
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (dateOnly.isBefore(today)) {
      final days = today.difference(dateOnly).inDays;
      return '$days days overdue';
    } else {
      final days = dateOnly.difference(today).inDays;
      if (days <= 7) {
        return 'In $days days';
      } else {
        return '${date.day}/${date.month}';
      }
    }
  }
}

enum SortOption {
  dueDate,
  priority,
  status,
  title,
  createdDate,
  progress;

  String get label {
    switch (this) {
      case SortOption.dueDate:
        return 'Due Date';
      case SortOption.priority:
        return 'Priority';
      case SortOption.status:
        return 'Status';
      case SortOption.title:
        return 'Title';
      case SortOption.createdDate:
        return 'Created Date';
      case SortOption.progress:
        return 'Progress';
    }
  }
}
