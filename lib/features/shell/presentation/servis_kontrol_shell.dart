import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/presentation/dashboard_page.dart';
import 'package:servis_kontrol/features/revisions/presentation/revision_page.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_page.dart';

enum AppSection { panel, tasks, revisions, team, performance, reports }

class ServisKontrolShell extends StatefulWidget {
  const ServisKontrolShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<ServisKontrolShell> createState() => _ServisKontrolShellState();
}

class _ServisKontrolShellState extends State<ServisKontrolShell> {
  AppSection _selected = AppSection.panel;

  AppUser get _user => widget.user;
  UserRole get _role => _user.role;

  List<(AppSection, String, IconData, String?)> get _sidebarItems => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded, null),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded, '3'),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded, '1'),
      (AppSection.performance, 'Performans', Icons.insights_rounded, null),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded, null),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded, '6'),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded, '4'),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined, null),
      (AppSection.performance, 'Performans', Icons.insights_rounded, null),
    ],
    UserRole.manager => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded, null),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded, '9'),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded, '5'),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined, null),
      (AppSection.performance, 'Performans', Icons.insights_rounded, null),
      (AppSection.reports, 'Raporlar', Icons.insert_chart_outlined_rounded, null),
    ],
  };

  List<(AppSection, String)> get _topNavItems => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel'),
      (AppSection.tasks, 'Görevler'),
      (AppSection.revisions, 'Revizyonlar'),
      (AppSection.performance, 'Performans'),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel'),
      (AppSection.team, 'Ekip'),
      (AppSection.tasks, 'Görevler'),
      (AppSection.revisions, 'Revizyonlar'),
    ],
    UserRole.manager => [
      (AppSection.panel, 'Panel'),
      (AppSection.team, 'Çalışanlar'),
      (AppSection.tasks, 'Görevler'),
      (AppSection.reports, 'Raporlar'),
    ],
  };

  (String, IconData, AppSection) get _primaryAction => switch (_role) {
    UserRole.employee => (
      'Teslim Güncelle',
      Icons.playlist_add_check_circle_rounded,
      AppSection.tasks,
    ),
    UserRole.teamLead => (
      'Revizyonları İncele',
      Icons.rate_review_rounded,
      AppSection.revisions,
    ),
    UserRole.manager => ('Görev Ata', Icons.add_rounded, AppSection.team),
  };

  List<ActivityRow> get _activities => switch (_role) {
    UserRole.employee => const [
      ActivityRow('Yeni saha görevi atandı', 'Merkez Plaza - 8 dk önce', AppPalette.success),
      ActivityRow('Revizyon notu düştü', 'Panel etiketi - 23 dk önce', AppPalette.warning),
      ActivityRow('Bugün teslim hatırlatması', '1 saat önce', AppPalette.primary),
    ],
    UserRole.teamLead => const [
      ActivityRow('Revizyon talebi açıldı', 'Teknik servis / klima - 12 dk önce', AppPalette.warning),
      ActivityRow('Yeni görev dağıtıldı', 'Bakım planlama - 20 dk önce', AppPalette.success),
      ActivityRow('Ekip notu güncellendi', 'Saha ekibi - 1 saat önce', AppPalette.primary),
    ],
    UserRole.manager => const [
      ActivityRow('Yeni görev atandı', 'Bakım planlama - 12 dk önce', AppPalette.success),
      ActivityRow('Revizyon talebi açıldı', 'Teknik servis / klima - 37 dk önce', AppPalette.warning),
      ActivityRow('Çalışan vardiya değişikliği', 'Saha ekibi - 1 saat önce', AppPalette.primary),
    ],
  };

  List<TeamRow> get _teamRows => switch (_role) {
    UserRole.employee => [
      TeamRow(_user.name, _user.jobTitle, 'Sahada', 3, 72),
      const TeamRow('Seda Yılmaz', 'Ekip Lideri', 'Aktif', 5, 78),
      const TeamRow('Merve Aydın', 'Operasyon Yöneticisi', 'Aktif', 7, 88),
    ],
    UserRole.teamLead => [
      TeamRow(_user.name, _user.jobTitle, 'Aktif', 6, 81),
      const TeamRow('Onur Kaya', 'Saha Teknisyeni', 'Sahada', 3, 69),
      const TeamRow('Burak Demir', 'Teknik Uzman', 'Aktif', 4, 74),
    ],
    UserRole.manager => const [
      TeamRow('Merve Aydın', 'Operasyon Yöneticisi', 'Aktif', 6, 84),
      TeamRow('Seda Yılmaz', 'Saha Koordinatörü', 'Aktif', 4, 76),
      TeamRow('Onur Kaya', 'Teknisyen', 'Sahada', 3, 69),
    ],
  };

  List<PerformanceRowData> get _performanceRows => switch (_role) {
    UserRole.employee => [
      PerformanceRowData(_user.name, _user.jobTitle, '3', '9', '86%', '1', '0.8', '72 / 100 - Gelişiyor', AppPalette.warning),
      const PerformanceRowData('Seda Yılmaz', 'Ekip Lideri', '5', '14', '89%', '1', '0.6', '78 / 100 - Güvenli', AppPalette.success),
      const PerformanceRowData('Merve Aydın', 'Yönetici', '7', '19', '93%', '0', '0.3', '88 / 100 - Güçlü', AppPalette.success),
    ],
    UserRole.teamLead => [
      PerformanceRowData(_user.name, _user.jobTitle, '6', '13', '87%', '1', '0.5', '81 / 100 - Güvenli', AppPalette.success),
      const PerformanceRowData('Onur Kaya', 'Teknisyen', '3', '9', '74%', '3', '1.3', '69 / 100 - İzle', AppPalette.danger),
      const PerformanceRowData('Burak Demir', 'Teknik Uzman', '4', '10', '79%', '2', '0.9', '74 / 100 - Dikkat', AppPalette.warning),
    ],
    UserRole.manager => const [
      PerformanceRowData('Merve Aydın', 'Operasyon', '6', '14', '91%', '1', '0.4', '84 / 100 - Güvenli', AppPalette.success),
      PerformanceRowData('Seda Yılmaz', 'Koordinatör', '4', '11', '82%', '2', '0.9', '76 / 100 - Dikkat', AppPalette.warning),
      PerformanceRowData('Onur Kaya', 'Teknisyen', '3', '9', '74%', '3', '1.3', '69 / 100 - İzle', AppPalette.danger),
    ],
  };

  List<StatData> get _reportStats => switch (_role) {
    UserRole.employee => const [
      StatData(Icons.schedule_rounded, 'Bugün Teslim', '1', 'Üzerimde açık iş', AppPalette.primary),
      StatData(Icons.report_gmailerrorred_rounded, 'Bekleyen Not', '1', 'Revizyon mesajı', AppPalette.warning),
      StatData(Icons.rate_review_rounded, 'Kontrol Bekleyen', '2', 'Ekip geri dönüşü', Color(0xFF7A7AE6)),
      StatData(Icons.done_all_rounded, 'Tamamlanan', '9', 'Bu ay', AppPalette.success),
    ],
    UserRole.teamLead => const [
      StatData(Icons.schedule_rounded, 'Bugün Teslim', '3', 'Kritik ekip işi', AppPalette.primary),
      StatData(Icons.report_gmailerrorred_rounded, 'Geciken', '2', 'Takip gerekli', AppPalette.warning),
      StatData(Icons.rate_review_rounded, 'İnceleme / Revizyon', '4', 'Kuyruk', Color(0xFF7A7AE6)),
      StatData(Icons.done_all_rounded, 'Tamamlanan', '16', 'Son 30 gün', AppPalette.success),
    ],
    UserRole.manager => const [
      StatData(Icons.schedule_rounded, 'Bugün Teslim', '4', 'Acil görev', AppPalette.primary),
      StatData(Icons.report_gmailerrorred_rounded, 'Geciken', '2', 'Son teslim geçti', AppPalette.warning),
      StatData(Icons.rate_review_rounded, 'İnceleme / Revizyon', '5', 'Kuyruk', Color(0xFF7A7AE6)),
      StatData(Icons.done_all_rounded, 'Tamamlanan', '18', 'Son 30 gün', AppPalette.success),
    ],
  };

  List<StatData> get _teamOverviewStats => switch (_role) {
    UserRole.employee => const [
      StatData(Icons.groups_2_rounded, 'Bağlı Ekip', '3', 'Yakından çalıştığın kişiler', AppPalette.primary),
      StatData(Icons.task_rounded, 'Üzerimde Açık', '3', 'Aktif saha işi', AppPalette.warning),
      StatData(Icons.pending_actions_rounded, 'Bekleyen Geri Dönüş', '2', 'İnceleme notu', AppPalette.danger),
      StatData(Icons.analytics_rounded, 'Kişisel Skor', '72', 'Son 30 gün', AppPalette.success),
    ],
    UserRole.teamLead => const [
      StatData(Icons.groups_2_rounded, 'Toplam Çalışan', '8', 'Aktif ekip', AppPalette.primary),
      StatData(Icons.task_rounded, 'Aktif Görevler', '19', 'Dağıtılmış iş', AppPalette.warning),
      StatData(Icons.pending_actions_rounded, 'Bekleyen Onaylar', '4', 'Kontrol kuyruğu', AppPalette.danger),
      StatData(Icons.analytics_rounded, 'Ekip Performansı', '%81', 'Ortalama skor', AppPalette.success),
    ],
    UserRole.manager => const [
      StatData(Icons.groups_2_rounded, 'Toplam Çalışan', '14', 'Aktif personel', AppPalette.primary),
      StatData(Icons.task_rounded, 'Aktif Görevler', '27', 'Açık görev', AppPalette.warning),
      StatData(Icons.pending_actions_rounded, 'Bekleyen Onaylar', '5', 'İnceleme kuyruğu', AppPalette.danger),
      StatData(Icons.analytics_rounded, 'Ekip Performansı', '%78', 'Ortalama skor', AppPalette.success),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        return Scaffold(
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: AppPalette.sidebar,
                  child: SafeArea(child: _sidebar()),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) SizedBox(width: 244, child: _sidebar()),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(wide),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 20 : 14,
                            20,
                            wide ? 20 : 14,
                            24,
                          ),
                          child: _content(wide),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sidebar() {
    final items = _sidebarItems;

    return Container(
      color: AppPalette.sidebar,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.sidebarSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppPalette.primary,
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ServisKontrol Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Operasyon Platformu',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => setState(() => _selected = item.$1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      horizontalTitleGap: 10,
                      minLeadingWidth: 18,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: _selected == item.$1
                          ? AppPalette.primary
                          : Colors.transparent,
                      leading: Icon(item.$3, color: Colors.white, size: 19),
                      title: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      trailing: item.$4 == null
                          ? null
                          : CircleAvatar(
                              radius: 11,
                              backgroundColor: _selected == item.$1
                                  ? Colors.white24
                                  : AppPalette.sidebarSoft,
                              child: Text(
                                item.$4!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Ayarlar',
                      style: TextStyle(
                        color: Color(0x88FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const _SidebarMeta(
                  icon: Icons.settings_outlined,
                  label: 'Genel Ayarlar',
                ),
                const _SidebarMeta(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım Merkezi',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    _user.initials,
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool wide) {
    final nav = _topNavItems;
    final primaryAction = _primaryAction;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!wide)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppPalette.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppPalette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppPalette.border),
                  ),
                ),
              ),
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 20),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in nav)
                        TextButton(
                          onPressed: () => setState(() => _selected = item.$1),
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              color: _selected == item.$1
                                  ? AppPalette.text
                                  : AppPalette.muted,
                              fontWeight: _selected == item.$1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          FilledButton.icon(
            onPressed: () => setState(() => _selected = primaryAction.$3),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(primaryAction.$2),
            label: Text(primaryAction.$1),
          ),
          const SizedBox(width: 10),
          const _RoundAction(
            icon: Icons.notifications_none_rounded,
            badge: '1',
          ),
          const SizedBox(width: 10),
          const _RoundAction(icon: Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _content(bool wide) {
    switch (_selected) {
      case AppSection.panel:
        return DashboardPage(user: _user);
      case AppSection.tasks:
        return _tasksPage();
      case AppSection.revisions:
        return _revisionsPage(wide);
      case AppSection.team:
        return _teamPage(wide);
      case AppSection.performance:
        return _performancePage();
      case AppSection.reports:
        return _reportsPage(wide);
    }
  }

  Widget _tasksPage() {
    return TaskPage(user: _user);
  }

  Widget _revisionsPage(bool wide) {
    return RevisionPage(user: _user);
  }

  Widget _teamPage(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: _role == UserRole.employee
              ? 'Bagli Oldugun Ekip'
              : 'Ekibe Genel Bakış',
          subtitle: _role == UserRole.employee
              ? 'Liderin, yönetici notları ve ekip görünümü burada.'
              : 'Ekibinizin performansını ve görevlerini etkili şekilde yönetin.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final stat in _teamOverviewStats)
              SizedBox(width: 300, child: _StatCard(data: stat)),
          ],
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _teamTable()),
              const SizedBox(width: 16),
              const Expanded(
                flex: 2,
                child: _Card(
                  child: _EmptyNote(
                    title: 'Bekleyen Düzeltmeler',
                    subtitle: 'İnceleme / revizyon kuyruğu',
                    message: 'Bekleyen iş yok.',
                  ),
                ),
              ),
            ],
          )
        else ...[
          _teamTable(),
          const SizedBox(height: 16),
          const _Card(
            child: _EmptyNote(
              title: 'Bekleyen Düzeltmeler',
              subtitle: 'İnceleme / revizyon kuyruğu',
              message: 'Bekleyen iş yok.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _teamTable() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Çalışan Performansı',
            subtitle: 'Kişi bazlı özet',
            action: 'Tümünü Gör',
          ),
          const SizedBox(height: 16),
          _TableCard(
            headers: const [
              'Çalışan',
              'Durum',
              'Aktif Görevler',
              'Performans',
              'İşlemler',
            ],
            rows: [
              for (final row in _teamRows)
                [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppPalette.primarySoft,
                        child: Text(
                          row.name[0],
                          style: const TextStyle(
                            color: AppPalette.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(row.role),
                        ],
                      ),
                    ],
                  ),
                  _Badge(
                    label: row.status,
                    color: row.status == 'Aktif'
                        ? AppPalette.success
                        : AppPalette.warning,
                  ),
                  Text('${row.activeTasks} Görev'),
                  _ScoreBar(score: row.score),
                  const Icon(Icons.visibility_outlined, size: 18),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _performancePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Performans',
          subtitle: 'Çalışan bazlı temel metrikler ve skor.',
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ActionPill(label: 'CSV İndir'),
              const SizedBox(height: 16),
              _TableCard(
                headers: const [
                  'Çalışan',
                  'Rol',
                  'Açık',
                  'Tamamlanan',
                  'Zamanında',
                  'Geç',
                  'Ort. Revizyon',
                  'Skor',
                ],
                rows: [
                  for (final row in _performanceRows)
                    [
                      Text(
                        row.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      _Badge(label: row.role, color: AppPalette.primary),
                      Text(row.openTasks),
                      Text(row.completedTasks),
                      Text(row.onTimeRate),
                      Text(row.lateCount),
                      Text(row.averageRevision),
                      _Badge(label: row.scoreLabel, color: row.scoreColor),
                    ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportsPage(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Raporlar',
          subtitle: 'Durum dağılımı, kritik göstergeler ve son aktiviteler.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final stat in _reportStats)
              SizedBox(
                width: wide ? 320 : double.infinity,
                child: _StatCard(data: stat),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SectionHeader(
                        title: 'Durum Dağılımı',
                        subtitle: 'Toplam görev sayıları',
                        action: 'CSV İndir',
                      ),
                      SizedBox(height: 16),
                      _TableCard(
                        headers: ['Durum', 'Adet'],
                        rows: [
                          [Text('Beklemede'), Text('3')],
                          [Text('Devam Ediyor'), Text('12')],
                          [Text('İncelemede'), Text('2')],
                          [Text('Revizyonda'), Text('3')],
                          [Text('Tamamlandı'), Text('18')],
                          [Text('İptal'), Text('1')],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _ActivityCard(
                  title: 'Son Aktiviteler',
                  subtitle: 'Son 20 hareket',
                  activities: _activities,
                ),
              ),
            ],
          )
        else ...[
          const _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Durum Dağılımı',
                  subtitle: 'Toplam görev sayıları',
                  action: 'CSV İndir',
                ),
                SizedBox(height: 16),
                _TableCard(
                  headers: ['Durum', 'Adet'],
                  rows: [
                    [Text('Beklemede'), Text('3')],
                    [Text('Devam Ediyor'), Text('12')],
                    [Text('İncelemede'), Text('2')],
                    [Text('Revizyonda'), Text('3')],
                    [Text('Tamamlandı'), Text('18')],
                    [Text('İptal'), Text('1')],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActivityCard(
            title: 'Son Aktiviteler',
            subtitle: 'Son 20 hareket',
            activities: _activities,
          ),
        ],
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppPalette.muted)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppPalette.muted)),
            ],
          ),
        ),
        if (action != null) TextButton(onPressed: () {}, child: Text(action!)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051830),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final StatData data;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: SizedBox(
        height: 182,
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -18,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: data.color.withValues(alpha: 0.14),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(data.icon, size: 18, color: data.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.caption,
                  style: const TextStyle(color: AppPalette.muted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.56,
                    minHeight: 8,
                    backgroundColor: AppPalette.primarySoft,
                    valueColor: AlwaysStoppedAnimation<Color>(data.color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.activities,
  });
  final String title;
  final String subtitle;
  final List<ActivityRow> activities;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: subtitle, action: 'Tümü'),
          const SizedBox(height: 16),
          for (final activity in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: activity.color.withValues(alpha: 0.14),
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: activity.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(activity.subtitle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: const BorderSide(color: AppPalette.border),
      ),
      child: Text(label, style: const TextStyle(color: AppPalette.text)),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w500,
            ),
            columns: [for (final h in headers) DataColumn(label: Text(h))],
            rows: [
              for (final row in rows)
                DataRow(cells: [for (final cell in row) DataCell(cell)]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color == Colors.white ? AppPalette.text : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white ? 0.85 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppPalette.success
        : score >= 70
        ? AppPalette.warning
        : AppPalette.danger;
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppPalette.primarySoft,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$score',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMeta extends StatelessWidget {
  const _SidebarMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xD2F2F6FF), size: 18),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.badge});
  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppPalette.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.border),
          ),
          child: Icon(icon, color: AppPalette.text, size: 20),
        ),
        if (badge != null)
          Positioned(
            right: -2,
            top: -4,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppPalette.danger,
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({
    required this.title,
    required this.subtitle,
    required this.message,
  });
  final String title;
  final String subtitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: AppPalette.muted)),
      ],
    );
  }
}

class StatData {
  const StatData(this.icon, this.title, this.value, this.caption, this.color);
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;
}

class ActivityRow {
  const ActivityRow(this.title, this.subtitle, this.color);
  final String title;
  final String subtitle;
  final Color color;
}

class TeamRow {
  const TeamRow(
    this.name,
    this.role,
    this.status,
    this.activeTasks,
    this.score,
  );
  final String name;
  final String role;
  final String status;
  final int activeTasks;
  final int score;
}

class ProjectRow {
  const ProjectRow(this.name, this.type, this.progress);
  final String name;
  final String type;
  final double progress;
}

class PerformanceRowData {
  const PerformanceRowData(
    this.name,
    this.role,
    this.openTasks,
    this.completedTasks,
    this.onTimeRate,
    this.lateCount,
    this.averageRevision,
    this.scoreLabel,
    this.scoreColor,
  );

  final String name;
  final String role;
  final String openTasks;
  final String completedTasks;
  final String onTimeRate;
  final String lateCount;
  final String averageRevision;
  final String scoreLabel;
  final Color scoreColor;
}
