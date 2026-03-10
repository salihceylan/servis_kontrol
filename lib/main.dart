import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ServisKontrolApp());
}

class ServisKontrolApp extends StatelessWidget {
  const ServisKontrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServisKontrol Pro',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          surface: Colors.white,
        ),
        textTheme: textTheme,
      ),
      home: const ServisKontrolShell(),
    );
  }
}

enum AppSection { panel, tasks, revisions, team, performance, reports }

class AppPalette {
  static const background = Color(0xFFF3F6FB);
  static const card = Colors.white;
  static const sidebar = Color(0xFF07162E);
  static const sidebarSoft = Color(0xFF0C2147);
  static const primary = Color(0xFF2F63E8);
  static const primarySoft = Color(0xFFD9E5FF);
  static const text = Color(0xFF0A1E40);
  static const muted = Color(0xFF61728D);
  static const border = Color(0xFFDCE3EE);
  static const success = Color(0xFF3CB96C);
  static const warning = Color(0xFFF0A541);
  static const danger = Color(0xFFE45D5D);
}

class ServisKontrolShell extends StatefulWidget {
  const ServisKontrolShell({super.key});

  @override
  State<ServisKontrolShell> createState() => _ServisKontrolShellState();
}

class _ServisKontrolShellState extends State<ServisKontrolShell> {
  AppSection _selected = AppSection.panel;

  final dashboardStats = const [
    StatData(
      Icons.play_circle_fill_rounded,
      'Devam Eden',
      '12',
      'Aktif gorevler',
      AppPalette.primary,
    ),
    StatData(
      Icons.schedule_rounded,
      'Bugun Teslim',
      '4',
      'Takvimde kritik teslim',
      AppPalette.warning,
    ),
    StatData(
      Icons.rate_review_rounded,
      'Revizyon Bekleyen',
      '7',
      'Inceleme kuyrugu',
      Color(0xFF7A7AE6),
    ),
    StatData(
      Icons.done_all_rounded,
      'Tamamlanan',
      '18',
      'Son 30 gun',
      AppPalette.success,
    ),
  ];

  final tasks = const [
    TaskRow(
      'Jenerator periyodik kontrol',
      'Merkez Plaza',
      'Admin',
      'Devam Ediyor',
      'Yuksek',
      '2026-03-11',
      '2026-03-10 09:14',
    ),
    TaskRow(
      'Yangin paneli raporu',
      'Nova Residence',
      'Seda',
      'Beklemede',
      'Orta',
      '2026-03-12',
      '2026-03-10 08:05',
    ),
    TaskRow(
      'Asansor test formu',
      'Kuzey Atolye',
      'Onur',
      'Devam Ediyor',
      'Dusuk',
      '2026-03-13',
      '2026-03-09 18:40',
    ),
  ];

  final activities = const [
    ActivityRow(
      'Yeni gorev atandi',
      'Bakim planlama - 12 dk once',
      AppPalette.success,
    ),
    ActivityRow(
      'Revizyon talebi acildi',
      'Teknik servis / klima - 37 dk once',
      AppPalette.warning,
    ),
    ActivityRow(
      'Calisan vardiya degisikligi',
      'Saha ekibi - 1 saat once',
      AppPalette.primary,
    ),
  ];

