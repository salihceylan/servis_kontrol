import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/help/data/api_help_repository.dart';
import 'package:servis_kontrol/features/help/data/help_repository.dart';
import 'package:servis_kontrol/features/help/domain/help_center_snapshot.dart';

class HelpController extends ChangeNotifier {
  HelpController({
    required ApiClient apiClient,
    HelpRepository? repository,
  }) : _repository = repository ?? ApiHelpRepository(apiClient) {
    load();
  }

  final HelpRepository _repository;
  HelpCenterSnapshot? _snapshot;
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;

  HelpCenterSnapshot? get snapshot => _snapshot;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _snapshot != null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _snapshot = await _repository.load(query: _query);
    } on ApiException catch (error) {
      _snapshot = null;
      _errorMessage = error.message;
    } catch (_) {
      _snapshot = null;
      _errorMessage = 'Yardım merkezi verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuery(String value) {
    _query = value;
    load();
  }
}
