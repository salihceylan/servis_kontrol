enum TaskStatus { pending, inProgress, inReview, revision, delivered }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
    TaskStatus.pending => 'Beklemede',
    TaskStatus.inProgress => 'Devam Ediyor',
    TaskStatus.inReview => 'İncelemede',
    TaskStatus.revision => 'Revizyonda',
    TaskStatus.delivered => 'Teslim Edildi',
  };

  String get apiValue => switch (this) {
    TaskStatus.pending => 'pending',
    TaskStatus.inProgress => 'in_progress',
    TaskStatus.inReview => 'in_review',
    TaskStatus.revision => 'revision',
    TaskStatus.delivered => 'delivered',
  };
}

TaskStatus taskStatusFromApi(String? value) => switch (value) {
  'in_progress' => TaskStatus.inProgress,
  'in_review' => TaskStatus.inReview,
  'revision' => TaskStatus.revision,
  'delivered' => TaskStatus.delivered,
  _ => TaskStatus.pending,
};

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Düşük',
    TaskPriority.medium => 'Orta',
    TaskPriority.high => 'Yüksek',
  };

  String get apiValue => switch (this) {
    TaskPriority.low => 'low',
    TaskPriority.medium => 'medium',
    TaskPriority.high => 'high',
  };
}

TaskPriority taskPriorityFromApi(String? value) => switch (value) {
  'low' => TaskPriority.low,
  'high' => TaskPriority.high,
  _ => TaskPriority.medium,
};

enum TaskDateFilter { all, today, thisWeek, overdue }

extension TaskDateFilterX on TaskDateFilter {
  String get label => switch (this) {
    TaskDateFilter.all => 'Tümü',
    TaskDateFilter.today => 'Bugün',
    TaskDateFilter.thisWeek => 'Bu Hafta',
    TaskDateFilter.overdue => 'Geciken',
  };

  String get apiValue => switch (this) {
    TaskDateFilter.all => 'all',
    TaskDateFilter.today => 'today',
    TaskDateFilter.thisWeek => 'this_week',
    TaskDateFilter.overdue => 'overdue',
  };
}

class TaskTimelineEntry {
  const TaskTimelineEntry({
    required this.title,
    required this.detail,
    required this.actor,
    required this.timestamp,
  });

  final String title;
  final String detail;
  final String actor;
  final DateTime timestamp;

  factory TaskTimelineEntry.fromJson(Map<String, dynamic> json) {
    return TaskTimelineEntry(
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      actor: json['actor'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class TaskDependency {
  const TaskDependency({
    required this.title,
    required this.statusLabel,
  });

  final String title;
  final String statusLabel;

  factory TaskDependency.fromJson(Map<String, dynamic> json) {
    return TaskDependency(
      title: json['title'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
    );
  }
}

class TaskTimeEntry {
  const TaskTimeEntry({
    required this.userName,
    required this.durationLabel,
    required this.startedAtLabel,
  });

  final String userName;
  final String durationLabel;
  final String startedAtLabel;

  factory TaskTimeEntry.fromJson(Map<String, dynamic> json) {
    return TaskTimeEntry(
      userName: json['user_name'] as String? ?? '',
      durationLabel: json['duration_label'] as String? ?? '',
      startedAtLabel: json['started_at_label'] as String? ?? '',
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.project,
    required this.assignee,
    required this.status,
    required this.priority,
    required this.dueAt,
    required this.updatedAt,
    required this.tag,
    required this.description,
    required this.checklistCompleted,
    required this.checklistTotal,
    required this.timeline,
    required this.estimatedMinutes,
    required this.trackedMinutes,
    required this.blockedByCount,
    required this.subtaskCount,
    required this.dependencies,
    required this.timeEntries,
    this.meetingLink,
    this.requestSource,
  });

  final String id;
  final String title;
  final String project;
  final String assignee;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime dueAt;
  final DateTime updatedAt;
  final String tag;
  final String description;
  final int checklistCompleted;
  final int checklistTotal;
  final List<TaskTimelineEntry> timeline;
  final int estimatedMinutes;
  final int trackedMinutes;
  final int blockedByCount;
  final int subtaskCount;
  final List<TaskDependency> dependencies;
  final List<TaskTimeEntry> timeEntries;
  final String? meetingLink;
  final String? requestSource;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final timeline = (json['timeline'] as List<dynamic>? ?? const [])
        .map((item) => TaskTimelineEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final dependencies = (json['dependencies'] as List<dynamic>? ?? const [])
        .map((item) => TaskDependency.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final timeEntries = (json['time_entries'] as List<dynamic>? ?? const [])
        .map((item) => TaskTimeEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return TaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      project: json['project'] as String? ?? '',
      assignee: json['assignee'] as String? ?? '',
      status: taskStatusFromApi(json['status'] as String?),
      priority: taskPriorityFromApi(json['priority'] as String?),
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      tag: json['tag'] as String? ?? '',
      description: json['description'] as String? ?? '',
      checklistCompleted: json['checklist_completed'] as int? ?? 0,
      checklistTotal: json['checklist_total'] as int? ?? 0,
      timeline: timeline,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
      trackedMinutes: json['tracked_minutes'] as int? ?? 0,
      blockedByCount: json['blocked_by_count'] as int? ?? 0,
      subtaskCount: json['subtask_count'] as int? ?? 0,
      dependencies: dependencies,
      timeEntries: timeEntries,
      meetingLink: json['meeting_link'] as String?,
      requestSource: json['request_source'] as String?,
    );
  }

  double get progress =>
      checklistTotal == 0 ? 0 : checklistCompleted / checklistTotal;

  TaskItem copyWith({
    String? id,
    String? title,
    String? project,
    String? assignee,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
    DateTime? updatedAt,
    String? tag,
    String? description,
    int? checklistCompleted,
    int? checklistTotal,
    List<TaskTimelineEntry>? timeline,
    int? estimatedMinutes,
    int? trackedMinutes,
    int? blockedByCount,
    int? subtaskCount,
    List<TaskDependency>? dependencies,
    List<TaskTimeEntry>? timeEntries,
    String? meetingLink,
    String? requestSource,
    bool clearMeetingLink = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      project: project ?? this.project,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      checklistTotal: checklistTotal ?? this.checklistTotal,
      timeline: timeline ?? this.timeline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      trackedMinutes: trackedMinutes ?? this.trackedMinutes,
      blockedByCount: blockedByCount ?? this.blockedByCount,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      dependencies: dependencies ?? this.dependencies,
      timeEntries: timeEntries ?? this.timeEntries,
      meetingLink: clearMeetingLink ? null : (meetingLink ?? this.meetingLink),
      requestSource: requestSource ?? this.requestSource,
    );
  }
}
