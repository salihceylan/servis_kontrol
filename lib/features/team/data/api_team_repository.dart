import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/team/data/team_repository.dart';
import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';

class ApiTeamRepository implements TeamRepository {
  const ApiTeamRepository(this._client);

  final ApiClient _client;

  @override
  Future<TeamSnapshot> load({
    String? query,
    bool flaggedOnly = false,
  }) async {
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
}
