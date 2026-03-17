import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/dashboard/presentation/dashboard_page.dart';
import 'package:servis_kontrol/features/help/presentation/help_center_page.dart';
import 'package:servis_kontrol/features/notifications/application/notification_center_controller.dart';
import 'package:servis_kontrol/features/notifications/presentation/notification_center_dialog.dart';
import 'package:servis_kontrol/features/operations_messages/application/operation_message_dock_controller.dart';
import 'package:servis_kontrol/features/operations_messages/presentation/operation_message_dock.dart';
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
  AppSection _selected = AppSection.panel;
  late final OperationMessageDockController _messageDockController;
  late final NotificationCenterController _notificationController;

  AppUser get _user => widget.user;
  UserRole get _role => _user.role;

  bool get _canAccessSettings => switch (_role) {
    UserRole.manager ||
    UserRole.superAdmin ||
    UserRole.sales ||
    UserRole.support => true,
    _ => false,
  };

  List<AppSection> get _availableSections => switch (_role) {
    UserRole.employee => const [
      AppSection.panel,
      AppSection.tasks,
      AppSection.revisions,
      AppSection.performance,
      AppSection.help,
    ],
    UserRole.teamLead => const [
      AppSection.panel,
      AppSection.team,
      AppSection.tasks,
      AppSection.revisions,
      AppSection.performance,
      AppSection.help,
    ],
    UserRole.manager ||
    UserRole.superAdmin ||
    UserRole.sales ||
    UserRole.support => const [
      AppSection.panel,
      AppSection.team,
      AppSection.tasks,
      AppSection.revisions,
      AppSection.performance,
      AppSection.reports,
      AppSection.settings,
      AppSection.help,
    ],
  };

  AppSection get _visibleSelected =>
      _availableSections.contains(_selected) ? _selected : AppSection.panel;

  (IconData, AppSection) get _quickAction => _canAccessSettings
      ? (Icons.settings_outlined, AppSection.settings)
      : (Icons.help_outline_rounded, AppSection.help);

  @override
  void initState() {
    super.initState();
    _messageDockController = OperationMessageDockController(
      user: widget.user,
      apiClient: widget.apiClient,
    );
    _notificationController = NotificationCenterController(
      apiClient: widget.apiClient,
    );
  }

  @override
  void dispose() {
    _messageDockController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  Future<void> _openNotifications() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          NotificationCenterDialog(controller: _notificationController),
    );
  }

  // ── Sidebar items (desktop) ───────────────────────────────────────────────

  List<(AppSection, String, IconData)> get _sidebarItems => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevlerim', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlarım', Icons.autorenew_rounded),
      (AppSection.performance, 'Performansım', Icons.insights_rounded),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.team, 'Takımım', Icons.groups_2_outlined),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.performance, 'Performans', Icons.insights_rounded),
    ],
    UserRole.manager => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
      (AppSection.team, 'Çalışanlar', Icons.groups_2_outlined),
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

  // ── Bottom nav primary tabs (mobile) ─────────────────────────────────────

  List<(AppSection, String, IconData)> get _primaryTabs => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevlerim', Icons.task_alt_rounded),
      (AppSection.revisions, 'Revizyonlarım', Icons.autorenew_rounded),
      (AppSection.performance, 'Performansım', Icons.insights_rounded),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.team, 'Takımım', Icons.groups_2_outlined),
      (AppSection.revisions, 'Revizyonlar', Icons.autorenew_rounded),
    ],
    UserRole.manager ||
    UserRole.superAdmin ||
    UserRole.sales ||
    UserRole.support => [
      (AppSection.panel, 'Panel', Icons.grid_view_rounded),
      (AppSection.tasks, 'Görevler', Icons.task_alt_rounded),
      (AppSection.team, 'Ekip', Icons.groups_2_outlined),
      (AppSection.reports, 'Raporlar', Icons.insert_chart_outlined_rounded),
    ],
  };

  /// Sections that overflow into "Daha Fazla" sheet on mobile.
  List<(AppSection, String, IconData)> get _moreSections {
    final primarySet = _primaryTabs.map((t) => t.$1).toSet();
    final allItems = [
      ..._sidebarItems,
      if (_canAccessSettings)
        (AppSection.settings, 'Genel Ayarlar', Icons.settings_outlined),
      (AppSection.help, 'Yardım Merkezi', Icons.help_outline_rounded),
    ];
    return allItems.where((t) => !primarySet.contains(t.$1)).toList();
  }

  /// Bottom nav index for the current section (last index = "Daha Fazla").
  int get _currentBottomNavIndex {
    final idx = _primaryTabs.indexWhere((t) => t.$1 == _visibleSelected);
    return idx >= 0 ? idx : _primaryTabs.length;
  }

  void _openMoreSheet(AppRolePalette palette) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              for (final item in _moreSections)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: _visibleSelected == item.$1
                      ? palette.primary.withValues(alpha: 0.1)
                      : null,
                  leading: Icon(item.$3, color: palette.primary),
                  title: Text(
                    item.$2,
                    style: TextStyle(
                      fontWeight: _visibleSelected == item.$1
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _selected = item.$1);
                  },
                ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onLogout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Top nav items (desktop top bar) ──────────────────────────────────────

  List<(AppSection, String)> get _topNavItems => switch (_role) {
    UserRole.employee => [
      (AppSection.panel, 'Panel'),
      (AppSection.tasks, 'Görevlerim'),
      (AppSection.revisions, 'Revizyonlarım'),
      (AppSection.performance, 'Performansım'),
    ],
    UserRole.teamLead => [
      (AppSection.panel, 'Panel'),
      (AppSection.team, 'Takımım'),
      (AppSection.tasks, 'Görevler'),
      (AppSection.revisions, 'Revizyonlar'),
      (AppSection.performance, 'Performans'),
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
      'Teslim Güncelle',
      Icons.assignment_turned_in_rounded,
      AppSection.tasks,
    ),
    UserRole.teamLead => (
      'Görev Ata',
      Icons.add_task_rounded,
      AppSection.tasks,
    ),
    UserRole.manager => ('Görev Ata', Icons.add_rounded, AppSection.team),
    UserRole.superAdmin ||
    UserRole.sales ||
    UserRole.support => ('Görev Ata', Icons.add_rounded, AppSection.team),
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        return wide ? _buildWide() : _buildNarrow();
      },
    );
  }

  // Desktop layout — unchanged
  Widget _buildWide() {
    final palette = context.rolePalette;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                SizedBox(width: 244, child: _sidebar()),
                Expanded(
                  child: Column(
                    children: [
                      _desktopTopBar(palette),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: _content(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            OperationMessageDock(
              user: _user,
              controller: _messageDockController,
            ),
          ],
        ),
      ),
    );
  }

  // Mobile layout — bottom nav
  Widget _buildNarrow() {
    final palette = context.rolePalette;
    final tabs = _primaryTabs;
    final currentIndex = _currentBottomNavIndex;

    return Scaffold(
      appBar: _mobileAppBar(palette),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == tabs.length) {
            _openMoreSheet(palette);
          } else {
            setState(() => _selected = tabs[index].$1);
          }
        },
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.$3),
              label: tab.$2,
            ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'Daha Fazla',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: _content(),
            ),
            OperationMessageDock(
              user: _user,
              controller: _messageDockController,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _mobileAppBar(AppRolePalette palette) {
    final primaryAction = _primaryAction;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: palette.primary,
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ServisKontrol',
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => setState(() => _selected = primaryAction.$3),
          style: FilledButton.styleFrom(
            backgroundColor: palette.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(primaryAction.$2, size: 16),
          label: Text(
            primaryAction.$1,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _notificationController,
          builder: (context, _) {
            final unreadCount = _notificationController.unreadCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _openNotifications,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppPalette.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Desktop sidebar ───────────────────────────────────────────────────────

  Widget _sidebar() {
    final palette = context.rolePalette;
    final selected = _visibleSelected;
    return Container(
      color: palette.sidebar,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.sidebarSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: palette.primary,
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
                      selected: selected == item.$1,
                      onTap: () => setState(() => _selected = item.$1),
                    ),
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Text(
                    _canAccessSettings ? 'Ayarlar' : 'Yardım',
                    style: const TextStyle(
                      color: Color(0x88FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_canAccessSettings) ...[
                  _SidebarTile(
                    icon: Icons.settings_outlined,
                    label: 'Genel Ayarlar',
                    selected: selected == AppSection.settings,
                    onTap: () =>
                        setState(() => _selected = AppSection.settings),
                  ),
                  const SizedBox(height: 4),
                ],
                _SidebarTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım Merkezi',
                  selected: selected == AppSection.help,
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
                  backgroundColor: palette.primarySoft,
                  child: Text(
                    _user.initials,
                    style: TextStyle(
                      color: palette.primary,
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

  // ── Desktop top bar ───────────────────────────────────────────────────────

  Widget _desktopTopBar(AppRolePalette palette) {
    final nav = _topNavItems;
    final primaryAction = _primaryAction;
    final selected = _visibleSelected;
    final quickAction = _quickAction;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: palette.surfaceMuted,
              ),
            ),
          ),
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
                        onPressed: () =>
                            setState(() => _selected = item.$1),
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            color: selected == item.$1
                                ? palette.text
                                : palette.muted,
                            fontWeight: selected == item.$1
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
          FilledButton.icon(
            onPressed: () => setState(() => _selected = primaryAction.$3),
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(primaryAction.$2),
            label: Text(primaryAction.$1),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _notificationController,
            builder: (context, _) {
              final unreadCount = _notificationController.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _RoundAction(
                    icon: Icons.notifications_none_rounded,
                    onTap: _openNotifications,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
          _RoundAction(
            icon: quickAction.$1,
            onTap: () => setState(() => _selected = quickAction.$2),
          ),
        ],
      ),
    );
  }

  // ── Content router ────────────────────────────────────────────────────────

  Widget _content() {
    switch (_visibleSelected) {
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

// ── Shared widgets ────────────────────────────────────────────────────────────

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
    final palette = context.rolePalette;
    return ListTile(
      dense: true,
      onTap: onTap,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      horizontalTitleGap: 8,
      minLeadingWidth: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected ? palette.primary : Colors.transparent,
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
    final palette = context.rolePalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, color: palette.text, size: 20),
      ),
    );
  }
}
