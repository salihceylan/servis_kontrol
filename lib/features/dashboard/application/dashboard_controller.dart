import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/dashboard/data/api_dashboard_repository.dart';
import 'package:servis_kontrol/features/dashboard/data/dashboard_repository.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required ApiClient apiClient,
    DashboardRepository? repository,
  }) : _repository = repository ?? ApiDashboardRepository(apiClient) {
    load();
  }

  final DashboardRepository _repository;

  DashboardSnapshot? _snapshot;
  bool _isLoading = true;
  String? _errorMessage;

  DashboardSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _snapshot = null;
    } catch (_) {
      _errorMessage = 'Panel verileri yüklenemedi.';
      _snapshot = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
