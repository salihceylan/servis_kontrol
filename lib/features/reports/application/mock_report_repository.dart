import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class MockReportRepository {
  const MockReportRepository();

  ReportSnapshot loadFor(AppUser user) {
    return switch (user.role) {
      UserRole.employee => const ReportSnapshot(
        metrics: [
          ReportMetric(
            label: 'Bugün Teslim',
            value: '1',
            caption: 'Üzerindeki aktif iş',
          ),
          ReportMetric(
            label: 'Bekleyen Not',
            value: '1',
            caption: 'Revizyon mesajı',
          ),
          ReportMetric(
            label: 'Kontrol Bekleyen',
            value: '2',
            caption: 'Ekip geri dönüşü',
          ),
          ReportMetric(
            label: 'Tamamlanan',
            value: '9',
            caption: 'Bu ay',
          ),
        ],
        statusCounts: [
          ReportStatusCount(label: 'Beklemede', count: 2),
          ReportStatusCount(label: 'Devam Ediyor', count: 3),
          ReportStatusCount(label: 'İncelemede', count: 1),
          ReportStatusCount(label: 'Revizyonda', count: 1),
          ReportStatusCount(label: 'Tamamlandı', count: 9),
        ],
        activities: [
          ReportActivity(
            title: 'Merkez Plaza teslim raporu hazır',
            subtitle: 'PDF olarak indirilebilir',
          ),
          ReportActivity(
            title: 'Panel etiketi revizyon çıktısı üretildi',
            subtitle: 'Excel paylaşımı hazır',
          ),
        ],
        teamOptions: ['Kendi İşlerim'],
        userOptions: ['Onur Kaya'],
        runs: [
          ReportRun(
            id: 'emp-run-1',
            title: 'Kişisel teslim raporu',
            scope: 'Kendi İşlerim',
            format: ReportFormat.pdf,
            createdAtLabel: 'Bugün 09:40',
            status: ReportRunStatus.ready,
          ),
        ],
      ),
      UserRole.teamLead => const ReportSnapshot(
        metrics: [
          ReportMetric(
            label: 'Bugün Teslim',
            value: '3',
            caption: 'Kritik ekip işi',
          ),
          ReportMetric(
            label: 'Geciken',
            value: '2',
            caption: 'Takip gerekli',
          ),
          ReportMetric(
            label: 'İnceleme / Revizyon',
            value: '4',
            caption: 'Kuyruk',
          ),
          ReportMetric(
            label: 'Tamamlanan',
            value: '16',
            caption: 'Son 30 gün',
          ),
        ],
        statusCounts: [
          ReportStatusCount(label: 'Beklemede', count: 3),
          ReportStatusCount(label: 'Devam Ediyor', count: 8),
          ReportStatusCount(label: 'İncelemede', count: 2),
          ReportStatusCount(label: 'Revizyonda', count: 2),
          ReportStatusCount(label: 'Tamamlandı', count: 16),
        ],
        activities: [
          ReportActivity(
            title: 'Nova Residence ekip performans raporu hazır',
            subtitle: 'E-posta ile paylaşıma hazır',
          ),
          ReportActivity(
            title: 'Revizyon kuyruğu raporu oluşturuldu',
            subtitle: 'Excel çıktısı tamamlandı',
          ),
          ReportActivity(
            title: 'Merkez Plaza teslim özeti gönderildi',
            subtitle: 'PDF mail teslimi yapıldı',
          ),
        ],
        teamOptions: ['Saha Ekibi', 'Koordinasyon'],
        userOptions: ['Seda Yılmaz', 'Onur Kaya', 'Burak Demir'],
        runs: [
          ReportRun(
            id: 'lead-run-1',
            title: 'Haftalık ekip performansı',
            scope: 'Saha Ekibi',
            format: ReportFormat.excel,
            createdAtLabel: 'Bugün 08:15',
            status: ReportRunStatus.ready,
          ),
        ],
      ),
      UserRole.manager => const ReportSnapshot(
        metrics: [
          ReportMetric(
            label: 'Bugün Teslim',
            value: '4',
            caption: 'Acil görev',
          ),
          ReportMetric(
            label: 'Geciken',
            value: '2',
            caption: 'Son teslim geçti',
          ),
          ReportMetric(
            label: 'İnceleme / Revizyon',
            value: '5',
            caption: 'Kuyruk',
          ),
          ReportMetric(
            label: 'Tamamlanan',
            value: '18',
            caption: 'Son 30 gün',
          ),
        ],
        statusCounts: [
          ReportStatusCount(label: 'Beklemede', count: 3),
          ReportStatusCount(label: 'Devam Ediyor', count: 12),
          ReportStatusCount(label: 'İncelemede', count: 2),
          ReportStatusCount(label: 'Revizyonda', count: 3),
          ReportStatusCount(label: 'Tamamlandı', count: 18),
          ReportStatusCount(label: 'İptal', count: 1),
        ],
        activities: [
          ReportActivity(
            title: 'Operasyon özeti yönetici mailine gönderildi',
            subtitle: 'PDF paylaşımı tamamlandı',
          ),
          ReportActivity(
            title: 'Çalışan kalite raporu üretildi',
            subtitle: 'Excel indirmesi hazır',
          ),
          ReportActivity(
            title: 'Revizyon eşiği raporu yenilendi',
            subtitle: 'Alarm takibi için yeni veri çıktı',
          ),
        ],
        teamOptions: ['Tüm Şirket', 'Saha Ekibi', 'Koordinasyon'],
        userOptions: ['Merve Aydın', 'Seda Yılmaz', 'Onur Kaya', 'Burak Demir'],
        runs: [
          ReportRun(
            id: 'mgr-run-1',
            title: 'Haftalık operasyon özeti',
            scope: 'Tüm Şirket',
            format: ReportFormat.pdf,
            createdAtLabel: 'Bugün 07:55',
            status: ReportRunStatus.ready,
          ),
          ReportRun(
            id: 'mgr-run-2',
            title: 'Revizyon performans raporu',
            scope: 'Saha Ekibi',
            format: ReportFormat.excel,
            createdAtLabel: 'Dün 18:20',
            status: ReportRunStatus.ready,
          ),
        ],
      ),
    };
  }
}
