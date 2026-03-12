import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

class MockPerformanceRepository {
  const MockPerformanceRepository();

  PerformanceSnapshot loadFor(
    AppUser user,
    PerformanceRange range,
  ) {
    return switch ((user.role, range)) {
      (UserRole.employee, PerformanceRange.last30Days) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '72',
            caption: 'Bireysel skor',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '9',
            caption: 'Son 30 günde kapanan iş',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '2.4 gün',
            caption: 'Görev kapanış ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%18',
            caption: 'İlk teslim sonrası geri dönüş',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 61, target: 75),
          PerformanceTrendPoint(label: 'Kas', score: 67, target: 75),
          PerformanceTrendPoint(label: 'Ara', score: 69, target: 75),
          PerformanceTrendPoint(label: 'Oca', score: 71, target: 76),
          PerformanceTrendPoint(label: 'Şub', score: 74, target: 76),
          PerformanceTrendPoint(label: 'Mar', score: 72, target: 76),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'UPS kapasite etiketi',
            owner: 'Onur Kaya',
            completedAt: '11 Mar 2026',
            revisionCount: 2,
            qualityScore: 69,
            durationLabel: '2.1 gün',
            statusLabel: 'İyileşiyor',
          ),
          TaskPerformanceRow(
            taskTitle: 'Merkez Plaza saha teslimi',
            owner: 'Onur Kaya',
            completedAt: '09 Mar 2026',
            revisionCount: 1,
            qualityScore: 76,
            durationLabel: '1.4 gün',
            statusLabel: 'Dengeli',
          ),
        ],
      ),
      (UserRole.employee, PerformanceRange.last6Months) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '74',
            caption: '6 aylık ortalama',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '41',
            caption: '6 ayda kapanan iş',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '2.7 gün',
            caption: 'Kapanış ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%21',
            caption: 'Revizyon döngüsü',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 61, target: 75),
          PerformanceTrendPoint(label: 'Kas', score: 67, target: 75),
          PerformanceTrendPoint(label: 'Ara', score: 69, target: 75),
          PerformanceTrendPoint(label: 'Oca', score: 71, target: 76),
          PerformanceTrendPoint(label: 'Şub', score: 74, target: 76),
          PerformanceTrendPoint(label: 'Mar', score: 72, target: 76),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'Kamera altyapısı saha kaydı',
            owner: 'Onur Kaya',
            completedAt: '04 Mar 2026',
            revisionCount: 2,
            qualityScore: 72,
            durationLabel: '2.6 gün',
            statusLabel: 'Dengeli',
          ),
          TaskPerformanceRow(
            taskTitle: 'Asansör test formu',
            owner: 'Onur Kaya',
            completedAt: '25 Şub 2026',
            revisionCount: 1,
            qualityScore: 78,
            durationLabel: '1.9 gün',
            statusLabel: 'Güvenli',
          ),
        ],
      ),
      (UserRole.teamLead, PerformanceRange.last30Days) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '81',
            caption: 'Ekip ortalaması',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '13',
            caption: 'Kapanan ekip işi',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '2.1 gün',
            caption: 'Görev kapanış ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%14',
            caption: 'Kalite geri dönüş oranı',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 74, target: 78),
          PerformanceTrendPoint(label: 'Kas', score: 76, target: 78),
          PerformanceTrendPoint(label: 'Ara', score: 79, target: 79),
          PerformanceTrendPoint(label: 'Oca', score: 80, target: 80),
          PerformanceTrendPoint(label: 'Şub', score: 83, target: 80),
          PerformanceTrendPoint(label: 'Mar', score: 81, target: 81),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'Nova Residence rapor teslimi',
            owner: 'Burak Demir',
            completedAt: '11 Mar 2026',
            revisionCount: 1,
            qualityScore: 84,
            durationLabel: '1.6 gün',
            statusLabel: 'Güvenli',
          ),
          TaskPerformanceRow(
            taskTitle: 'UPS kapasite etiketi',
            owner: 'Onur Kaya',
            completedAt: '10 Mar 2026',
            revisionCount: 3,
            qualityScore: 69,
            durationLabel: '2.9 gün',
            statusLabel: 'İzle',
          ),
          TaskPerformanceRow(
            taskTitle: 'Asansör test formu',
            owner: 'Ece Akın',
            completedAt: '09 Mar 2026',
            revisionCount: 1,
            qualityScore: 79,
            durationLabel: '1.8 gün',
            statusLabel: 'Dengeli',
          ),
        ],
      ),
      (UserRole.teamLead, PerformanceRange.last6Months) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '79',
            caption: '6 aylık ekip ortalaması',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '63',
            caption: 'Ekip kapanış sayısı',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '2.3 gün',
            caption: 'Kapanış ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%16',
            caption: 'Kalite geri dönüş oranı',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 72, target: 78),
          PerformanceTrendPoint(label: 'Kas', score: 75, target: 78),
          PerformanceTrendPoint(label: 'Ara', score: 77, target: 79),
          PerformanceTrendPoint(label: 'Oca', score: 80, target: 80),
          PerformanceTrendPoint(label: 'Şub', score: 82, target: 80),
          PerformanceTrendPoint(label: 'Mar', score: 79, target: 81),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'Yangın paneli raporu',
            owner: 'Burak Demir',
            completedAt: '07 Mar 2026',
            revisionCount: 1,
            qualityScore: 82,
            durationLabel: '2.0 gün',
            statusLabel: 'Güvenli',
          ),
          TaskPerformanceRow(
            taskTitle: 'Kamera altyapısı kontrolü',
            owner: 'Onur Kaya',
            completedAt: '03 Mar 2026',
            revisionCount: 2,
            qualityScore: 74,
            durationLabel: '2.8 gün',
            statusLabel: 'Dikkat',
          ),
        ],
      ),
      (UserRole.manager, PerformanceRange.last30Days) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '84',
            caption: 'Organizasyon ortalaması',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '18',
            caption: 'Kapanan kritik iş',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '1.9 gün',
            caption: 'Teslim ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%11',
            caption: 'Yöneticiye dönen kayıt oranı',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 76, target: 80),
          PerformanceTrendPoint(label: 'Kas', score: 79, target: 80),
          PerformanceTrendPoint(label: 'Ara', score: 81, target: 81),
          PerformanceTrendPoint(label: 'Oca', score: 82, target: 82),
          PerformanceTrendPoint(label: 'Şub', score: 85, target: 82),
          PerformanceTrendPoint(label: 'Mar', score: 84, target: 83),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'Merkez Plaza saha teslimi',
            owner: 'Seda Yılmaz',
            completedAt: '11 Mar 2026',
            revisionCount: 0,
            qualityScore: 91,
            durationLabel: '1.2 gün',
            statusLabel: 'Güçlü',
          ),
          TaskPerformanceRow(
            taskTitle: 'Kamera altyapısı',
            owner: 'Onur Kaya',
            completedAt: '10 Mar 2026',
            revisionCount: 3,
            qualityScore: 69,
            durationLabel: '3.1 gün',
            statusLabel: 'Kritik',
          ),
          TaskPerformanceRow(
            taskTitle: 'Yangın paneli raporu',
            owner: 'Burak Demir',
            completedAt: '09 Mar 2026',
            revisionCount: 1,
            qualityScore: 86,
            durationLabel: '1.7 gün',
            statusLabel: 'Güvenli',
          ),
        ],
      ),
      (UserRole.manager, PerformanceRange.last6Months) => const PerformanceSnapshot(
        metrics: [
          PerformanceMetric(
            label: 'Genel Skor',
            value: '82',
            caption: '6 aylık organizasyon ortalaması',
          ),
          PerformanceMetric(
            label: 'Tamamlanan',
            value: '118',
            caption: 'Kapanan iş hacmi',
          ),
          PerformanceMetric(
            label: 'Ortalama Süre',
            value: '2.1 gün',
            caption: 'Teslim ortalaması',
          ),
          PerformanceMetric(
            label: 'Revizyon Oranı',
            value: '%13',
            caption: 'Revizyon geri dönüş oranı',
          ),
        ],
        trendPoints: [
          PerformanceTrendPoint(label: 'Eki', score: 75, target: 80),
          PerformanceTrendPoint(label: 'Kas', score: 78, target: 80),
          PerformanceTrendPoint(label: 'Ara', score: 80, target: 81),
          PerformanceTrendPoint(label: 'Oca', score: 81, target: 82),
          PerformanceTrendPoint(label: 'Şub', score: 84, target: 82),
          PerformanceTrendPoint(label: 'Mar', score: 82, target: 83),
        ],
        rows: [
          TaskPerformanceRow(
            taskTitle: 'Merkez Plaza saha teslimi',
            owner: 'Seda Yılmaz',
            completedAt: '11 Mar 2026',
            revisionCount: 0,
            qualityScore: 91,
            durationLabel: '1.2 gün',
            statusLabel: 'Güçlü',
          ),
          TaskPerformanceRow(
            taskTitle: 'Nova Residence bakım raporu',
            owner: 'Burak Demir',
            completedAt: '07 Mar 2026',
            revisionCount: 1,
            qualityScore: 88,
            durationLabel: '1.6 gün',
            statusLabel: 'Güvenli',
          ),
          TaskPerformanceRow(
            taskTitle: 'Kamera altyapısı',
            owner: 'Onur Kaya',
            completedAt: '04 Mar 2026',
            revisionCount: 3,
            qualityScore: 69,
            durationLabel: '3.1 gün',
            statusLabel: 'Kritik',
          ),
        ],
      ),
    };
  }
}
