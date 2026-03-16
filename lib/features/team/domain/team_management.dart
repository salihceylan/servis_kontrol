class TeamMemberDraft {
  const TeamMemberDraft({
    required this.name,
    required this.loginName,
    required this.roleCode,
    required this.statusCode,
    required this.permissionCodes,
    this.email,
    this.password,
    this.department,
    this.jobTitle,
    this.phone,
    this.teamId,
    this.workPreference,
  });

  final String name;
  final String loginName;
  final String? email;
  final String? password;
  final String roleCode;
  final String? department;
  final String? jobTitle;
  final String? phone;
  final String? teamId;
  final String? workPreference;
  final String statusCode;
  final Set<String> permissionCodes;

  Map<String, dynamic> toJson({required bool includePassword}) {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'login_name': loginName.trim().toLowerCase(),
      'email': email?.trim().toLowerCase(),
      'role_code': roleCode,
      'department': department?.trim(),
      'job_title': jobTitle?.trim(),
      'phone': phone?.trim(),
      'team_id': teamId == null || teamId!.isEmpty
          ? null
          : int.tryParse(teamId!),
      'work_preference': workPreference?.trim(),
      'status': statusCode,
      'permission_codes': permissionCodes.toList(growable: false),
    };

    if (includePassword || (password?.trim().isNotEmpty ?? false)) {
      payload['password'] = password?.trim();
    }

    return payload;
  }
}

class TeamGroupDraft {
  const TeamGroupDraft({required this.name, this.managerUserId});

  final String name;
  final String? managerUserId;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'manager_user_id': managerUserId == null || managerUserId!.isEmpty
          ? null
          : int.tryParse(managerUserId!),
    };
  }
}
