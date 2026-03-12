import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class DashboardSnapshotFactory {
  const DashboardSnapshotFactory();

  DashboardSnapshot create(AppUser user) {
    final title = 'Hos geldiniz, ${user.firstName}';

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
          'Bugun uzerinde calistigin gorevler, bildirimler ve teslim riskleri burada.',
      heroTitle: 'Workflow Is Takip Platformu',
      heroMessage:
          'Panel ana sayfasinda once kendi gorev akisini, sonra bagli oldugun ekibin geri donuslerini gorursun.',
      heroHighlight: 'Bugun odak: 1 kritik teslim, 1 revizyon notu',
      summaryCards: const [
        DashboardMetric(
          label: 'Uzerimde Acik',
          value: '3',
          caption: 'Aktif saha gorevi',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugun Teslim',
          value: '1',
          caption: 'Saat 17:30 oncesi',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'Revizyon',
          value: '1',
          caption: 'Lider geri donusu',
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
          label: 'Zamaninda',
          value: '%86',
          caption: 'Teslim orani',
          color: AppPalette.success,
          icon: Icons.verified_rounded,
        ),
        DashboardMetric(
          label: 'Ort. Revizyon',
          value: '0.8',
          caption: 'Gorev basi',
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
          title: 'Merkez Plaza teslim saati yaklasti',
          subtitle: '17:30 once fotograf ve servis notu girilmeli',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: 'Panel etiketi icin revizyon notu geldi',
          subtitle: 'Yeni saha fotografi isteniyor',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Seda Yilmaz gorev durumunu guncelledi',
          subtitle: 'Yangin pompa kontrolu onceliklendirildi',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: '1 teslimi kapat',
          subtitle: 'Asansor test formu ve fotograf seti eksik',
          badge: 'Kritik',
        ),
        DashboardFocusItem(
          title: 'Revizyon notunu cevapla',
          subtitle: 'Panel etiketi okunurlugu tekrar cekilecek',
          badge: 'Bekliyor',
        ),
        DashboardFocusItem(
          title: 'Gunun raporunu tamamla',
          subtitle: 'Saha cikislarinin notu merkez ekibe dussun',
          badge: 'Bugun',
        ),
      ],
      projects: const [
        DashboardProject(
          name: 'Merkez Plaza',
          type: 'Saha Bakim',
          progress: 0.64,
        ),
        DashboardProject(
          name: 'Nova Residence',
          type: 'Kontrol',
          progress: 0.46,
        ),
        DashboardProject(
          name: 'Kuzey Atolye',
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
          'Ekibin gorev dagilimi, revizyon kuyrugu ve bugun yonetmen gereken operasyon burada.',
      heroTitle: 'Workflow Is Takip Platformu',
      heroMessage:
          'Panel, ekip lideri icin once revizyon ve dagitim dengesini gosteren komuta ekranidir.',
      heroHighlight: 'Bugun odak: 4 inceleme, 3 kritik teslim',
      summaryCards: const [
        DashboardMetric(
          label: 'Ekipte Acik',
          value: '8',
          caption: 'Dagitilmis gorev',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugun Teslim',
          value: '3',
          caption: 'Takip gerektiriyor',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'Incelemede',
          value: '4',
          caption: 'Kontrol kuyrugu',
          color: Color(0xFF7A7AE6),
          icon: Icons.rate_review_rounded,
        ),
        DashboardMetric(
          label: 'Tamamlanan',
          value: '16',
          caption: 'Son 30 gun',
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
          label: 'Revizyon Orani',
          value: '%18',
          caption: 'Bu hafta',
          color: AppPalette.warning,
          icon: Icons.compare_arrows_rounded,
        ),
        DashboardMetric(
          label: 'On-time',
          value: '%87',
          caption: 'Teslim performansi',
          color: AppPalette.primary,
          icon: Icons.av_timer_rounded,
        ),
      ],
      notifications: const [
        DashboardNotification(
          title: '4 is inceleme bekliyor',
          subtitle: 'Panel, UPS ve etiket kontrolleri kuyrukta',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Burak Demir teslim riski tasiyor',
          subtitle: 'Nova Residence gorevi gec kalabilir',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: 'Yeni gorev atama talebi geldi',
          subtitle: 'Merkez ekipten ilave saha kaynagi istendi',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: 'Revizyon kuyrugunu erit',
          subtitle: '4 inceleme kalemi panel bekliyor',
          badge: 'Oncelik',
        ),
        DashboardFocusItem(
          title: 'Teslim riskini kapat',
          subtitle: 'Nova Residence icin yedek teknisyen planla',
          badge: 'Risk',
        ),
        DashboardFocusItem(
          title: 'Ekip notu guncelle',
          subtitle: 'Bugunku saha dagilimini merkez ekiple paylas',
          badge: 'Bugun',
        ),
      ],
      projects: const [
        DashboardProject(name: 'Merkez Plaza', type: 'Bakim', progress: 0.72),
        DashboardProject(
          name: 'Kuzey Atolye',
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
          'Operasyon ozetleri, KPI kartlari, bildirim merkezi ve yonetsel karar akisi burada.',
      heroTitle: 'Workflow Is Takip Platformu',
      heroMessage:
          'Panel, yonetici icin ekip kartlari, performans widgetlari ve erken uyari noktalarini bir araya getirir.',
      heroHighlight: 'Bugun odak: 5 revizyon, 2 gecikme, 14 aktif personel',
      summaryCards: const [
        DashboardMetric(
          label: 'Devam Eden',
          value: '12',
          caption: 'Aktif gorevler',
          color: AppPalette.primary,
          icon: Icons.play_circle_fill_rounded,
        ),
        DashboardMetric(
          label: 'Bugun Teslim',
          value: '4',
          caption: 'Kritik takvim',
          color: AppPalette.warning,
          icon: Icons.schedule_rounded,
        ),
        DashboardMetric(
          label: 'Revizyon Bekleyen',
          value: '7',
          caption: 'Inceleme kuyrugu',
          color: Color(0xFF7A7AE6),
          icon: Icons.rate_review_rounded,
        ),
        DashboardMetric(
          label: 'Tamamlanan',
          value: '18',
          caption: 'Son 30 gun',
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
          label: 'Ort. Sure',
          value: '2.4g',
          caption: 'Gorev cevrimi',
          color: AppPalette.warning,
          icon: Icons.timelapse_rounded,
        ),
        DashboardMetric(
          label: 'Memnuniyet',
          value: '4.8',
          caption: 'Musteri puani',
          color: AppPalette.primary,
          icon: Icons.sentiment_satisfied_alt_rounded,
        ),
      ],
      notifications: const [
        DashboardNotification(
          title: '2 gorev teslim tarihini asti',
          subtitle: 'Nova Residence ve Kuzey Atolye yakindan izlenmeli',
          color: AppPalette.warning,
        ),
        DashboardNotification(
          title: '5 revizyon yonetici onayi bekliyor',
          subtitle: 'Panel ve UPS kalemleri kuyrukta',
          color: Color(0xFF7A7AE6),
        ),
        DashboardNotification(
          title: 'Ekip liderleri bugun 3 yeni atama istedi',
          subtitle: 'Yuk dagilimi dengesizlesiyor',
          color: AppPalette.primary,
        ),
      ],
      focusItems: const [
        DashboardFocusItem(
          title: 'Geciken gorevleri filtrele',
          subtitle: '2 is teslim tarihini asti, alarm takibi ac',
          badge: 'Alarm',
        ),
        DashboardFocusItem(
          title: 'Revizyon onaylarini ilerlet',
          subtitle: 'Bekleyen 5 is karar bekliyor',
          badge: 'Onay',
        ),
        DashboardFocusItem(
          title: 'Ekip kaynak dagilimini duzenle',
          subtitle: 'Merkez ve saha kapasitelerini dengele',
          badge: 'Yonetsel',
        ),
      ],
      projects: const [
        DashboardProject(name: 'Merkez Plaza', type: 'Bakim', progress: 0.72),
        DashboardProject(
          name: 'Kuzey Atolye',
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
