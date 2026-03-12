enum MemberRiskLevel { low, medium, high }

extension MemberRiskLevelX on MemberRiskLevel {
  String get label => switch (this) {
    MemberRiskLevel.low => 'Düşük Risk',
    MemberRiskLevel.medium => 'İzle',
    MemberRiskLevel.high => 'Kritik',
  };
}

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
}
