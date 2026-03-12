import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/revisions/application/revision_controller.dart';
import 'package:servis_kontrol/features/revisions/data/revision_repository.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';
import '../../../support/test_support.dart';

void main() {
  test('onay ve revizyon akisleri calisir', () async {
    final controller = RevisionController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeRevisionRepository(),
    );

    await controller.load();
    expect(controller.pendingItems, isNotEmpty);

    controller.selectItem(controller.pendingItems.first.id);
    await controller.approveSelected();
    expect(controller.selectedItem!.stage, RevisionStage.completed);
    expect(controller.selectedItem!.performanceReady, isTrue);

    final revisionTarget = controller.revisionItems.first;
    controller.selectItem(revisionTarget.id);
    await controller.requestRevision('Fotograf ve toplanti notu eksik.');
    expect(controller.selectedItem!.stage, RevisionStage.inRevision);
    expect(controller.selectedItem!.revisionCount, revisionTarget.revisionCount + 1);
    expect(controller.selectedItem!.revisionReason, isNotNull);
    expect(controller.selectedItem!.earlyWarning, isTrue);
  });
}

class _FakeRevisionRepository implements RevisionRepository {
  final Map<String, RevisionItem> _items = {
    'pending': RevisionItem(
      id: 'pending',
      title: 'Panel etiketi',
      project: 'Merkez Plaza',
      owner: 'Merve',
      stage: RevisionStage.pendingReview,
      revisionCount: 0,
      updatedAt: DateTime(2026, 3, 12, 9),
      category: 'Etiket',
      summary: 'Kontrol bekliyor',
      histories: const [],
    ),
    'revision': RevisionItem(
      id: 'revision',
      title: 'Kamera notu',
      project: 'Nova Residence',
      owner: 'Onur',
      stage: RevisionStage.inRevision,
      revisionCount: 2,
      updatedAt: DateTime(2026, 3, 12, 8),
      category: 'Toplanti',
      summary: 'Eksik not var',
      revisionReason: 'Eksik not',
      histories: const [],
    ),
  };

  @override
  Future<List<RevisionItem>> load({String? query}) async {
    return _items.values.toList(growable: false);
  }

  @override
  Future<RevisionItem> approve(String revisionId) async {
    final item = _items[revisionId]!;
    final updated = item.copyWith(
      stage: RevisionStage.completed,
      performanceReady: true,
      clearRevisionReason: true,
    );
    _items[revisionId] = updated;
    return updated;
  }

  @override
  Future<RevisionItem> requestRevision({
    required String revisionId,
    required String reason,
  }) async {
    final item = _items[revisionId]!;
    final updated = item.copyWith(
      stage: RevisionStage.inRevision,
      revisionCount: item.revisionCount + 1,
      revisionReason: reason,
      earlyWarning: true,
    );
    _items[revisionId] = updated;
    return updated;
  }

  @override
  Future<RevisionItem> markEmployeeUpdated({
    required String revisionId,
    required String note,
  }) async {
    final item = _items[revisionId]!;
    final updated = item.copyWith(
      stage: RevisionStage.pendingReview,
      clearRevisionReason: true,
      histories: [
        RevisionHistoryEntry(
          title: 'Calisan guncelledi',
          detail: note,
          actor: 'Onur',
          timestamp: DateTime(2026, 3, 12, 11),
        ),
        ...item.histories,
      ],
    );
    _items[revisionId] = updated;
    return updated;
  }
}
