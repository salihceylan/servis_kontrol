import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class TaskFormOption {
  const TaskFormOption({required this.id, required this.label, this.groupId});

  final String id;
  final String label;
  final String? groupId;

  factory TaskFormOption.fromJson(Map<String, dynamic> json) {
    return TaskFormOption(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? '',
      groupId: json['group_id']?.toString(),
    );
  }
}

class TaskComposerSnapshot {
  const TaskComposerSnapshot({
    required this.teams,
    required this.projects,
    required this.assignees,
    required this.tagSuggestions,
  });

  final List<TaskFormOption> teams;
  final List<TaskFormOption> projects;
  final List<TaskFormOption> assignees;
  final List<String> tagSuggestions;

  factory TaskComposerSnapshot.fromJson(Map<String, dynamic> json) {
    final teams = (json['teams'] as List<dynamic>? ?? const [])
        .map((item) => TaskFormOption.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final projects = (json['projects'] as List<dynamic>? ?? const [])
        .map((item) => TaskFormOption.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final assignees = (json['assignees'] as List<dynamic>? ?? const [])
        .map((item) => TaskFormOption.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final tagSuggestions =
        (json['tag_suggestions'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);

    return TaskComposerSnapshot(
      teams: teams,
      projects: projects,
      assignees: assignees,
      tagSuggestions: tagSuggestions,
    );
  }

  TaskComposerSnapshot copyWith({
    List<TaskFormOption>? teams,
    List<TaskFormOption>? projects,
    List<TaskFormOption>? assignees,
    List<String>? tagSuggestions,
  }) {
    return TaskComposerSnapshot(
      teams: teams ?? this.teams,
      projects: projects ?? this.projects,
      assignees: assignees ?? this.assignees,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.priority,
    this.projectId,
    this.teamId,
    this.dueAt,
    this.estimatedMinutes,
    this.tag,
  });

  final String title;
  final String description;
  final String? projectId;
  final String? teamId;
  final String assigneeId;
  final TaskPriority priority;
  final DateTime? dueAt;
  final int? estimatedMinutes;
  final String? tag;

  Map<String, dynamic> toJson() {
    final normalizedTag = tag?.trim() ?? '';

    return {
      'title': title.trim(),
      'description': description.trim(),
      if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
      if (teamId != null && teamId!.isNotEmpty) 'team_id': teamId,
      'assignee_id': assigneeId,
      'priority': priority.apiValue,
      if (dueAt != null) 'due_at': dueAt!.toIso8601String(),
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (normalizedTag.isNotEmpty) 'tag': normalizedTag,
    };
  }
}
