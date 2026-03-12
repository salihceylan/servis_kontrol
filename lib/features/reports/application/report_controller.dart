import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/reports/application/mock_report_repository.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class ReportController extends ChangeNotifier {
  ReportController({
    required AppUser user,
    MockReportRepository? repository,
  })  : _user = user,
        _repository = repository ?? const MockReportRepository() {
    final snapshot = _repository.loadFor(user);
    _metrics = snapshot.metrics;
    _statusCounts = snapshot.statusCounts;
    _activities = snapshot.activities;
    _teamOptions = snapshot.teamOptions;
    _userOptions = snapshot.userOptions;
    _runs = snapshot.runs;
  }

  final AppUser _user;
  final MockReportRepository _repository;

  late final List<ReportMetric> _metrics;
  late final List<ReportStatusCount> _statusCounts;
  late final List<ReportActivity> _activities;
  late final List<String> _teamOptions;
  late final List<String> _userOptions;
  late List<ReportRun> _runs;

  String? _teamFilter;
  String? _userFilter;
  ReportType _typeFilter = ReportType.operational;
  bool _creating = false;

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

  void updateTeamFilter(String? value) {
    _teamFilter = value;
    notifyListeners();
  }

  void updateUserFilter(String? value) {
    _userFilter = value;
    notifyListeners();
  }

  void updateTypeFilter(ReportType value) {
    _typeFilter = value;
    notifyListeners();
  }

  Future<void> createReport({
    required String scope,
    required ReportFormat format,
  }) async {
    _creating = true;
    final newRun = ReportRun(
      id: 'run-${_runs.length + 1}',
      title: '${_typeFilter.label} Raporu',
      scope: scope,
      format: format,
      createdAtLabel: 'Hazırlanıyor',
      status: ReportRunStatus.preparing,
    );
    _runs = [newRun, ..._runs];
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    _runs = [
      newRun.copyWith(
        createdAtLabel: 'Bugün 10:10',
        status: ReportRunStatus.ready,
      ),
      ..._runs.where((run) => run.id != newRun.id),
    ];
    _creating = false;
    notifyListeners();
  }
}
