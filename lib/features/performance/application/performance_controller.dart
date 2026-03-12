import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/performance/application/mock_performance_repository.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

class PerformanceController extends ChangeNotifier {
  PerformanceController({
    required AppUser user,
    MockPerformanceRepository? repository,
  })  : _user = user,
        _repository = repository ?? const MockPerformanceRepository() {
    _load();
  }

  final AppUser _user;
  final MockPerformanceRepository _repository;

  PerformanceRange _range = PerformanceRange.last30Days;
  PerformanceSnapshot? _snapshot;

  PerformanceRange get range => _range;
  PerformanceSnapshot get snapshot => _snapshot!;

  void updateRange(PerformanceRange value) {
    if (_range == value) {
      return;
    }
    _range = value;
    _load();
    notifyListeners();
  }

  void _load() {
    _snapshot = _repository.loadFor(_user, _range);
  }
}
