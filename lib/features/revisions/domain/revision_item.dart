enum RevisionStage { pendingReview, inRevision, completed }

extension RevisionStageX on RevisionStage {
  String get label => switch (this) {
    RevisionStage.pendingReview => 'İnceleme Bekliyor',
    RevisionStage.inRevision => 'Revizyonda',
    RevisionStage.completed => 'Tamamlandı',
  };

  String get apiValue => switch (this) {
    RevisionStage.pendingReview => 'pending_review',
    RevisionStage.inRevision => 'in_revision',
    RevisionStage.completed => 'completed',
  };
}

RevisionStage revisionStageFromApi(String? value) => switch (value) {
  'in_revision' => RevisionStage.inRevision,
  'completed' => RevisionStage.completed,
  _ => RevisionStage.pendingReview,
};

class RevisionHistoryEntry {
  const RevisionHistoryEntry({
    required this.title,
    required this.detail,
    required this.actor,
    required this.timestamp,
  });

  final String title;
  final String detail;
  final String actor;
  final DateTime timestamp;

  factory RevisionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RevisionHistoryEntry(
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      actor: json['actor'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class RevisionItem {
  const RevisionItem({
    required this.id,
    required this.title,
    required this.project,
    required this.owner,
    required this.stage,
    required this.revisionCount,
    required this.updatedAt,
    required this.category,
    required this.summary,
    required this.histories,
    this.revisionReason,
    this.earlyWarning = false,
    this.performanceReady = false,
  });

  final String id;
  final String title;
  final String project;
  final String owner;
  final RevisionStage stage;
  final int revisionCount;
  final DateTime updatedAt;
  final String category;
  final String summary;
  final String? revisionReason;
  final bool earlyWarning;
  final bool performanceReady;
  final List<RevisionHistoryEntry> histories;

  factory RevisionItem.fromJson(Map<String, dynamic> json) {
    final histories = (json['histories'] as List<dynamic>? ?? const [])
        .map(
          (item) => RevisionHistoryEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);

    return RevisionItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      project: json['project'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      stage: revisionStageFromApi(json['stage'] as String?),
      revisionCount: json['revision_count'] as int? ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      category: json['category'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      revisionReason: json['revision_reason'] as String?,
      earlyWarning: json['early_warning'] as bool? ?? false,
      performanceReady: json['performance_ready'] as bool? ?? false,
      histories: histories,
    );
  }

  RevisionItem copyWith({
    String? id,
    String? title,
    String? project,
    String? owner,
    RevisionStage? stage,
    int? revisionCount,
    DateTime? updatedAt,
    String? category,
    String? summary,
    String? revisionReason,
    bool clearRevisionReason = false,
    bool? earlyWarning,
    bool? performanceReady,
    List<RevisionHistoryEntry>? histories,
  }) {
    return RevisionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      project: project ?? this.project,
      owner: owner ?? this.owner,
      stage: stage ?? this.stage,
      revisionCount: revisionCount ?? this.revisionCount,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      revisionReason: clearRevisionReason
          ? null
          : (revisionReason ?? this.revisionReason),
      earlyWarning: earlyWarning ?? this.earlyWarning,
      performanceReady: performanceReady ?? this.performanceReady,
      histories: histories ?? this.histories,
    );
  }
}
