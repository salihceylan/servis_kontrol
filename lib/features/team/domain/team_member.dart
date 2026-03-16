enum MemberRiskLevel { low, medium, high }

extension MemberRiskLevelX on MemberRiskLevel {
  String get label => switch (this) {
    MemberRiskLevel.low => 'Dusuk Risk',
    MemberRiskLevel.medium => 'Izle',
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
    required this.capacityPercent,
    required this.trackedHoursLabel,
    required this.workloadStatusLabel,
    this.userCode = '',
    this.loginName = '',
    this.roleCode = 'employee',
    this.statusCode = 'active',
    this.email = '',
    this.phone = '',
    this.department = '',
    this.jobTitle = '',
    this.workPreference = '',
    this.teamId,
    this.teamName,
    this.permissions = const <String>{},
    this.canEdit = false,
    this.lastManagerNote,
  });

  final String id;
  final String userCode;
  final String loginName;
  final String name;
  final String role;
  final String roleCode;
  final String status;
  final String statusCode;
  final String email;
  final String phone;
  final String department;
  final String jobTitle;
  final String workPreference;
  final String? teamId;
  final String? teamName;
  final int activeTasks;
  final int completedTasks;
  final int performanceScore;
  final String focusNote;
  final MemberRiskLevel riskLevel;
  final double capacityPercent;
  final String trackedHoursLabel;
  final String workloadStatusLabel;
  final Set<String> permissions;
  final bool canEdit;
  final String? lastManagerNote;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final permissions = (json['permissions'] as List<dynamic>? ?? const [])
        .map((item) => '$item')
        .toSet();

    return TeamMember(
      id: json['id']?.toString() ?? '',
      userCode: json['user_code']?.toString() ?? '',
      loginName: json['login_name']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleCode: json['role_code'] as String? ?? 'employee',
      status: json['status'] as String? ?? '',
      statusCode: json['status_code'] as String? ?? 'active',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      department: json['department'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? '',
      workPreference: json['work_preference'] as String? ?? '',
      teamId: json['team_id']?.toString(),
      teamName: json['team_name'] as String?,
      activeTasks: json['active_tasks'] as int? ?? 0,
      completedTasks: json['completed_tasks'] as int? ?? 0,
      performanceScore: json['performance_score'] as int? ?? 0,
      focusNote: json['focus_note'] as String? ?? '',
      riskLevel: memberRiskLevelFromApi(json['risk_level'] as String?),
      capacityPercent: (json['capacity_percent'] as num?)?.toDouble() ?? 0,
      trackedHoursLabel: json['tracked_hours_label'] as String? ?? '',
      workloadStatusLabel: json['workload_status_label'] as String? ?? '',
      permissions: permissions,
      canEdit: json['can_edit'] as bool? ?? false,
      lastManagerNote: json['last_manager_note'] as String?,
    );
  }

  TeamMember copyWith({
    String? id,
    String? userCode,
    String? loginName,
    String? name,
    String? role,
    String? roleCode,
    String? status,
    String? statusCode,
    String? email,
    String? phone,
    String? department,
    String? jobTitle,
    String? workPreference,
    String? teamId,
    String? teamName,
    int? activeTasks,
    int? completedTasks,
    int? performanceScore,
    String? focusNote,
    MemberRiskLevel? riskLevel,
    double? capacityPercent,
    String? trackedHoursLabel,
    String? workloadStatusLabel,
    Set<String>? permissions,
    bool? canEdit,
    String? lastManagerNote,
    bool clearManagerNote = false,
  }) {
    return TeamMember(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      loginName: loginName ?? this.loginName,
      name: name ?? this.name,
      role: role ?? this.role,
      roleCode: roleCode ?? this.roleCode,
      status: status ?? this.status,
      statusCode: statusCode ?? this.statusCode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      workPreference: workPreference ?? this.workPreference,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      activeTasks: activeTasks ?? this.activeTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      performanceScore: performanceScore ?? this.performanceScore,
      focusNote: focusNote ?? this.focusNote,
      riskLevel: riskLevel ?? this.riskLevel,
      capacityPercent: capacityPercent ?? this.capacityPercent,
      trackedHoursLabel: trackedHoursLabel ?? this.trackedHoursLabel,
      workloadStatusLabel: workloadStatusLabel ?? this.workloadStatusLabel,
      permissions: permissions ?? this.permissions,
      canEdit: canEdit ?? this.canEdit,
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

class ManagedTeam {
  const ManagedTeam({
    required this.id,
    required this.name,
    required this.code,
    required this.memberCount,
    required this.activeTaskCount,
    this.managerUserId,
    this.managerName,
  });

  final String id;
  final String name;
  final String code;
  final String? managerUserId;
  final String? managerName;
  final int memberCount;
  final int activeTaskCount;

  factory ManagedTeam.fromJson(Map<String, dynamic> json) {
    return ManagedTeam(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      managerUserId: json['manager_user_id']?.toString(),
      managerName: json['manager_name'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      activeTaskCount: json['active_task_count'] as int? ?? 0,
    );
  }
}

class TeamPermissionOption {
  const TeamPermissionOption({
    required this.code,
    required this.module,
    required this.label,
    required this.description,
  });

  final String code;
  final String module;
  final String label;
  final String description;

  factory TeamPermissionOption.fromJson(Map<String, dynamic> json) {
    return TeamPermissionOption(
      code: json['code'] as String? ?? '',
      module: json['module'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class TeamRoleOption {
  const TeamRoleOption({required this.code, required this.label});

  final String code;
  final String label;

  factory TeamRoleOption.fromJson(Map<String, dynamic> json) {
    return TeamRoleOption(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
