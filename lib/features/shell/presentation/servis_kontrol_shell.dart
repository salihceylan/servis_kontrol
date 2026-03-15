import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/presentation/dashboard_page.dart';
import 'package:servis_kontrol/features/help/presentation/help_center_page.dart';
import 'package:servis_kontrol/features/performance/presentation/performance_page.dart';
import 'package:servis_kontrol/features/revisions/presentation/revision_page.dart';
import 'package:servis_kontrol/features/reports/presentation/reports_page.dart';
import 'package:servis_kontrol/features/settings/presentation/general_settings_page.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_page.dart';
import 'package:servis_kontrol/features/team/presentation/team_page.dart';

enum AppSection {
  panel,
  tasks,
  revisions,
  team,
  performance,
  reports,
  settings,
  help,
}

class ServisKontrolShell extends StatefulWidget {
  const ServisKontrolShell({
    super.key,
    required this.user,
    required this.apiClient,
    required this.onLogout,
  });

  final AppUser user;
  final ApiClient apiClient;
  final Future<void> Function() onLogout;

  @override
  State<ServisKontrolShell> createState() => _ServisKontrolShellState();
}

class _ServisKontrolShellState extends State<ServisKontrolShell> {
  static const _sidebarBase = Color(0xFF0D2545);
  static const _sidebarPanel = Color(0xFF183659);

  AppSection _selected = AppSection.panel;

  AppUser get _user => widget.user;
  UserRole get _role => _user.role;

  List<(AppSection, String, IconData)> get _sidebarItems => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.performance, 'Performans', Icons.insights_rounded),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined),
      (AppSection.performance, 'Performans', Icons.insights_rounded),
    ],
    UserRole.manager => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined),
      (AppSection.performance, 'Performans', Icons.insights_rounded),
      (AppSection.reports, 'Raporlar', Icons.insert_chart_outlined_rounded),
    ],
    UserRole.superAdmin || UserRole.sales || UserRole.support => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined),
      (AppSection.performance, 'Performans', Icons.insights_rounded),
      (AppSection.reports, 'Raporlar', Icons.insert_chart_outlined_rounded),
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
    UserRole.superAdmin || UserRole.sales || UserRole.support => [
      (AppSection.panel, 'Panel'),
      (AppSection.team, 'Çalışanlar'),
      (AppSection.tasks, 'Görevler'),
      (AppSection.reports, 'Raporlar'),
    ],
  };

  (String, IconData, AppSection) get _primaryAction => switch (_role) {
    UserRole.employee => (
      'Görevlerim',
      Icons.assignment_turned_in_rounded,
      AppSection.tasks,
    ),
    UserRole.teamLead => (
      'Revizyonları İncele',
      Icons.rate_review_rounded,
      AppSection.revisions,
    ),
    UserRole.manager => ('Görev Ata', Icons.add_rounded, AppSection.team),
    UserRole.superAdmin ||
    UserRole.sales ||
    UserRole.support => ('Görev Ata', Icons.add_rounded, AppSection.team),
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
                  backgroundColor: _sidebarBase,
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
                          child: _content(),
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
    return Container(
      color: _sidebarBase,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _sidebarPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Workflow Work OS',
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
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final item in _sidebarItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SidebarTile(
                      icon: item.$3,
                      label: item.$2,
                      selected: _selected == item.$1,
                      onTap: () => setState(() => _selected = item.$1),
                    ),
                  ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 6),
                  child: Text(
                    'Ayarlar',
                    style: TextStyle(
                      color: Color(0x88FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SidebarTile(
                  icon: Icons.settings_outlined,
                  label: 'Genel Ayarlar',
                  selected: _selected == AppSection.settings,
                  onTap: () => setState(() => _selected = AppSection.settings),
                ),
                const SizedBox(height: 4),
                _SidebarTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım Merkezi',
                  selected: _selected == AppSection.help,
                  onTap: () => setState(() => _selected = AppSection.help),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
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
                          fontSize: 13,
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async => widget.onLogout(),
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
        border: Border(bottom: BorderSide(color: AppPalette.border)),
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: Icon(Icons.search_rounded),
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
          _RoundAction(
            icon: Icons.settings_outlined,
            onTap: () => setState(() => _selected = AppSection.settings),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    switch (_selected) {
      case AppSection.panel:
        return DashboardPage(apiClient: widget.apiClient);
      case AppSection.tasks:
        return TaskPage(user: _user, apiClient: widget.apiClient);
      case AppSection.revisions:
        return RevisionPage(user: _user, apiClient: widget.apiClient);
      case AppSection.team:
        return TeamPage(
          user: _user,
          apiClient: widget.apiClient,
          onOpenTasks: () => setState(() => _selected = AppSection.tasks),
          onOpenRevisions: () =>
              setState(() => _selected = AppSection.revisions),
        );
      case AppSection.performance:
        return PerformancePage(apiClient: widget.apiClient);
      case AppSection.reports:
        return ReportsPage(user: _user, apiClient: widget.apiClient);
      case AppSection.settings:
        return GeneralSettingsPage(apiClient: widget.apiClient);
      case AppSection.help:
        return HelpCenterPage(apiClient: widget.apiClient);
    }
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      horizontalTitleGap: 8,
      minLeadingWidth: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected ? AppPalette.primary : Colors.transparent,
      leading: Icon(icon, color: Colors.white, size: 18),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppPalette.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
        ),
        child: Icon(icon, color: AppPalette.text, size: 20),
      ),
    );
  }
}
