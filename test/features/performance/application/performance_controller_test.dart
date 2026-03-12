import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/performance/application/performance_controller.dart';
import 'package:servis_kontrol/features/performance/data/performance_repository.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';
import '../../../support/test_support.dart';

void main() {
  test('performans araligi degisince snapshot yenilenir', () async {
    final controller = PerformanceController(
      apiClient: createTestApiClient(),
      repository: _FakePerformanceRepository(),
    );

    await controller.load();
    expect(controller.snapshot!.metrics, isNotEmpty);
    expect(controller.range, PerformanceRange.last30Days);

    await controller.updateRange(PerformanceRange.last6Months);

    expect(controller.range, PerformanceRange.last6Months);
    expect(controller.snapshot!.rows, isNotEmpty);
    expect(controller.snapshot!.metrics.first.label, 'Genel Skor');
  });
}

class _FakePerformanceRepository implements PerformanceRepository {
  @override
  Future<PerformanceSnapshot> load(PerformanceRange range) async {
    return PerformanceSnapshot(
      metrics: [
        PerformanceMetric(
          label: 'Genel Skor',
          value: range == PerformanceRange.last30Days ? '80' : '82',
          caption: 'Skor',
        ),
      ],
      trendPoints: const [
        PerformanceTrendPoint(label: 'Mar', score: 82, target: 80),
      ],
      rows: const [
        TaskPerformanceRow(
          taskTitle: 'Rapor teslimi',
          owner: 'Merve',
          completedAt: '12 Mar 2026',
          revisionCount: 1,
          qualityScore: 88,
          durationLabel: '1.4 gun',
          statusLabel: 'Guvenli',
        ),
      ],
    );
  }
}
