enum PerformanceRange { last30Days, last6Months }

extension PerformanceRangeX on PerformanceRange {
  String get label => switch (this) {
    PerformanceRange.last30Days => 'Son 30 Gün',
    PerformanceRange.last6Months => 'Son 6 Ay',
  };
}

class PerformanceMetric {
  const PerformanceMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
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
}
