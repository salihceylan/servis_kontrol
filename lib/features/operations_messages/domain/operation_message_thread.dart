class OperationMessageContact {
  const OperationMessageContact({
    required this.id,
    required this.name,
    required this.email,
    required this.roleCode,
    required this.roleLabel,
    required this.teamName,
  });

  final String id;
  final String name;
  final String email;
  final String roleCode;
  final String roleLabel;
  final String teamName;

  factory OperationMessageContact.fromJson(Map<String, dynamic> json) {
    return OperationMessageContact(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleCode: json['role_code'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
    );
  }
}

class OperationMessageItem {
  const OperationMessageItem({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String? senderUserId;
  final String senderName;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  factory OperationMessageItem.fromJson(Map<String, dynamic> json) {
    return OperationMessageItem(
      id: json['id']?.toString() ?? '',
      senderUserId: json['sender_user_id']?.toString(),
      senderName: json['sender_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isMine: json['is_mine'] as bool? ?? false,
    );
  }
}

class OperationMessageThread {
  const OperationMessageThread({
    required this.id,
    required this.title,
    required this.counterpartId,
    required this.counterpartName,
    required this.counterpartRole,
    required this.counterpartRoleLabel,
    required this.counterpartTeamName,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.updatedAt,
    required this.lastMessageAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final String? counterpartId;
  final String counterpartName;
  final String counterpartRole;
  final String counterpartRoleLabel;
  final String counterpartTeamName;
  final String lastMessagePreview;
  final int unreadCount;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final List<OperationMessageItem> messages;

  factory OperationMessageThread.fromJson(Map<String, dynamic> json) {
    return OperationMessageThread(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      counterpartId: json['counterpart_id']?.toString(),
      counterpartName: json['counterpart_name'] as String? ?? '',
      counterpartRole: json['counterpart_role'] as String? ?? '',
      counterpartRoleLabel: json['counterpart_role_label'] as String? ?? '',
      counterpartTeamName: json['counterpart_team_name'] as String? ?? '',
      lastMessagePreview: json['last_message_preview'] as String? ?? '',
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      lastMessageAt: DateTime.tryParse(
        json['last_message_at'] as String? ?? '',
      ),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OperationMessageItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  OperationMessageThread copyWith({
    String? id,
    String? title,
    String? counterpartId,
    String? counterpartName,
    String? counterpartRole,
    String? counterpartRoleLabel,
    String? counterpartTeamName,
    String? lastMessagePreview,
    int? unreadCount,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    List<OperationMessageItem>? messages,
  }) {
    return OperationMessageThread(
      id: id ?? this.id,
      title: title ?? this.title,
      counterpartId: counterpartId ?? this.counterpartId,
      counterpartName: counterpartName ?? this.counterpartName,
      counterpartRole: counterpartRole ?? this.counterpartRole,
      counterpartRoleLabel: counterpartRoleLabel ?? this.counterpartRoleLabel,
      counterpartTeamName: counterpartTeamName ?? this.counterpartTeamName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }
}

class OperationMessageInboxSnapshot {
  const OperationMessageInboxSnapshot({
    required this.threads,
    required this.contacts,
    required this.pollIntervalSeconds,
  });

  final List<OperationMessageThread> threads;
  final List<OperationMessageContact> contacts;
  final int pollIntervalSeconds;

  factory OperationMessageInboxSnapshot.fromJson(Map<String, dynamic> json) {
    return OperationMessageInboxSnapshot(
      threads: (json['threads'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OperationMessageThread.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      contacts: (json['contacts'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OperationMessageContact.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      pollIntervalSeconds: json['poll_interval_seconds'] as int? ?? 8,
    );
  }
}
