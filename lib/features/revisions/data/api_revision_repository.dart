import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/revisions/data/revision_repository.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

class ApiRevisionRepository implements RevisionRepository {
  const ApiRevisionRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<RevisionItem>> load({String? query}) async {
    final items = await _client.getList(
      'revisions',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return items
        .map((item) => RevisionItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<RevisionItem> approve(String revisionId) async {
    final payload = await _client.postMap('revisions/$revisionId/approve');
    return RevisionItem.fromJson(
      payload['revision'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<RevisionItem> requestRevision({
    required String revisionId,
    required String reason,
  }) async {
    final payload = await _client.postMap(
      'revisions/$revisionId/request',
      body: {'reason': reason},
    );
    return RevisionItem.fromJson(
      payload['revision'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<RevisionItem> markEmployeeUpdated({
    required String revisionId,
    required String note,
  }) async {
    final payload = await _client.postMap(
      'revisions/$revisionId/employee-update',
      body: {'note': note},
    );
    return RevisionItem.fromJson(
      payload['revision'] as Map<String, dynamic>? ?? payload,
    );
  }
}
