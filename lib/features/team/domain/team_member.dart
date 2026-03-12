enum MemberRiskLevel { low, medium, high }

extension MemberRiskLevelX on MemberRiskLevel {
  String get label => switch (this) {
    MemberRiskLevel.low => 'Düşük Risk',
    MemberRiskLevel.medium => 'İzle',
    MemberRiskLevel.high => 'Kritik',
  };

  String get apiValue => switch (this) {
    MemberRiskLevel.low => 'low',
    MemberRiskLevel.medium => 'medium',
    MemberRiskLevel.high => 'high',
  };
}

MemberRiskLevel memberRiskLevelFromApi(String? value) => switch (value) {
  'high' => MemberRiskLevel.high,
  'medium' => MemberRiskLevel.medium,
  _ => MemberRiskLevel.low,
};

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.activeTasks,
    required this.completedTasks,
    required this.performanceScore,
    required this.focusNote,
    required this.riskLevel,
    this.lastManagerNote,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final int activeTasks;
  final int completedTasks;
  final int performanceScore;
  final String focusNote;
  final MemberRiskLevel riskLevel;
  final String? lastManagerNote;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
      activeTasks: json['active_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      performanceScore: json['performance_score'] as int? ?? 0,
      focusNote: json['focus_note'] as String? ?? '',
      riskLevel: memberRiskLevelFromApi(json['risk_level'] as String?),
      lastManagerNote: json['last_manager_note'] as String?,
    );
  }

  TeamMember copyWith({
    String? id,
    String? name,
    String? role,
    String? status,
    int? activeTasks,
    int? completedTasks,
    int? performanceScore,
    String? focusNote,
    MemberRiskLevel? riskLevel,
    String? lastManagerNote,
    bool clearManagerNote = false,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      activeTasks: activeTasks ?? this.activeTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      performanceScore: performanceScore ?? this.performanceScore,
      focusNote: focusNote ?? this.focusNote,
      riskLevel: riskLevel ?? this.riskLevel,
      lastManagerNote: clearManagerNote
          ? null
          : (lastManagerNote ?? this.lastManagerNote),
    );
  }
}

class TeamCorrection {
  const TeamCorrection({
    required this.id,
    required this.title,
    required this.owner,
    required this.summary,
    required this.ageLabel,
  });

  final String id;
  final String title;
  final String owner;
  final String summary;
  final String ageLabel;

  factory TeamCorrection.fromJson(Map<String, dynamic> json) {
    return TeamCorrection(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      ageLabel: json['age_label'] as String? ?? '',
    );
  }
}

class TeamAlert {
  const TeamAlert({
    required this.id,
    required this.title,
    required this.detail,
    required this.project,
    required this.riskLevel,
  });

  final String id;
  final String title;
  final String detail;
  final String project;
  final MemberRiskLevel riskLevel;

  factory TeamAlert.fromJson(Map<String, dynamic> json) {
    return TeamAlert(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      project: json['project'] as String? ?? '',
      riskLevel: memberRiskLevelFromApi(json['risk_level'] as String?),
    );
  }
}
