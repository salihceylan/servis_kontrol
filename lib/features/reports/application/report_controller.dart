import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/reports/data/api_report_repository.dart';
import 'package:servis_kontrol/features/reports/data/report_repository.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class ReportController extends ChangeNotifier {
  ReportController({
    required AppUser user,
    required ApiClient apiClient,
    ReportRepository? repository,
  })  : _user = user,
        _repository = repository ?? ApiReportRepository(apiClient) {
    load();
  }

  final AppUser _user;
  final ReportRepository _repository;

  List<ReportMetric> _metrics = const [];
  List<ReportStatusCount> _statusCounts = const [];
  List<ReportActivity> _activities = const [];
  List<String> _teamOptions = const [];
  List<String> _userOptions = const [];
  List<ReportRun> _runs = const [];

  String? _teamFilter;
  String? _userFilter;
  ReportType _typeFilter = ReportType.operational;
  bool _creating = false;
  bool _isLoading = true;
  String? _errorMessage;

  List<ReportMetric> get metrics => _metrics;
  List<ReportStatusCount> get statusCounts => _statusCounts;
  List<ReportActivity> get activities => _activities;
  List<String> get teamOptions => _teamOptions;
  List<String> get userOptions => _userOptions;
  List<ReportRun> get runs => _runs;
  String? get teamFilter => _teamFilter;
  String? get userFilter => _userFilter;
  ReportType get typeFilter => _typeFilter;
  bool get creating => _creating;
  bool get canEmail => _user.email.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _metrics.isNotEmpty || _runs.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.load(
        team: _teamFilter,
        user: _userFilter,
        type: _typeFilter,
      );
      _metrics = snapshot.metrics;
      _statusCounts = snapshot.statusCounts;
      _activities = snapshot.activities;
      _teamOptions = snapshot.teamOptions;
      _userOptions = snapshot.userOptions;
      _runs = snapshot.runs;
    } on ApiException catch (error) {
      _metrics = const [];
      _statusCounts = const [];
      _activities = const [];
      _teamOptions = const [];
      _userOptions = const [];
      _runs = const [];
      _errorMessage = error.message;
    } catch (_) {
      _metrics = const [];
      _statusCounts = const [];
      _activities = const [];
      _teamOptions = const [];
      _userOptions = const [];
      _runs = const [];
      _errorMessage = 'Rapor verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateTeamFilter(String? value) {
    _teamFilter = value;
    load();
  }

  void updateUserFilter(String? value) {
    _userFilter = value;
    load();
  }

  void updateTypeFilter(ReportType value) {
    _typeFilter = value;
    load();
  }

  Future<bool> createReport({
    required String scope,
    required ReportFormat format,
  }) async {
    _creating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final run = await _repository.createReport(
        scope: scope,
        type: _typeFilter,
        format: format,
        team: _teamFilter,
        user: _userFilter,
      );
      _runs = [run, ..._runs.where((item) => item.id != run.id)];
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Rapor oluşturulamadı.';
      return false;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }
}
