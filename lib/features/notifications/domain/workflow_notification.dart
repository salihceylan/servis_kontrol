class WorkflowNotification {
  const WorkflowNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.accentKey,
    required this.relatedTaskId,
    required this.relatedRevisionId,
    required this.isRead,
    required this.createdAt,
    required this.createdAtLabel,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String accentKey;
  final String? relatedTaskId;
  final String? relatedRevisionId;
  final bool isRead;
  final DateTime createdAt;
  final String createdAtLabel;

  factory WorkflowNotification.fromJson(Map<String, dynamic> json) {
    return WorkflowNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      accentKey: json['accent'] as String? ?? 'primary',
      relatedTaskId: json['related_task_id']?.toString(),
      relatedRevisionId: json['related_revision_id']?.toString(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      createdAtLabel: json['created_at_label'] as String? ?? '',
    );
  }

  WorkflowNotification copyWith({bool? isRead}) {
    return WorkflowNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      accentKey: accentKey,
      relatedTaskId: relatedTaskId,
      relatedRevisionId: relatedRevisionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      createdAtLabel: createdAtLabel,
    );
  }
}

class NotificationCenterSnapshot {
  const NotificationCenterSnapshot({
    required this.unreadCount,
    required this.items,
  });

  final int unreadCount;
  final List<WorkflowNotification> items;

  factory NotificationCenterSnapshot.fromJson(Map<String, dynamic> json) {
    return NotificationCenterSnapshot(
      unreadCount: json['unread_count'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                WorkflowNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
