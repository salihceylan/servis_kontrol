import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/presentation/dashboard_page.dart';
import 'package:servis_kontrol/features/performance/presentation/performance_page.dart';
import 'package:servis_kontrol/features/revisions/presentation/revision_page.dart';
import 'package:servis_kontrol/features/reports/presentation/reports_page.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_page.dart';
import 'package:servis_kontrol/features/team/presentation/team_page.dart';

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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.sidebarSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                          fontSize: 14,
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
              borderRadius: BorderRadius.circular(18),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppPalette.border),
        ),
      ),
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
                  prefixIcon: const Icon(Icons.search_rounded),
                  fillColor: AppPalette.surfaceMuted,
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
                borderRadius: BorderRadius.circular(18),
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

  Widget _revisionsPage(bool _) {
    return RevisionPage(user: _user);
  }

  Widget _teamPage(bool _) {
    return TeamPage(
      user: _user,
      onOpenTasks: () => setState(() => _selected = AppSection.tasks),
      onOpenRevisions: () => setState(() => _selected = AppSection.revisions),
    );
  }

  Widget _performancePage() {
    return PerformancePage(user: _user);
  }

  Widget _reportsPage(bool _) {
    return ReportsPage(user: _user);
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

