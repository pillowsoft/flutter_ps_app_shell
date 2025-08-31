import 'dart:math';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import '../models/task_model.dart';

/// Task repository for managing tasks with database integration
class TaskRepository {
  static TaskRepository? _instance;
  static TaskRepository get instance => _instance ??= TaskRepository._();

  TaskRepository._();

  final DatabaseService _db = DatabaseService.instance;
  final _random = Random();

  static const String _collectionName = 'tasks';

  /// Generate sample tasks for demo
  Future<void> generateSampleData({int count = 50}) async {
    final tasks = <Task>[];

    for (int i = 0; i < count; i++) {
      tasks.add(_generateRandomTask());
    }

    // Save to database
    for (final task in tasks) {
      await _db.create(_collectionName, task.toJson());
    }

    AppShellLogger.i('Generated $count sample tasks');
  }

  Task _generateRandomTask() {
    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        _random.nextInt(10000).toString();
    final now = DateTime.now();

    final titles = [
      'Review quarterly report',
      'Call client about project updates',
      'Prepare presentation slides',
      'Update documentation',
      'Fix critical bug in production',
      'Schedule team meeting',
      'Submit expense report',
      'Complete code review',
      'Write unit tests',
      'Deploy new feature',
      'Update project roadmap',
      'Research new technologies',
      'Optimize database queries',
      'Design new UI mockups',
      'Conduct user interviews',
      'Analyze performance metrics',
      'Plan sprint backlog',
      'Create marketing campaign',
      'Review security audit',
      'Update dependencies',
      'Write blog post',
      'Prepare training materials',
      'Setup CI/CD pipeline',
      'Refactor legacy code',
      'Implement new API endpoint',
    ];

    final descriptions = [
      'This task requires immediate attention and careful consideration of all aspects.',
      'Please ensure all stakeholders are informed about the progress.',
      'Follow the established guidelines and best practices.',
      'Coordinate with the team to ensure smooth execution.',
      'Review previous implementations for reference.',
      'Consider performance implications and scalability.',
      'Document all changes and decisions made.',
      'Test thoroughly before marking as complete.',
      null, // Some tasks without descriptions
      null,
    ];

    final tags = [
      ['urgent', 'client'],
      ['development', 'backend'],
      ['design', 'ui/ux'],
      ['documentation'],
      ['meeting', 'team'],
      ['bug', 'production'],
      ['feature', 'new'],
      ['optimization'],
      ['research'],
      [],
    ];

    final assignees = [
      ['John Doe'],
      ['Jane Smith'],
      ['Bob Johnson'],
      ['Alice Williams'],
      ['John Doe', 'Jane Smith'],
      ['Bob Johnson', 'Alice Williams'],
      [],
    ];

    final priority =
        TaskPriority.values[_random.nextInt(TaskPriority.values.length)];
    final status = TaskStatus.values[
        _random.nextInt(TaskStatus.values.length - 1)]; // Exclude archived
    final category =
        TaskCategory.values[_random.nextInt(TaskCategory.values.length)];

    // Create dates
    final createdAt = now.subtract(Duration(days: _random.nextInt(30)));
    DateTime? dueDate;
    DateTime? completedAt;

    // 70% chance of having a due date
    if (_random.nextDouble() < 0.7) {
      dueDate = createdAt.add(Duration(days: _random.nextInt(60)));
    }

    // If status is done, set completed date
    if (status == TaskStatus.done) {
      completedAt = dueDate != null && dueDate.isBefore(now)
          ? dueDate.subtract(Duration(days: _random.nextInt(3)))
          : now.subtract(Duration(days: _random.nextInt(5)));
    }

    // Progress based on status
    double progress = 0.0;
    switch (status) {
      case TaskStatus.todo:
        progress = 0.0;
        break;
      case TaskStatus.inProgress:
        progress = 0.2 + _random.nextDouble() * 0.5;
        break;
      case TaskStatus.review:
        progress = 0.7 + _random.nextDouble() * 0.2;
        break;
      case TaskStatus.done:
        progress = 1.0;
        break;
      case TaskStatus.archived:
        progress = 1.0;
        break;
    }

    // Generate comments for some tasks
    final comments = <TaskComment>[];
    if (_random.nextDouble() < 0.3) {
      final commentCount = _random.nextInt(5) + 1;
      for (int i = 0; i < commentCount; i++) {
        comments.add(_generateComment(createdAt));
      }
    }

    // Generate attachments for some tasks
    final attachments = <TaskAttachment>[];
    if (_random.nextDouble() < 0.2) {
      final attachmentCount = _random.nextInt(3) + 1;
      for (int i = 0; i < attachmentCount; i++) {
        attachments.add(_generateAttachment(createdAt));
      }
    }

    // Recurring tasks (10% chance)
    bool isRecurring = _random.nextDouble() < 0.1;
    RecurrencePattern? recurrence;
    if (isRecurring) {
      recurrence = RecurrencePattern(
        type: RecurrenceType
            .values[_random.nextInt(RecurrenceType.values.length)],
        interval: _random.nextInt(3) + 1,
        endDate: now.add(Duration(days: 90)),
      );
    }

    // Estimated hours for some tasks
    int? estimatedHours;
    int? actualHours;
    if (_random.nextDouble() < 0.4) {
      estimatedHours = _random.nextInt(40) + 1;
      if (status == TaskStatus.done) {
        actualHours =
            estimatedHours + _random.nextInt(10) - 5; // +/- 5 hours variance
        if (actualHours < 1) actualHours = 1;
      }
    }

    // Reminders for high priority tasks with due dates
    final reminders = <TaskReminder>[];
    if (priority == TaskPriority.high || priority == TaskPriority.critical) {
      if (dueDate != null && dueDate.isAfter(now)) {
        reminders.add(TaskReminder(
          id: 'reminder_$id',
          reminderTime: dueDate.subtract(Duration(days: 1)),
          type: ReminderType.notification,
        ));
      }
    }

    return Task(
      id: id,
      title: titles[_random.nextInt(titles.length)],
      description: descriptions[_random.nextInt(descriptions.length)],
      priority: priority,
      status: status,
      category: category,
      createdAt: createdAt,
      dueDate: dueDate,
      completedAt: completedAt,
      tags: List<String>.from(tags[_random.nextInt(tags.length)]),
      assignees:
          List<String>.from(assignees[_random.nextInt(assignees.length)]),
      attachments: attachments,
      comments: comments,
      estimatedHours: estimatedHours,
      actualHours: actualHours,
      progress: progress,
      isRecurring: isRecurring,
      recurrence: recurrence,
      reminders: reminders,
    );
  }

