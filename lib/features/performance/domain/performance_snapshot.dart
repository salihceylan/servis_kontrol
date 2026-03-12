enum PerformanceRange { last30Days, last6Months }

extension PerformanceRangeX on PerformanceRange {
  String get label => switch (this) {
    PerformanceRange.last30Days => 'Son 30 Gün',
    PerformanceRange.last6Months => 'Son 6 Ay',
  };

  String get apiValue => switch (this) {
    PerformanceRange.last30Days => 'last_30_days',
    PerformanceRange.last6Months => 'last_6_months',
  };
}

PerformanceRange performanceRangeFromApi(String? value) => switch (value) {
  'last_6_months' => PerformanceRange.last6Months,
  _ => PerformanceRange.last30Days,
};

class PerformanceMetric {
  const PerformanceMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      label: json['label'] as String? ?? '',
      value: '${json['value'] ?? ''}',
      caption: json['caption'] as String? ?? '',
    );
  }
}

class PerformanceTrendPoint {
  const PerformanceTrendPoint({
    required this.label,
    required this.score,
    required this.target,
  });

  final String label;
  final double score;
  final double target;

  factory PerformanceTrendPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceTrendPoint(
      label: json['label'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      target: (json['target'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TaskPerformanceRow {
  const TaskPerformanceRow({
    required this.taskTitle,
    required this.owner,
    required this.completedAt,
    required this.revisionCount,
    required this.qualityScore,
    required this.durationLabel,
    required this.statusLabel,
  });

  final String taskTitle;
  final String owner;
  final String completedAt;
  final int revisionCount;
  final int qualityScore;
  final String durationLabel;
  final String statusLabel;

  factory TaskPerformanceRow.fromJson(Map<String, dynamic> json) {
    return TaskPerformanceRow(
      taskTitle: json['task_title'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      completedAt: json['completed_at'] as String? ?? '',
      revisionCount: json['revision_count'] as int? ?? 0,
      qualityScore: json['quality_score'] as int? ?? 0,
      durationLabel: json['duration_label'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
    );
  }
}

class PerformanceSnapshot {
  const PerformanceSnapshot({
    required this.metrics,
    required this.trendPoints,
    required this.rows,
  });

  final List<PerformanceMetric> metrics;
  final List<PerformanceTrendPoint> trendPoints;
  final List<TaskPerformanceRow> rows;

  factory PerformanceSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      String key,
      T Function(Map<String, dynamic> json) parser,
    ) {
      final source = json[key] as List<dynamic>? ?? const [];
      return source
          .map((item) => parser(item as Map<String, dynamic>))
          .toList(growable: false);
    }

    return PerformanceSnapshot(
      metrics: readList('metrics', PerformanceMetric.fromJson),
      trendPoints: readList('trend_points', PerformanceTrendPoint.fromJson),
      rows: readList('rows', TaskPerformanceRow.fromJson),
    );
  }
}
