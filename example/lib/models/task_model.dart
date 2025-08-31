import 'package:flutter/material.dart';

/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
      case TaskPriority.critical:
        return Icons.priority_high;
    }
  }
}

/// Task status
enum TaskStatus {
  todo,
  inProgress,
  review,
  done,
  archived;

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.archived:
        return Colors.grey[700]!;
    }
  }
}

/// Task category
enum TaskCategory {
  work,
  personal,
  shopping,
  health,
  finance,
  education,
  travel,
  other;

  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.finance:
        return 'Finance';
      case TaskCategory.education:
        return 'Education';
      case TaskCategory.travel:
        return 'Travel';
      case TaskCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.personal:
        return Icons.person;
      case TaskCategory.shopping:
        return Icons.shopping_cart;
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.finance:
        return Icons.attach_money;
      case TaskCategory.education:
        return Icons.school;
      case TaskCategory.travel:
        return Icons.flight;
      case TaskCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.personal:
        return Colors.purple;
      case TaskCategory.shopping:
        return Colors.orange;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.finance:
        return Colors.green;
      case TaskCategory.education:
        return Colors.indigo;
      case TaskCategory.travel:
        return Colors.teal;
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}

/// Task model
class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final List<String> assignees;
  final List<TaskAttachment> attachments;
  final List<TaskComment> comments;
  final Map<String, dynamic>? customFields;
  final int? estimatedHours;
  final int? actualHours;
  final double progress;
  final bool isRecurring;
  final RecurrencePattern? recurrence;
  final String? parentTaskId;
  final List<String> subtaskIds;
  final Location? location;
  final List<TaskReminder> reminders;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
    this.assignees = const [],
    this.attachments = const [],
    this.comments = const [],
    this.customFields,
    this.estimatedHours,
    this.actualHours,
    this.progress = 0.0,
    this.isRecurring = false,
    this.recurrence,
    this.parentTaskId,
    this.subtaskIds = const [],
    this.location,
    this.reminders = const [],
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.done || status == TaskStatus.archived)
      return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  bool get isHighPriority {
    return priority == TaskPriority.high || priority == TaskPriority.critical;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    TaskCategory? category,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
    List<String>? assignees,
    List<TaskAttachment>? attachments,
    List<TaskComment>? comments,
    Map<String, dynamic>? customFields,
    int? estimatedHours,
    int? actualHours,
    double? progress,
    bool? isRecurring,
    RecurrencePattern? recurrence,
    String? parentTaskId,
    List<String>? subtaskIds,
    Location? location,
    List<TaskReminder>? reminders,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      assignees: assignees ?? this.assignees,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      customFields: customFields ?? this.customFields,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      progress: progress ?? this.progress,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      location: location ?? this.location,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.index,
      'category': category.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'assignees': assignees,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'customFields': customFields,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'progress': progress,
      'isRecurring': isRecurring,
      'recurrence': recurrence?.toJson(),
      'parentTaskId': parentTaskId,
      'subtaskIds': subtaskIds,
      'location': location?.toJson(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TaskPriority.values[json['priority']],
      status: TaskStatus.values[json['status']],
      category: TaskCategory.values[json['category']],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      assignees: List<String>.from(json['assignees'] ?? []),
      attachments: (json['attachments'] as List?)
              ?.map((a) => TaskAttachment.fromJson(a))
              .toList() ??
          [],
      comments: (json['comments'] as List?)
              ?.map((c) => TaskComment.fromJson(c))
              .toList() ??
          [],
      customFields: json['customFields'],
      estimatedHours: json['estimatedHours'],
      actualHours: json['actualHours'],
      progress: json['progress'] ?? 0.0,
      isRecurring: json['isRecurring'] ?? false,
      recurrence: json['recurrence'] != null
          ? RecurrencePattern.fromJson(json['recurrence'])
          : null,
      parentTaskId: json['parentTaskId'],
      subtaskIds: List<String>.from(json['subtaskIds'] ?? []),
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      reminders: (json['reminders'] as List?)
              ?.map((r) => TaskReminder.fromJson(r))
              .toList() ??
          [],
    );
  }
}

/// Task attachment
class TaskAttachment {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? url;
  final DateTime uploadedAt;
  final String uploadedBy;

  TaskAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.url,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
        'url': url,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        id: json['id'],
        fileName: json['fileName'],
        fileType: json['fileType'],
        fileSize: json['fileSize'],
        url: json['url'],
        uploadedAt: DateTime.parse(json['uploadedAt']),
        uploadedBy: json['uploadedBy'],
      );
}

/// Task comment
class TaskComment {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? editedAt;
  final List<String> mentions;

  TaskComment({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.editedAt,
    this.mentions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'mentions': mentions,
      };

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        id: json['id'],
        text: json['text'],
        authorId: json['authorId'],
        authorName: json['authorName'],
        createdAt: DateTime.parse(json['createdAt']),
        editedAt:
            json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
        mentions: List<String>.from(json['mentions'] ?? []),
      );
}

/// Recurrence pattern for recurring tasks
class RecurrencePattern {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? maxOccurrences;

  RecurrencePattern({
    required this.type,
    required this.interval,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.maxOccurrences,
  });

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'interval': interval,
        'daysOfWeek': daysOfWeek,
        'dayOfMonth': dayOfMonth,
        'endDate': endDate?.toIso8601String(),
        'maxOccurrences': maxOccurrences,
      };

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) =>
      RecurrencePattern(
        type: RecurrenceType.values[json['type']],
        interval: json['interval'],
        daysOfWeek: json['daysOfWeek'] != null
            ? List<int>.from(json['daysOfWeek'])
            : null,
        dayOfMonth: json['dayOfMonth'],
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        maxOccurrences: json['maxOccurrences'],
      );
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Task location
class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'placeName': placeName,
      };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
        placeName: json['placeName'],
      );
}

/// Task reminder
class TaskReminder {
  final String id;
  final DateTime reminderTime;
  final ReminderType type;
  final bool isActive;

  TaskReminder({
    required this.id,
    required this.reminderTime,
    required this.type,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminderTime': reminderTime.toIso8601String(),
        'type': type.index,
        'isActive': isActive,
      };

  factory TaskReminder.fromJson(Map<String, dynamic> json) => TaskReminder(
        id: json['id'],
        reminderTime: DateTime.parse(json['reminderTime']),
        type: ReminderType.values[json['type']],
        isActive: json['isActive'] ?? true,
      );
}

enum ReminderType {
  notification,
  email,
  sms,
}