  final teamRows = const [
    TeamRow('Admin', 'Operasyon Yoneticisi', 'Aktif', 6, 84),
    TeamRow('Seda Yilmaz', 'Saha Koordinatoru', 'Aktif', 4, 76),
    TeamRow('Onur Kaya', 'Teknisyen', 'Sahada', 3, 69),
  ];

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
                if (wide) SizedBox(width: 188, child: _sidebar()),
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
    final items = <(AppSection, String, IconData, String?)>[
      (AppSection.panel, 'Panel', Icons.grid_view_rounded, null),
      (AppSection.tasks, 'Gorevler', Icons.task_alt_rounded, '4'),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded, null),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined, null),
      (AppSection.performance, 'Performans', Icons.insights_rounded, null),
      (
        AppSection.reports,
        'Raporlar',
        Icons.insert_chart_outlined_rounded,
        null,
      ),
    ];

    return Container(
      color: AppPalette.sidebar,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Operational Suite',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: _selected == item.$1
                          ? AppPalette.primary
                          : Colors.transparent,
                      leading: Icon(item.$3, color: Colors.white, size: 19),
                      title: Text(
                        item.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
                      'AYARLAR',
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
                  label: 'Yardim Merkezi',
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
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'admin@serviskontrol.local',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool wide) {
    const nav = [
      (AppSection.panel, 'Panel'),
      (AppSection.team, 'Calisanlar'),
      (AppSection.tasks, 'Gorevler'),
      (AppSection.reports, 'Raporlar'),
    ];

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
          ],
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Gorev Olustur'),
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
        return _dashboardPage(wide);
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

  Widget _dashboardPage(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Hos geldiniz, Admin',
          subtitle: 'Bugun: 10.03.2026',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final stat in dashboardStats)
              SizedBox(
                width: wide ? 250 : double.infinity,
                child: _StatCard(data: stat),
              ),
            SizedBox(
              width: wide ? 270 : double.infinity,
              child: const _ProductivityCard(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 4, child: _TrendCard()),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _ActivityCard(
                  title: 'Bildirimler',
                  subtitle: 'Son aktiviteler',
                  activities: activities,
                ),
              ),
            ],
          )
        else ...[
          const _TrendCard(),
          const SizedBox(height: 16),
          _ActivityCard(
            title: 'Bildirimler',
            subtitle: 'Son aktiviteler',
            activities: activities,
          ),
        ],
        const SizedBox(height: 18),
        _ProjectCard(
          projects: const [
            ProjectRow('Merkez Plaza', 'Bakim', 0.72),
            ProjectRow('Kuzey Atolye', 'Kontrol', 0.48),
            ProjectRow('Nova Residence', 'Kurulum', 0.89),
          ],
        ),
      ],
    );
  }

  Widget _tasksPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Gorevler',
          subtitle: 'Arama, filtreleme ve gorev detayina hizli erisim.',
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            children: [
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SearchBox(hint: 'Gorev / proje ara...'),
                  _FilterPill(label: 'Durum', value: 'Tumu'),
                  _FilterPill(label: 'Oncelik', value: 'Tumu'),
                  _FilterPill(label: 'Proje', value: 'Tumu'),
                  _ActionPill(label: 'Filtrele', filled: true),
                  _ActionPill(label: 'Sifirla'),
                ],
              ),
              const SizedBox(height: 16),
              _TableCard(
                headers: const [
                  'Gorev',
                  'Proje',
                  'Atanan',
                  'Durum',
                  'Oncelik',
                  'Son Teslim',
                  'Guncelleme',
                ],
                rows: [
                  for (final task in tasks)
                    [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
                        ),
                      ),
                      Text(task.project),
                      Text(task.assignee),
                      _Badge(
                        label: task.status,
                        color: task.status == 'Beklemede'
                            ? AppPalette.warning
                            : AppPalette.primary,
                      ),
                      _Badge(
                        label: task.priority,
                        color: task.priority == 'Yuksek'
                            ? AppPalette.danger
                            : task.priority == 'Orta'
                            ? AppPalette.warning
                            : AppPalette.success,
                      ),
                      Text(task.dueDate),
                      Text(task.updatedAt),
                    ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _revisionsPage(bool wide) {
    final left = _RevisionBucket(
      title: 'Inceleme Bekleyen',
      subtitle: 'Durum: Incelemede',
      items: const [
        RevisionLine('Kamera altyapisi', 'Merkez Plaza / Admin'),
        RevisionLine('UPS kapasite notu', 'Kuzey Atolye / Seda'),
      ],
    );
    final right = _RevisionBucket(
      title: 'Revizyonda',
      subtitle: 'Durum: Revizyonda',
      items: const [
        RevisionLine('Isi pompasi etiketleme', 'Nova Residence / Onur'),
        RevisionLine('Panel kablo rotasi', 'Merkez Plaza / Burak'),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Revizyonlar',
          subtitle:
              'Inceleme bekleyen ve revizyondaki isleri tek ekrandan yonetin.',
        ),
        const SizedBox(height: 18),
        const _Card(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SearchBox(hint: 'Gorev / proje ara...'),
              _FilterPill(label: 'Proje', value: 'Tumu'),
              _ActionPill(label: 'Filtrele', filled: true),
              _ActionPill(label: 'Sifirla'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          )
        else ...[
          left,
          const SizedBox(height: 16),
          right,
        ],
      ],
    );
  }

  Widget _teamPage(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Ekibe Genel Bakis',
          subtitle:
              'Ekibinizin performansini ve gorevlerini etkili sekilde yonetin.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            SizedBox(
              width: 300,
              child: _StatCard(
                data: StatData(
                  Icons.groups_2_rounded,
                  'Toplam Calisan',
                  '14',
                  'Aktif personel',
                  AppPalette.primary,
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: _StatCard(
                data: StatData(
                  Icons.task_rounded,
                  'Aktif Gorevler',
                  '27',
                  'Acik gorev',
                  AppPalette.warning,
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: _StatCard(
                data: StatData(
                  Icons.pending_actions_rounded,
                  'Bekleyen Onaylar',
                  '5',
                  'Inceleme kuyrugu',
                  AppPalette.danger,
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: _StatCard(
                data: StatData(
                  Icons.analytics_rounded,
                  'Ekip Performansi',
                  '%78',
                  'Ortalama skor',
                  AppPalette.success,
                ),
              ),
            ),
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
                    title: 'Bekleyen Duzeltmeler',
                    subtitle: 'Inceleme / revizyon kuyrugu',
                    message: 'Bekleyen is yok.',
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
              title: 'Bekleyen Duzeltmeler',
              subtitle: 'Inceleme / revizyon kuyrugu',
              message: 'Bekleyen is yok.',
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
            title: 'Calisan Performansi',
            subtitle: 'Kisi bazli ozet',
            action: 'Tumunu Gor',
          ),
          const SizedBox(height: 16),
          _TableCard(
            headers: const [
              'Calisan',
              'Durum',
              'Aktif Gorevler',
              'Performans',
              'Islemler',
            ],
            rows: [
              for (final row in teamRows)
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
                  Text('${row.activeTasks} Gorev'),
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
          subtitle: 'Calisan bazli temel metrikler ve skor.',
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ActionPill(label: 'CSV Indir'),
              const SizedBox(height: 16),
              _TableCard(
                headers: const [
                  'Calisan',
                  'Rol',
                  'Acik',
                  'Tamamlanan',
                  'Zamaninda',
                  'Gec',
                  'Ort. Revizyon',
                  'Skor',
                ],
                rows: [
                  const [
                    Text(
                      'Admin',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _Badge(label: 'Operasyon', color: AppPalette.primary),
                    Text('6'),
                    Text('14'),
                    Text('91%'),
                    Text('1'),
                    Text('0.4'),
                    _Badge(
                      label: '84 / 100 - Guvenli',
                      color: AppPalette.success,
                    ),
                  ],
                  const [
                    Text(
                      'Seda Yilmaz',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _Badge(label: 'Koordinator', color: AppPalette.primary),
                    Text('4'),
                    Text('11'),
                    Text('82%'),
                    Text('2'),
                    Text('0.9'),
                    _Badge(
                      label: '76 / 100 - Dikkat',
                      color: AppPalette.warning,
                    ),
                  ],
                  const [
                    Text(
                      'Onur Kaya',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    _Badge(label: 'Teknisyen', color: AppPalette.primary),
                    Text('3'),
                    Text('9'),
                    Text('74%'),
                    Text('3'),
                    Text('1.3'),
                    _Badge(label: '69 / 100 - Izle', color: AppPalette.danger),
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
    const reportStats = [
      StatData(
        Icons.schedule_rounded,
        'Bugun Teslim',
        '4',
        'Acil gorev',
        AppPalette.primary,
      ),
      StatData(
        Icons.report_gmailerrorred_rounded,
        'Geciken',
        '2',
        'Son teslim gecti',
        AppPalette.warning,
      ),
      StatData(
        Icons.rate_review_rounded,
        'Inceleme / Revizyon',
        '5',
        'Kuyruk',
        Color(0xFF7A7AE6),
      ),
      StatData(
        Icons.done_all_rounded,
        'Tamamlanan',
        '18',
        'Son 30 gun',
        AppPalette.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PageHeader(
          title: 'Raporlar',
          subtitle: 'Durum dagilimi, kritik gostergeler ve son aktiviteler.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final stat in reportStats)
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
                        title: 'Durum Dagilimi',
                        subtitle: 'Toplam gorev sayilari',
                        action: 'CSV Indir',
                      ),
                      SizedBox(height: 16),
                      _TableCard(
                        headers: ['Durum', 'Adet'],
                        rows: [
                          [Text('Beklemede'), Text('3')],
                          [Text('Devam Ediyor'), Text('12')],
                          [Text('Incelemede'), Text('2')],
                          [Text('Revizyonda'), Text('3')],
                          [Text('Tamamlandi'), Text('18')],
                          [Text('Iptal'), Text('1')],
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
                  activities: activities,
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
                  title: 'Durum Dagilimi',
                  subtitle: 'Toplam gorev sayilari',
                  action: 'CSV Indir',
                ),
                SizedBox(height: 16),
                _TableCard(
                  headers: ['Durum', 'Adet'],
                  rows: [
                    [Text('Beklemede'), Text('3')],
                    [Text('Devam Ediyor'), Text('12')],
                    [Text('Incelemede'), Text('2')],
                    [Text('Revizyonda'), Text('3')],
                    [Text('Tamamlandi'), Text('18')],
                    [Text('Iptal'), Text('1')],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActivityCard(
            title: 'Son Aktiviteler',
            subtitle: 'Son 20 hareket',
            activities: activities,
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

class _ProductivityCard extends StatelessWidget {
  const _ProductivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF244BCF), Color(0xFF346DF2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18051830),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Verimlilik Skoru',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              _Badge(label: 'Riskli', color: Colors.white),
            ],
          ),
          SizedBox(height: 28),
          Text(
            '78',
            style: TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Zamaninda teslimat: %91',
            style: TextStyle(color: Color(0xB8FFFFFF)),
          ),
          SizedBox(height: 16),
          _WhiteBar(
            label: 'Musteri memnuniyeti',
            value: 0.89,
            trailing: '4.8/5.0',
          ),
          SizedBox(height: 10),
          _WhiteBar(label: 'Ekip kullanimi', value: 0.72, trailing: '%72'),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    const bars = [0.36, 0.88, 0.56, 0.49, 0.61, 0.73, 0.44];
    const days = ['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Performans ve Trendler',
            subtitle: 'Son 7 gunluk aktivite ozeti',
            action: 'Bu Hafta',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 36 + (bars[i] * 150),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: i == 1
                                        ? const [
                                            AppPalette.primary,
                                            Color(0xFF4D80FF),
                                          ]
                                        : const [
                                            Color(0xFFD4E0FF),
                                            Color(0xFFE6EEFF),
                                          ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            days[i],
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
          _SectionHeader(title: title, subtitle: subtitle, action: 'Tumu'),
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

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.projects});
  final List<ProjectRow> projects;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Aktif Projeler',
            subtitle: 'Son 5 proje',
            action: 'Tumunu Gor',
          ),
          const SizedBox(height: 16),
          for (final project in projects) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    project.name[0],
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(project.type),
                    ],
                  ),
                ),
                Text('${(project.progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: project.progress,
                minHeight: 8,
                backgroundColor: AppPalette.primarySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _RevisionBucket extends StatelessWidget {
  const _RevisionBucket({
    required this.title,
    required this.subtitle,
    required this.items,
  });
  final String title;
  final String subtitle;
  final List<RevisionLine> items;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
            action: '${items.length}',
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.meta),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 420),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  ',
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return filled
        ? FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(label),
          )
        : OutlinedButton(
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

class _WhiteBar extends StatelessWidget {
  const _WhiteBar({
    required this.label,
    required this.value,
    required this.trailing,
  });
  final String label;
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
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

class TaskRow {
  const TaskRow(
    this.title,
    this.project,
    this.assignee,
    this.status,
    this.priority,
    this.dueDate,
    this.updatedAt,
  );
  final String title;
  final String project;
  final String assignee;
  final String status;
  final String priority;
  final String dueDate;
  final String updatedAt;
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

class RevisionLine {
  const RevisionLine(this.title, this.meta);
  final String title;
  final String meta;
}
