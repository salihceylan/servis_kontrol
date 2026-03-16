import 'package:servis_kontrol/features/team/domain/team_member.dart';

class TeamSnapshot {
  const TeamSnapshot({
    required this.members,
    required this.corrections,
    required this.alerts,
    this.teams = const [],
    this.permissionOptions = const [],
    this.roleOptions = const [],
  });

  final List<TeamMember> members;
  final List<TeamCorrection> corrections;
  final List<TeamAlert> alerts;
  final List<ManagedTeam> teams;
  final List<TeamPermissionOption> permissionOptions;
  final List<TeamRoleOption> roleOptions;

  factory TeamSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      String key,
      T Function(Map<String, dynamic> json) parser,
    ) {
      final source = json[key] as List<dynamic>? ?? const [];
      return source
          .map((item) => parser(item as Map<String, dynamic>))
          .toList(growable: false);
    }

    return TeamSnapshot(
      members: readList('members', TeamMember.fromJson),
      corrections: readList('corrections', TeamCorrection.fromJson),
      alerts: readList('alerts', TeamAlert.fromJson),
      teams: readList('teams', ManagedTeam.fromJson),
      permissionOptions: readList(
        'permission_options',
        TeamPermissionOption.fromJson,
      ),
      roleOptions: readList('role_options', TeamRoleOption.fromJson),
    );
  }
}
