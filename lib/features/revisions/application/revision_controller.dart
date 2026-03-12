import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/data/api_revision_repository.dart';
import 'package:servis_kontrol/features/revisions/data/revision_repository.dart';
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
    required ApiClient apiClient,
    RevisionRepository? repository,
  })  : _user = user,
        _repository = repository ?? ApiRevisionRepository(apiClient) {
    load();
  }

  final AppUser _user;
  final RevisionRepository _repository;
  List<RevisionItem> _items = const [];
  String _query = '';
  String? _selectedId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  UserRole get role => _user.role;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasData => _items.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _repository.load(query: _query);
      _ensureSelection();
    } on ApiException catch (error) {
      _items = const [];
      _selectedId = null;
      _errorMessage = error.message;
    } catch (_) {
      _items = const [];
      _selectedId = null;
      _errorMessage = 'Revizyon verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<bool> approveSelected() {
    final item = selectedItem;
    if (item == null) {
      return Future.value(false);
    }
    return _persist(() => _repository.approve(item.id));
  }

  Future<bool> requestRevision(String reason) {
    final item = selectedItem;
    final normalized = reason.trim();
    if (item == null || normalized.isEmpty) {
      return Future.value(false);
    }
    return _persist(
      () => _repository.requestRevision(
        revisionId: item.id,
        reason: normalized,
      ),
    );
  }

  Future<bool> markEmployeeUpdated(String note) {
    final item = selectedItem;
    final normalized = note.trim();
    if (item == null || normalized.isEmpty) {
      return Future.value(false);
    }
    return _persist(
      () => _repository.markEmployeeUpdated(
        revisionId: item.id,
        note: normalized,
      ),
    );
  }

  Future<bool> _persist(Future<RevisionItem> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await action();
      _writeItem(updated);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Revizyon kaydı güncellenemedi.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _writeItem(RevisionItem updated) {
    _items = [
      for (final item in _items) if (item.id == updated.id) updated else item,
    ];
    _selectedId = updated.id;
    _ensureSelection();
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
