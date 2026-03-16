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

enum TaskCommentKind { comment, managerNote, coordination, fieldUpdate }

extension TaskCommentKindX on TaskCommentKind {
  String get apiValue => switch (this) {
    TaskCommentKind.comment => 'comment',
    TaskCommentKind.managerNote => 'manager_note',
    TaskCommentKind.coordination => 'coordination',
    TaskCommentKind.fieldUpdate => 'field_update',
  };
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.priority,
    this.projectId,
    this.teamId,
    this.plannedStartAt,
    this.dueAt,
    this.estimatedMinutes,
    this.tag,
    this.serviceLocation,
    this.contactName,
    this.contactPhone,
    this.accessNotes,
    this.expectedOutcome,
    this.managerBrief,
    this.leadBrief,
  });

  final String title;
  final String description;
  final String? projectId;
  final String? teamId;
  final String assigneeId;
  final TaskPriority priority;
  final DateTime? plannedStartAt;
  final DateTime? dueAt;
  final int? estimatedMinutes;
  final String? tag;
  final String? serviceLocation;
  final String? contactName;
  final String? contactPhone;
  final String? accessNotes;
  final String? expectedOutcome;
  final String? managerBrief;
  final String? leadBrief;

  Map<String, dynamic> toJson() {
    final normalizedTag = tag?.trim() ?? '';
    final normalizedLocation = serviceLocation?.trim() ?? '';
    final normalizedContactName = contactName?.trim() ?? '';
    final normalizedContactPhone = contactPhone?.trim() ?? '';
    final normalizedAccessNotes = accessNotes?.trim() ?? '';
    final normalizedExpectedOutcome = expectedOutcome?.trim() ?? '';
    final normalizedManagerBrief = managerBrief?.trim() ?? '';
    final normalizedLeadBrief = leadBrief?.trim() ?? '';

    return {
      'title': title.trim(),
      'description': description.trim(),
      if (projectId != null && projectId!.isNotEmpty) 'project_id': projectId,
      if (teamId != null && teamId!.isNotEmpty) 'team_id': teamId,
      'assignee_id': assigneeId,
      'priority': priority.apiValue,
      if (plannedStartAt != null)
        'planned_start_at': plannedStartAt!.toIso8601String(),
      if (dueAt != null) 'due_at': dueAt!.toIso8601String(),
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (normalizedTag.isNotEmpty) 'tag': normalizedTag,
      if (normalizedLocation.isNotEmpty) 'service_location': normalizedLocation,
      if (normalizedContactName.isNotEmpty)
        'contact_name': normalizedContactName,
      if (normalizedContactPhone.isNotEmpty)
        'contact_phone': normalizedContactPhone,
      if (normalizedAccessNotes.isNotEmpty)
        'access_notes': normalizedAccessNotes,
      if (normalizedExpectedOutcome.isNotEmpty)
        'expected_outcome': normalizedExpectedOutcome,
      if (normalizedManagerBrief.isNotEmpty)
        'manager_brief': normalizedManagerBrief,
      if (normalizedLeadBrief.isNotEmpty) 'lead_brief': normalizedLeadBrief,
    };
  }
}

class TaskStartDraft {
  const TaskStartDraft({this.startNote});

  final String? startNote;

  Map<String, dynamic> toJson() {
    final normalizedStartNote = startNote?.trim() ?? '';
    return {
      if (normalizedStartNote.isNotEmpty) 'start_note': normalizedStartNote,
    };
  }
}

class TaskSubmissionDraft {
  const TaskSubmissionDraft({
    required this.completionSummary,
    this.fieldNotes,
    this.blockerNotes,
    this.actualMinutes,
  });

  final String completionSummary;
  final String? fieldNotes;
  final String? blockerNotes;
  final int? actualMinutes;

  Map<String, dynamic> toJson() {
    final normalizedFieldNotes = fieldNotes?.trim() ?? '';
    final normalizedBlockerNotes = blockerNotes?.trim() ?? '';
    return {
      'completion_summary': completionSummary.trim(),
      if (normalizedFieldNotes.isNotEmpty) 'field_notes': normalizedFieldNotes,
      if (normalizedBlockerNotes.isNotEmpty)
        'blocker_notes': normalizedBlockerNotes,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
    };
  }
}
