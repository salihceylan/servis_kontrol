enum TaskStatus { pending, inProgress, inReview, revision, delivered }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
    TaskStatus.pending => 'Beklemede',
    TaskStatus.inProgress => 'Devam Ediyor',
    TaskStatus.inReview => 'İncelemede',
    TaskStatus.revision => 'Revizyonda',
    TaskStatus.delivered => 'Teslim Edildi',
  };
}

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Düşük',
    TaskPriority.medium => 'Orta',
    TaskPriority.high => 'Yüksek',
  };
}

enum TaskDateFilter { all, today, thisWeek, overdue }

extension TaskDateFilterX on TaskDateFilter {
  String get label => switch (this) {
    TaskDateFilter.all => 'Tümü',
    TaskDateFilter.today => 'Bugün',
    TaskDateFilter.thisWeek => 'Bu Hafta',
    TaskDateFilter.overdue => 'Geciken',
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
    this.meetingLink,
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
  final String? meetingLink;

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
    String? meetingLink,
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
      meetingLink: clearMeetingLink ? null : (meetingLink ?? this.meetingLink),
    );
  }
}
