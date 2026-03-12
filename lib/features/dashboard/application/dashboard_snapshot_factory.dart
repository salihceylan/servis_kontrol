import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class DashboardSnapshotFactory {
  const DashboardSnapshotFactory();

  DashboardSnapshot create(AppUser user) {
    final title = 'Hoş geldiniz, ${user.firstName}';

    return switch (user.role) {
      UserRole.employee => _employee(title),
      UserRole.teamLead => _teamLead(title),
      UserRole.manager => _manager(title),
    };
  }

  DashboardSnapshot _employee(String title) {
    return const DashboardSnapshot(
      title: 'unused',
      subtitle: 'unused',
      heroTitle: 'unused',
      heroMessage: 'unused',
      heroHighlight: 'unused',
      summaryCards: [],
      kpiCards: [],
      notifications: [],
      focusItems: [],
      projects: [],
    ).copyWithManual(
      title: title,
      subtitle:
          'Bugün üzerinde çalıştığın görevler, bildirimler ve teslim riskleri burada.',
      heroTitle: 'Workflow İş Takip Platformu',
      heroMessage:
          'Panel ana sayfasında önce kendi görev akışını, sonra bağlı olduğun ekibin geri dönüşlerini görürsün.',
      heroHighlight: 'Bugün odak: 1 kritik teslim, 1 revizyon notu',
      summaryCards: const [
        DashboardMetric(
          label: 'Üzerimde Açık',
          value: '3',
          caption: 'Aktif saha görevi',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugün Teslim',
          value: '1',
          caption: 'Saat 17:30 öncesi',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'Revizyon',
          value: '1',
          caption: 'Lider geri dönüşü',
          color: Color(0xFF7A7AE6),
          icon: Icons.rate_review_rounded,
        ),
        DashboardMetric(
          label: 'Tamamlanan',
          value: '9',
          caption: 'Bu ay',
          color: AppPalette.success,
          icon: Icons.done_all_rounded,
        ),
      ],
      kpiCards: const [
        DashboardMetric(
          label: 'Zamanında',
          value: '%86',
          caption: 'Teslim oranı',
          color: AppPalette.success,
          icon: Icons.verified_rounded,
        ),
        DashboardMetric(
          label: 'Ort. Revizyon',
          value: '0.8',
          caption: 'Görev başı',
          color: AppPalette.warning,
          icon: Icons.sync_alt_rounded,
        ),
        DashboardMetric(
          label: 'Memnuniyet',
          value: '4.7',
          caption: 'Son geri bildirim',
          color: AppPalette.primary,
          icon: Icons.thumb_up_alt_rounded,
        ),
      ],
      notifications: const [
        DashboardNotification(
          title: 'Merkez Plaza teslim saati yaklaştı',
          subtitle: '17:30 önce fotoğraf ve servis notu girilmeli',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: 'Panel etiketi için revizyon notu geldi',
          subtitle: 'Yeni saha fotoğrafı isteniyor',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Seda Yılmaz görev durumunu güncelledi',
          subtitle: 'Yangın pompa kontrolü önceliklendirildi',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: '1 teslimi kapat',
          subtitle: 'Asansör test formu ve fotoğraf seti eksik',
          badge: 'Kritik',
        ),
        DashboardFocusItem(
          title: 'Revizyon notunu cevapla',
          subtitle: 'Panel etiketi okunurluğu tekrar çekilecek',
          badge: 'Bekliyor',
        ),
        DashboardFocusItem(
          title: 'Günün raporunu tamamla',
          subtitle: 'Saha çıkışlarının notu merkez ekibe düşsün',
          badge: 'Bugün',
        ),
      ],
      projects: const [
        DashboardProject(
          name: 'Merkez Plaza',
          type: 'Saha Bakım',
          progress: 0.64,
        ),
        DashboardProject(
          name: 'Nova Residence',
          type: 'Kontrol',
          progress: 0.46,
        ),
        DashboardProject(
          name: 'Kuzey Atölye',
          type: 'Teslim',
          progress: 0.85,
        ),
      ],
    );
  }

  DashboardSnapshot _teamLead(String title) {
    return const DashboardSnapshot(
      title: 'unused',
      subtitle: 'unused',
      heroTitle: 'unused',
      heroMessage: 'unused',
      heroHighlight: 'unused',
      summaryCards: [],
      kpiCards: [],
      notifications: [],
      focusItems: [],
      projects: [],
    ).copyWithManual(
      title: title,
      subtitle:
          'Ekibin görev dağılımı, revizyon kuyruğu ve bugün yönetmen gereken operasyon burada.',
      heroTitle: 'Workflow İş Takip Platformu',
      heroMessage:
          'Panel, ekip lideri için önce revizyon ve dağıtım dengesini gösteren komuta ekranıdır.',
      heroHighlight: 'Bugün odak: 4 inceleme, 3 kritik teslim',
      summaryCards: const [
        DashboardMetric(
          label: 'Ekipte Açık',
          value: '8',
          caption: 'Dağıtılmış görev',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugün Teslim',
          value: '3',
          caption: 'Takip gerektiriyor',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'İncelemede',
          value: '4',
          caption: 'Kontrol kuyruğu',
          color: Color(0xFF7A7AE6),
          icon: Icons.rate_review_rounded,
        ),
        DashboardMetric(
          label: 'Tamamlanan',
          value: '16',
          caption: 'Son 30 gün',
          color: AppPalette.success,
          icon: Icons.done_all_rounded,
        ),
      ],
      kpiCards: const [
        DashboardMetric(
          label: 'Ekip Skoru',
          value: '81',
          caption: 'Ortalama puan',
          color: AppPalette.success,
          icon: Icons.insights_rounded,
        ),
        DashboardMetric(
          label: 'Revizyon Oranı',
          value: '%18',
          caption: 'Bu hafta',
          color: AppPalette.warning,
          icon: Icons.compare_arrows_rounded,
        ),
        DashboardMetric(
          label: 'Zamanında',
          value: '%87',
          caption: 'Teslim performansı',
          color: AppPalette.primary,
          icon: Icons.av_timer_rounded,
        ),
      ],
      notifications: const [
        DashboardNotification(
          title: '4 iş inceleme bekliyor',
          subtitle: 'Panel, UPS ve etiket kontrolleri kuyrukta',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Burak Demir teslim riski taşıyor',
          subtitle: 'Nova Residence görevi geç kalabilir',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: 'Yeni görev atama talebi geldi',
          subtitle: 'Merkez ekipten ilave saha kaynağı istendi',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: 'Revizyon kuyruğunu erit',
          subtitle: '4 inceleme kalemi panel bekliyor',
          badge: 'Öncelik',
        ),
        DashboardFocusItem(
          title: 'Teslim riskini kapat',
          subtitle: 'Nova Residence için yedek teknisyen planla',
          badge: 'Risk',
        ),
        DashboardFocusItem(
          title: 'Ekip notunu güncelle',
          subtitle: 'Bugünkü saha dağılımını merkez ekiple paylaş',
          badge: 'Bugün',
        ),
      ],
      projects: const [
        DashboardProject(name: 'Merkez Plaza', type: 'Bakım', progress: 0.72),
        DashboardProject(
          name: 'Kuzey Atölye',
          type: 'Kontrol',
          progress: 0.48,
        ),
        DashboardProject(
          name: 'Nova Residence',
          type: 'Kurulum',
          progress: 0.89,
        ),
      ],
    );
  }

  DashboardSnapshot _manager(String title) {
    return const DashboardSnapshot(
      title: 'unused',
      subtitle: 'unused',
      heroTitle: 'unused',
      heroMessage: 'unused',
      heroHighlight: 'unused',
      summaryCards: [],
      kpiCards: [],
      notifications: [],
      focusItems: [],
      projects: [],
    ).copyWithManual(
      title: title,
      subtitle:
          'Operasyon özetleri, KPI kartları, bildirim merkezi ve yönetsel karar akışı burada.',
      heroTitle: 'Workflow İş Takip Platformu',
      heroMessage:
          'Panel, yönetici için ekip kartları, performans widgetları ve erken uyarı noktalarını bir araya getirir.',
      heroHighlight: 'Bugün odak: 5 revizyon, 2 gecikme, 14 aktif personel',
      summaryCards: const [
        DashboardMetric(
          label: 'Devam Eden',
          value: '12',
          caption: 'Aktif görevler',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugün Teslim',
          value: '4',
          caption: 'Kritik takvim',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'Revizyon Bekleyen',
          value: '7',
          caption: 'İnceleme kuyruğu',
          color: Color(0xFF7A7AE6),
          icon: Icons.rate_review_rounded,
        ),
        DashboardMetric(
          label: 'Tamamlanan',
          value: '18',
          caption: 'Son 30 gün',
          color: AppPalette.success,
          icon: Icons.done_all_rounded,
        ),
      ],
      kpiCards: const [
        DashboardMetric(
          label: 'KPI Skoru',
          value: '78',
          caption: 'Genel operasyon',
          color: AppPalette.success,
          icon: Icons.query_stats_rounded,
        ),
        DashboardMetric(
          label: 'Ort. Süre',
          value: '2.4g',
          caption: 'Görev çevrimi',
          color: AppPalette.warning,
          icon: Icons.timelapse_rounded,
        ),
        DashboardMetric(
          label: 'Memnuniyet',
          value: '4.8',
          caption: 'Müşteri puanı',
          color: AppPalette.primary,
          icon: Icons.sentiment_satisfied_alt_rounded,
        ),
      ],
      notifications: const [
        DashboardNotification(
          title: '2 görev teslim tarihini aştı',
          subtitle: 'Nova Residence ve Kuzey Atölye yakından izlenmeli',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: '5 revizyon yönetici onayı bekliyor',
          subtitle: 'Panel ve UPS kalemleri kuyrukta',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Ekip liderleri bugün 3 yeni atama istedi',
          subtitle: 'Yük dağılımı dengesizleşiyor',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: 'Geciken görevleri filtrele',
          subtitle: '2 iş teslim tarihini aştı, alarm takibi aç',
          badge: 'Alarm',
        ),
        DashboardFocusItem(
          title: 'Revizyon onaylarını ilerlet',
          subtitle: 'Bekleyen 5 iş karar bekliyor',
          badge: 'Onay',
        ),
        DashboardFocusItem(
          title: 'Ekip kaynak dağılımını düzenle',
          subtitle: 'Merkez ve saha kapasitelerini dengele',
          badge: 'Yönetsel',
        ),
      ],
      projects: const [
        DashboardProject(name: 'Merkez Plaza', type: 'Bakım', progress: 0.72),
        DashboardProject(
          name: 'Kuzey Atölye',
          type: 'Kontrol',
          progress: 0.48,
        ),
        DashboardProject(
          name: 'Nova Residence',
          type: 'Kurulum',
          progress: 0.89,
        ),
      ],
    );
  }
}

extension on DashboardSnapshot {
  DashboardSnapshot copyWithManual({
    required String title,
    required String subtitle,
    required String heroTitle,
    required String heroMessage,
    required String heroHighlight,
    required List<DashboardMetric> summaryCards,
    required List<DashboardMetric> kpiCards,
    required List<DashboardNotification> notifications,
    required List<DashboardFocusItem> focusItems,
    required List<DashboardProject> projects,
  }) {
    return DashboardSnapshot(
      title: title,
      subtitle: subtitle,
      heroTitle: heroTitle,
      heroMessage: heroMessage,
      heroHighlight: heroHighlight,
      summaryCards: summaryCards,
      kpiCards: kpiCards,
      notifications: notifications,
      focusItems: focusItems,
      projects: projects,
    );
  }
}
