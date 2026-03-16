import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';
import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';

abstract class TeamRepository {
  Future<TeamSnapshot> load({String? query, bool flaggedOnly = false});

  Future<void> addManagerNote({required String memberId, required String note});

  Future<TeamMember> createMember(TeamMemberDraft draft);

  Future<TeamMember> updateMember({
    required String memberId,
    required TeamMemberDraft draft,
  });

  Future<ManagedTeam> createTeam(TeamGroupDraft draft);

  Future<ManagedTeam> updateTeam({
    required String teamId,
    required TeamGroupDraft draft,
  });
}
