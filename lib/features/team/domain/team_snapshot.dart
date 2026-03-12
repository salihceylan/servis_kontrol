import 'package:servis_kontrol/features/team/domain/team_member.dart';

class TeamSnapshot {
  const TeamSnapshot({
    required this.members,
    required this.corrections,
    required this.alerts,
  });

  final List<TeamMember> members;
  final List<TeamCorrection> corrections;
  final List<TeamAlert> alerts;

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
    );
  }
}
