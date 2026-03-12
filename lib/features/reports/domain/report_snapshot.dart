enum ReportType { operational, performance, revision, delivery }

extension ReportTypeX on ReportType {
  String get label => switch (this) {
    ReportType.operational => 'Operasyon',
    ReportType.performance => 'Performans',
    ReportType.revision => 'Revizyon',
    ReportType.delivery => 'Teslim',
  };

  String get apiValue => switch (this) {
    ReportType.operational => 'operational',
    ReportType.performance => 'performance',
    ReportType.revision => 'revision',
    ReportType.delivery => 'delivery',
  };
}

ReportType reportTypeFromApi(String? value) => switch (value) {
  'performance' => ReportType.performance,
  'revision' => ReportType.revision,
  'delivery' => ReportType.delivery,
  _ => ReportType.operational,
};

enum ReportFormat { pdf, excel }

extension ReportFormatX on ReportFormat {
  String get label => switch (this) {
    ReportFormat.pdf => 'PDF',
    ReportFormat.excel => 'Excel',
  };

  String get apiValue => switch (this) {
    ReportFormat.pdf => 'pdf',
    ReportFormat.excel => 'excel',
  };
}

ReportFormat reportFormatFromApi(String? value) => switch (value) {
  'excel' => ReportFormat.excel,
  _ => ReportFormat.pdf,
};

class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  factory ReportMetric.fromJson(Map<String, dynamic> json) {
    return ReportMetric(
      label: json['label'] as String? ?? '',
      value: '${json['value'] ?? ''}',
      caption: json['caption'] as String? ?? '',
    );
  }
}

class ReportStatusCount {
  const ReportStatusCount({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  factory ReportStatusCount.fromJson(Map<String, dynamic> json) {
    return ReportStatusCount(
      label: json['label'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class ReportActivity {
  const ReportActivity({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  factory ReportActivity.fromJson(Map<String, dynamic> json) {
    return ReportActivity(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

enum ReportRunStatus { preparing, ready }

ReportRunStatus reportRunStatusFromApi(String? value) => switch (value) {
  'ready' => ReportRunStatus.ready,
  _ => ReportRunStatus.preparing,
};

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

  factory ReportRun.fromJson(Map<String, dynamic> json) {
    return ReportRun(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      format: reportFormatFromApi(json['format'] as String?),
      createdAtLabel: json['created_at_label'] as String? ?? '',
      status: reportRunStatusFromApi(json['status'] as String?),
    );
  }

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

  factory ReportSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      String key,
      T Function(Map<String, dynamic> json) parser,
    ) {
      final source = json[key] as List<dynamic>? ?? const [];
      return source
          .map((item) => parser(item as Map<String, dynamic>))
          .toList(growable: false);
    }

    List<String> readStrings(String key) {
      final source = json[key] as List<dynamic>? ?? const [];
      return source.map((item) => '$item').toList(growable: false);
    }

    return ReportSnapshot(
      metrics: readList('metrics', ReportMetric.fromJson),
      statusCounts: readList('status_counts', ReportStatusCount.fromJson),
      activities: readList('activities', ReportActivity.fromJson),
      teamOptions: readStrings('team_options'),
      userOptions: readStrings('user_options'),
      runs: readList('runs', ReportRun.fromJson),
    );
  }
}