  TaskComment _generateComment(DateTime taskCreatedAt) {
    final commentTexts = [
      'Looks good to me!',
      'I have some concerns about this approach.',
      'Can we discuss this in the next meeting?',
      'Great progress so far.',
      'I think we need to reconsider the timeline.',
      'The client approved this change.',
      'Please see my attached feedback.',
      '@John Doe Can you take a look at this?',
      'This is blocked by the API changes.',
      'Ready for review.',
    ];

    final authors = [
      ('user1', 'John Doe'),
      ('user2', 'Jane Smith'),
      ('user3', 'Bob Johnson'),
      ('user4', 'Alice Williams'),
    ];

    final author = authors[_random.nextInt(authors.length)];
    final createdAt = taskCreatedAt.add(Duration(
      days: _random.nextInt(10),
      hours: _random.nextInt(24),
    ));

    return TaskComment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      text: commentTexts[_random.nextInt(commentTexts.length)],
      authorId: author.$1,
      authorName: author.$2,
      createdAt: createdAt,
      mentions: _random.nextDouble() < 0.3 ? ['@John Doe'] : [],
    );
  }

  TaskAttachment _generateAttachment(DateTime taskCreatedAt) {
    final attachments = [
      ('document.pdf', 'application/pdf', 245678),
      ('spreadsheet.xlsx', 'application/vnd.ms-excel', 189234),
      ('presentation.pptx', 'application/vnd.ms-powerpoint', 567890),
      ('image.png', 'image/png', 123456),
      ('screenshot.jpg', 'image/jpeg', 98765),
      ('notes.txt', 'text/plain', 4567),
      ('design.sketch', 'application/sketch', 789012),
      ('data.csv', 'text/csv', 34567),
    ];

    final attachment = attachments[_random.nextInt(attachments.length)];
    final uploadedAt = taskCreatedAt.add(Duration(
      days: _random.nextInt(5),
      hours: _random.nextInt(24),
    ));

    return TaskAttachment(
      id: 'attach_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      fileName: attachment.$1,
      fileType: attachment.$2,
      fileSize: attachment.$3,
      uploadedAt: uploadedAt,
      uploadedBy: 'User ${_random.nextInt(4) + 1}',
    );
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks() async {
    final docs = await _db.findByType(_collectionName);
    return docs.map((doc) => Task.fromJson(doc)).toList();
  }

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    // Temporarily use getAll and filter in-memory
    final allTasks = await getAll();
    return allTasks.where((task) => task.status == status).toList();
  }

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    // Temporarily use getAll and filter in-memory
    final allTasks = await getAll();
    return allTasks.where((task) => task.category == category).toList();
  }

  /// Get high priority tasks
  Future<List<Task>> getHighPriorityTasks() async {
    final docs = await _db.findByType(_collectionName);
    final tasks = docs.map((doc) => Task.fromJson(doc)).toList();
    return tasks.where((task) => task.isHighPriority).toList();
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    final docs = await _db.findByType(_collectionName);
    final tasks = docs.map((doc) => Task.fromJson(doc)).toList();
    return tasks.where((task) => task.isOverdue).toList();
  }

  /// Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    final docs = await _db.findByType(_collectionName);
    final tasks = docs.map((doc) => Task.fromJson(doc)).toList();
    return tasks.where((task) => task.isDueToday).toList();
  }

  /// Create a new task
  Future<String> createTask(Task task) async {
    final id = await _db.create(_collectionName, task.toJson());
    return id.toString();
  }

  /// Update a task
  Future<bool> updateTask(String id, Task task) async {
    return await _db.update(int.parse(id), task.toJson());
  }

  /// Delete a task
  Future<bool> deleteTask(String id) async {
    return await _db.delete(int.parse(id));
  }

  /// Watch tasks stream
  Stream<List<Task>> watchTasks() {
    return _db.watchByType(_collectionName).map((docs) {
      return docs.map((doc) => Task.fromJson(doc)).toList();
    });
  }

  /// Get task statistics
  Future<TaskStatistics> getStatistics() async {
    final tasks = await getAllTasks();

    int todoCount = 0;
    int inProgressCount = 0;
    int doneCount = 0;
    int overdueCount = 0;
    int highPriorityCount = 0;
    double totalProgress = 0;

    final categoryCount = <TaskCategory, int>{};

    for (final task in tasks) {
      // Status counts
      switch (task.status) {
        case TaskStatus.todo:
          todoCount++;
          break;
        case TaskStatus.inProgress:
          inProgressCount++;
          break;
        case TaskStatus.done:
          doneCount++;
          break;
        default:
          break;
      }

      // Other counts
      if (task.isOverdue) overdueCount++;
      if (task.isHighPriority) highPriorityCount++;

      // Category distribution
      categoryCount[task.category] = (categoryCount[task.category] ?? 0) + 1;

      // Progress
      totalProgress += task.progress;
    }

    return TaskStatistics(
      totalTasks: tasks.length,
      todoCount: todoCount,
      inProgressCount: inProgressCount,
      doneCount: doneCount,
      overdueCount: overdueCount,
      highPriorityCount: highPriorityCount,
      averageProgress: tasks.isEmpty ? 0 : totalProgress / tasks.length,
      categoryDistribution: categoryCount,
    );
  }
}

/// Task statistics
class TaskStatistics {
  final int totalTasks;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final int overdueCount;
  final int highPriorityCount;
  final double averageProgress;
  final Map<TaskCategory, int> categoryDistribution;

  TaskStatistics({
    required this.totalTasks,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.overdueCount,
    required this.highPriorityCount,
    required this.averageProgress,
    required this.categoryDistribution,
  });

  double get completionRate => totalTasks == 0 ? 0 : doneCount / totalTasks;
  double get overdueRate => totalTasks == 0 ? 0 : overdueCount / totalTasks;
}
