import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/performance/data/api_performance_repository.dart';
import 'package:servis_kontrol/features/performance/data/performance_repository.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

class PerformanceController extends ChangeNotifier {
  PerformanceController({
    required ApiClient apiClient,
    PerformanceRepository? repository,
  }) : _repository = repository ?? ApiPerformanceRepository(apiClient) {
    load();
  }

  final PerformanceRepository _repository;

  PerformanceRange _range = PerformanceRange.last30Days;
  PerformanceSnapshot? _snapshot;
  bool _isLoading = true;
  String? _errorMessage;

  PerformanceRange get range => _range;
  PerformanceSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _snapshot != null;

  Future<void> updateRange(PerformanceRange value) async {
    if (_range == value) {
      return;
    }
    _range = value;
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load(_range);
    } on ApiException catch (error) {
      _snapshot = null;
      _errorMessage = error.message;
    } catch (_) {
      _snapshot = null;
      _errorMessage = 'Performans verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
