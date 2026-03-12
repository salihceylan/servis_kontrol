enum RevisionStage { pendingReview, inRevision, completed }

extension RevisionStageX on RevisionStage {
  String get label => switch (this) {
    RevisionStage.pendingReview => 'İnceleme Bekliyor',
    RevisionStage.inRevision => 'Revizyonda',
    RevisionStage.completed => 'Tamamlandı',
  };
}

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
