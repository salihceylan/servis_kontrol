enum ReportType { operational, performance, revision, delivery }

extension ReportTypeX on ReportType {
  String get label => switch (this) {
    ReportType.operational => 'Operasyon',
    ReportType.performance => 'Performans',
    ReportType.revision => 'Revizyon',
    ReportType.delivery => 'Teslim',
  };
}

enum ReportFormat { pdf, excel }

extension ReportFormatX on ReportFormat {
  String get label => switch (this) {
    ReportFormat.pdf => 'PDF',
    ReportFormat.excel => 'Excel',
  };
}

class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class ReportStatusCount {
  const ReportStatusCount({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class ReportActivity {
  const ReportActivity({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

enum ReportRunStatus { preparing, ready }

class ReportRun {
  const ReportRun({
    required this.id,
    required this.title,
    required this.scope,
    required this.format,
    required this.createdAtLabel,
    required this.status,
  });

  final String id;
  final String title;
  final String scope;
  final ReportFormat format;
  final String createdAtLabel;
  final ReportRunStatus status;

  ReportRun copyWith({
    String? id,
    String? title,
    String? scope,
    ReportFormat? format,
    String? createdAtLabel,
    ReportRunStatus? status,
  }) {
    return ReportRun(
      id: id ?? this.id,
      title: title ?? this.title,
      scope: scope ?? this.scope,
      format: format ?? this.format,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      status: status ?? this.status,
    );
  }
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.metrics,
    required this.statusCounts,
    required this.activities,
    required this.teamOptions,
    required this.userOptions,
    required this.runs,
  });

  final List<ReportMetric> metrics;
  final List<ReportStatusCount> statusCounts;
  final List<ReportActivity> activities;
  final List<String> teamOptions;
  final List<String> userOptions;
  final List<ReportRun> runs;
}
