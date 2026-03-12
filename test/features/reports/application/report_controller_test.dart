import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/reports/application/report_controller.dart';
import 'package:servis_kontrol/features/reports/data/report_repository.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';
import '../../../support/test_support.dart';

void main() {
  test('rapor olusturma akisi hazir kayda doner', () async {
    final controller = ReportController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeReportRepository(),
    );

    await controller.load();
    expect(controller.runs, isNotEmpty);

    controller.updateTypeFilter(ReportType.performance);
    controller.updateTeamFilter('Saha Ekibi');
    await Future<void>.delayed(Duration.zero);

    await controller.createReport(
      scope: 'Saha Ekibi',
      format: ReportFormat.pdf,
    );

    expect(controller.creating, isFalse);
    expect(controller.runs.first.title, 'Performans Raporu');
    expect(controller.runs.first.status, ReportRunStatus.ready);
  });
}

class _FakeReportRepository implements ReportRepository {
  final List<ReportRun> _runs = [
    const ReportRun(
      id: 'seed',
      title: 'Operasyon Raporu',
      scope: 'Tum Sirket',
      format: ReportFormat.pdf,
      createdAtLabel: '12 Mar 2026',
      status: ReportRunStatus.ready,
    ),
  ];

  @override
  Future<ReportSnapshot> load({
    String? team,
    String? user,
    ReportType? type,
  }) async {
    return ReportSnapshot(
      metrics: const [
        ReportMetric(label: 'Toplam', value: '4', caption: 'Hazir'),
      ],
      statusCounts: const [
        ReportStatusCount(label: 'Hazir', count: 4),
      ],
      activities: const [
        ReportActivity(title: 'Rapor guncellendi', subtitle: 'Hazir'),
      ],
      teamOptions: const ['Saha Ekibi'],
      userOptions: const ['Merve'],
      runs: _runs,
    );
  }

  @override
  Future<ReportRun> createReport({
    required String scope,
    required ReportType type,
    required ReportFormat format,
    String? team,
    String? user,
  }) async {
    final run = ReportRun(
      id: 'new-run',
      title: '${type.label} Raporu',
      scope: scope,
      format: format,
      createdAtLabel: '12 Mar 2026',
      status: ReportRunStatus.ready,
    );
    _runs.insert(0, run);
    return run;
  }
}
