import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/team/data/team_repository.dart';
import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';
import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';

class ApiTeamRepository implements TeamRepository {
  const ApiTeamRepository(this._client);

  final ApiClient _client;

  @override
  Future<TeamSnapshot> load({String? query, bool flaggedOnly = false}) async {
    final payload = await _client.getMap(
      'team',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (flaggedOnly) 'flagged_only': '1',
      },
    );
    return TeamSnapshot.fromJson(payload);
  }

  @override
  Future<void> addManagerNote({
    required String memberId,
    required String note,
  }) {
    return _client.postVoid(
      'team/members/$memberId/note',
      body: {'note': note},
    );
  }

  @override
  Future<TeamMember> createMember(TeamMemberDraft draft) async {
    final payload = await _client.postMap(
      'team/users',
      body: draft.toJson(includePassword: true),
    );
    return TeamMember.fromJson(
      payload['member'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<TeamMember> updateMember({
    required String memberId,
    required TeamMemberDraft draft,
  }) async {
    final payload = await _client.putMap(
      'team/users/$memberId',
      body: draft.toJson(includePassword: false),
    );
    return TeamMember.fromJson(
      payload['member'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<ManagedTeam> createTeam(TeamGroupDraft draft) async {
    final payload = await _client.postMap('team/groups', body: draft.toJson());
    return ManagedTeam.fromJson(
      payload['team'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<ManagedTeam> updateTeam({
    required String teamId,
    required TeamGroupDraft draft,
  }) async {
    final payload = await _client.putMap(
      'team/groups/$teamId',
      body: draft.toJson(),
    );
    return ManagedTeam.fromJson(
      payload['team'] as Map<String, dynamic>? ?? payload,
    );
  }
}
