import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

abstract class RevisionRepository {
  Future<List<RevisionItem>> load({String? query});

  Future<RevisionItem> approve(String revisionId);

  Future<RevisionItem> requestRevision({
    required String revisionId,
    required String reason,
  });

  Future<RevisionItem> markEmployeeUpdated({
    required String revisionId,
    required String note,
  });
}
