import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/application/mock_revision_repository.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

class RevisionMetric {
  const RevisionMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class RevisionController extends ChangeNotifier {
  RevisionController({
    required AppUser user,
    MockRevisionRepository? repository,
  })  : _user = user,
        _repository = repository ?? const MockRevisionRepository() {
    _items = _repository.loadFor(user);
    if (_items.isNotEmpty) {
      _selectedId = _items.first.id;
    }
  }

  final AppUser _user;
  final MockRevisionRepository _repository;
  late List<RevisionItem> _items;
  String _query = '';
  String? _selectedId;

  UserRole get role => _user.role;
  String get query => _query;

  void updateQuery(String value) {
    _query = value;
    _ensureSelection();
    notifyListeners();
  }

  List<RevisionItem> get filteredItems {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _sorted(_items);
    }

    return _sorted(
      _items.where((item) {
        return item.title.toLowerCase().contains(normalized) ||
            item.project.toLowerCase().contains(normalized) ||
            item.owner.toLowerCase().contains(normalized) ||
            item.category.toLowerCase().contains(normalized);
      }).toList(),
    );
  }

  List<RevisionItem> get pendingItems => filteredItems
      .where((item) => item.stage == RevisionStage.pendingReview)
      .toList();

  List<RevisionItem> get revisionItems => filteredItems
      .where((item) => item.stage == RevisionStage.inRevision)
      .toList();

  List<RevisionItem> get completedItems => filteredItems
      .where((item) => item.stage == RevisionStage.completed)
      .toList();

  RevisionItem? get selectedItem {
    final currentItems = filteredItems;
    if (currentItems.isEmpty) {
      return null;
    }

    final selected = currentItems.cast<RevisionItem?>().firstWhere(
      (item) => item?.id == _selectedId,
      orElse: () => null,
    );
    return selected ?? currentItems.first;
  }

  List<RevisionMetric> get metrics {
    final pending = _items
        .where((item) => item.stage == RevisionStage.pendingReview)
        .length;
    final revision = _items
        .where((item) => item.stage == RevisionStage.inRevision)
        .length;
    final completed = _items
        .where((item) => item.stage == RevisionStage.completed)
        .length;
    final warnings = _items.where((item) => item.earlyWarning).length;

    return [
      RevisionMetric(
        label: 'İnceleme Bekleyen',
        value: '$pending',
        caption: 'Karar bekleyen iş sayısı',
      ),
      RevisionMetric(
        label: 'Revizyonda',
        value: '$revision',
        caption: 'Geri gönderilen görevler',
      ),
      RevisionMetric(
        label: 'Tamamlanan',
        value: '$completed',
        caption: 'Onayı kapanan revizyonlar',
      ),
      RevisionMetric(
        label: 'Erken Uyarı',
        value: '$warnings',
        caption: 'Eşik aşan görev sayısı',
      ),
    ];
  }

  void selectItem(String id) {
    _selectedId = id;
    notifyListeners();
  }

  void approveSelected() {
    final item = selectedItem;
    if (item == null) {
      return;
    }

    _writeItem(
      item.copyWith(
        stage: RevisionStage.completed,
        updatedAt: DateTime.now(),
        performanceReady: true,
        clearRevisionReason: true,
        histories: [
          RevisionHistoryEntry(
            title: 'Onaylandı',
            detail: 'Revizyon kapatıldı ve performans verisi üretildi.',
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...item.histories,
        ],
      ),
    );
  }

  void requestRevision(String reason) {
    final item = selectedItem;
    final normalized = reason.trim();
    if (item == null || normalized.isEmpty) {
      return;
    }

    final nextCount = item.revisionCount + 1;
    final warning = nextCount >= 3;
    final detail = warning
        ? '$normalized Erken uyarı tetiklendi, yönetici bayrağı açıldı ve e-posta/Slack bildirimi gönderildi.'
        : '$normalized Çalışana bildirim ve açıklama gönderildi.';

    _writeItem(
      item.copyWith(
        stage: RevisionStage.inRevision,
        revisionCount: nextCount,
        revisionReason: normalized,
        updatedAt: DateTime.now(),
        earlyWarning: warning,
        performanceReady: false,
        histories: [
          RevisionHistoryEntry(
            title: 'Revizyon istendi',
            detail: detail,
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...item.histories,
        ],
      ),
    );
  }

  void markEmployeeUpdated(String note) {
    final item = selectedItem;
    final normalized = note.trim();
    if (item == null || normalized.isEmpty) {
      return;
    }

    _writeItem(
      item.copyWith(
        stage: RevisionStage.pendingReview,
        updatedAt: DateTime.now(),
        histories: [
          RevisionHistoryEntry(
            title: 'Çalışan güncelledi',
            detail: normalized,
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...item.histories,
        ],
      ),
    );
  }

  void _writeItem(RevisionItem updated) {
    _items = [
      for (final item in _items) if (item.id == updated.id) updated else item,
    ];
    _selectedId = updated.id;
    _ensureSelection();
    notifyListeners();
  }

  void _ensureSelection() {
    final items = filteredItems;
    if (items.isEmpty) {
      _selectedId = null;
      return;
    }
    final exists = items.any((item) => item.id == _selectedId);
    if (!exists) {
      _selectedId = items.first.id;
    }
  }

  List<RevisionItem> _sorted(List<RevisionItem> items) {
    final copy = [...items];
    copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return copy;
  }
}
