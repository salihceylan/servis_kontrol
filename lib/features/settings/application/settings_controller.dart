import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/settings/data/api_settings_repository.dart';
import 'package:servis_kontrol/features/settings/data/settings_repository.dart';
import 'package:servis_kontrol/features/settings/domain/general_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required ApiClient apiClient,
    SettingsRepository? repository,
  }) : _repository = repository ?? ApiSettingsRepository(apiClient) {
    load();
  }

  final SettingsRepository _repository;
  GeneralSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  GeneralSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasData => _settings != null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _repository.load();
    } on ApiException catch (error) {
      _settings = null;
      _errorMessage = error.message;
    } catch (_) {
      _settings = null;
      _errorMessage = 'Ayarlar alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(GeneralSettings settings) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _repository.save(settings);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Ayarlar kaydedilemedi.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
