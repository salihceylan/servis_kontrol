import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';
import 'package:servis_kontrol/features/team/presentation/team_group_dialog.dart';
import 'package:servis_kontrol/features/team/presentation/team_member_dialog.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({
    super.key,
    required this.user,
    required this.apiClient,
    required this.onOpenTasks,
    required this.onOpenRevisions,
  });

  final AppUser user;
  final ApiClient apiClient;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenRevisions;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  late final TeamController _controller;
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  String? _noteMemberId;

  UserRole get _role => widget.user.role;
  bool get _isTeamLeadView => _role == UserRole.teamLead;

  String get _loadingMessage => _isTeamLeadView
      ? 'Takım üyeleri, görev yükü ve risk sinyalleri sunucudan alınıyor.'
      : 'Çalışanlar, takımlar ve yetki kayıtları sunucudan alınıyor.';

  String get _heroTitle => _isTeamLeadView
      ? 'Takım görünümü ve iş dağılımı'
      : 'Çalışan, takım ve izin yönetimi';

  String get _heroSubtitle => _isTeamLeadView
      ? 'Sorumlu olduğun takımın iş yükünü izle, görev akışını yönet ve revizyon risklerini yakından takip et.'
      : 'Manager kullanıcısı ekip kurabilir, çalışan ekleyebilir, şifre belirleyebilir, takım ataması yapabilir ve personel detaylarını görebilir.';

  String get _memberListSubtitle => _isTeamLeadView
      ? 'Takımındaki çalışanlar kullanıcı adı, rol, aktif görev ve risk bilgileriyle listelenir.'
      : 'Tüm personel kullanıcı adı, takım, rol ve aktif görev bilgileriyle listelenir.';

  String get _detailSubtitle => _isTeamLeadView
      ? 'Takım üyesi bilgileri, rol yetkileri ve iş yükü özeti.'
      : 'Kullanıcı bilgileri, izinler, takım ve yönetici notu.';

  String get _teamCardSubtitle => _isTeamLeadView
      ? 'Sorumlu olduğun takımın üye yapısını, aktif görev yükünü ve görev dağılımını izle.'
      : 'Manager birden fazla takım oluşturabilir, takım sorumlusu atayabilir ve personeli takımlara dağıtabilir.';

  String get _emptyMembersMessage => _isTeamLeadView
      ? 'Bu takım için görünen çalışan veya görev kaydı yok.'
      : 'Bu şirket için görünen çalışan veya takım kaydı yok.';

  @override
  void initState() {
    super.initState();
    _controller = TeamController(
      user: widget.user,
      apiClient: widget.apiClient,
    );
    _searchController.addListener(() {
      _controller.updateQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.rolePalette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return StatePanel.loading(
            title: 'Ekip verileri yükleniyor',
            message: _loadingMessage,
          );
        }
        if (_controller.errorMessage != null && !_controller.hasData) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }

        final selected = _controller.selectedMember;
        if (selected?.id != _noteMemberId) {
          _noteMemberId = selected?.id;
          _noteController.text = selected?.lastManagerNote ?? '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(palette),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.metrics)
                  SizedBox(
                    width: 220,
                    child: _metricCard(
                      metric.label,
                      metric.value,
                      metric.caption,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Filtreler',
              subtitle: 'Çalışanları, takımları ve risk sinyallerini filtrele.',
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Çalışan, kullanıcı adı, departman veya takım ara',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: palette.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilterChip(
                        selected: _controller.flaggedOnly,
                        label: const Text('Sadece kritik risk'),
                        onSelected: _controller.toggleFlaggedOnly,
                      ),
                      if (_controller.canToggleManagerMode)
                        FilterChip(
                          selected: _controller.managerMode,
                          label: Text(
                            _controller.managerMode
                                ? 'Yönetici görünümü'
                                : 'Özet görünümü',
                          ),
                          onSelected: _controller.toggleManagerMode,
                        ),
                      FilledButton.tonalIcon(
                        onPressed: widget.onOpenTasks,
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Görevler'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: widget.onOpenRevisions,
                        icon: const Icon(Icons.rate_review_rounded),
                        label: const Text('Revizyonlar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1180;
                final members = _membersCard();
                final detail = _detailCard(selected);
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: members),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: detail),
                    ],
                  );
                }
                return Column(
                  children: [members, const SizedBox(height: 16), detail],
                );
              },
            ),
            const SizedBox(height: 16),
            _teamsCard(),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final corrections = _signalsCard(
                  title: 'Revizyon Sinyalleri',
                  subtitle: 'Takım bazlı kalite ve düzeltme bekleyen işler.',
                  action: TextButton.icon(
                    onPressed: widget.onOpenRevisions,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ac'),
                  ),
                  items: [
                    for (final item in _controller.corrections)
                      _signalTile(
                        item.title,
                        '${item.owner} | ${item.ageLabel}',
                        item.summary,
                      ),
                  ],
                  empty: 'Bekleyen revizyon sinyali yok.',
                );
                final alerts = _signalsCard(
                  title: 'Operasyon Uyarilari',
                  subtitle: 'Aşıri yük ve kritik teslim sinyalleri.',
                  action: TextButton.icon(
                    onPressed: widget.onOpenTasks,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ac'),
                  ),
                  items: [
                    for (final item in _controller.alerts)
                      _signalTile(
                        item.title,
                        item.project,
                        item.detail,
                        badge: item.riskLevel.label,
                      ),
                  ],
                  empty: 'Aktif operasyon uyarısı yok.',
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: corrections),
                      const SizedBox(width: 16),
                      Expanded(child: alerts),
                    ],
                  );
                }
                return Column(
                  children: [corrections, const SizedBox(height: 16), alerts],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _hero(AppRolePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.sidebar, palette.sidebarSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _heroTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _heroSubtitle,
            style: TextStyle(color: Color(0xD0FFFFFF), height: 1.5),
          ),
          if (_controller.canManageWorkspace) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _controller.isSaving ? null : _openCreateMember,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Çalışan Ekle'),
                ),
                OutlinedButton.icon(
                  onPressed: _controller.isSaving ? null : _openCreateTeam,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Takım Ekle'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _membersCard() {
    final members = _controller.members;
    if (members.isEmpty) {
      return StatePanel.empty(
        title: 'Çalışan kaydı bulunamadı',
        message: _emptyMembersMessage,
      );
    }
    final palette = context.rolePalette;
    return _card(
      title: 'Çalışanlar',
      subtitle: _memberListSubtitle,
      child: Column(
        children: [
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: _controller.selectedMember?.id == member.id
                    ? palette.primarySoft
                    : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    _controller.selectMember(member.id);
                    _noteController.text = member.lastManagerNote ?? '';
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: palette.primary.withValues(
                                alpha: 0.14,
                              ),
                              foregroundColor: palette.primary,
                              child: Text(_initials(member.name)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${member.role} | ${member.loginName}',
                                    style: TextStyle(
                                      color: palette.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_controller.canManageWorkspace &&
                                member.canEdit)
                              IconButton(
                                onPressed: () => _openEditMember(member),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip(
                              member.userCode.isEmpty
                                  ? 'Kod yok'
                                  : member.userCode,
                              palette.primary,
                            ),
                            _chip(
                              member.teamName ?? 'Takım atanmadı',
                              palette.success,
                            ),
                            _chip(
                              member.status,
                              member.statusCode == 'passive'
                                  ? palette.danger
                                  : palette.success,
                            ),
                            _chip(
                              member.riskLevel.label,
                              _riskColor(member.riskLevel, palette),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _miniMetric(
                                'Aktif Görev',
                                '${member.activeTasks}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _miniMetric(
                                'Performans',
                                '%${member.performanceScore}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _miniMetric(
                                'Kapasite',
                                '%${member.capacityPercent.round()}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailCard(TeamMember? member) {
    if (member == null) {
      return const StatePanel.empty(
        title: 'Çalışan seçilmedi',
        message: 'Detayları görmek için listeden bir çalışan seç.',
      );
    }
    final palette = context.rolePalette;
    return _card(
      title: 'Çalışan Detayı',
      subtitle: _detailSubtitle,
      action: _controller.canManageWorkspace && member.canEdit
          ? OutlinedButton.icon(
              onPressed: () => _openEditMember(member),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Düzenle'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: palette.primary.withValues(alpha: 0.16),
                foregroundColor: palette.primary,
                child: Text(
                  _initials(member.name),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.role} | ${member.loginName}',
                      style: TextStyle(
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                member.userCode.isEmpty ? 'Kod yok' : member.userCode,
                palette.primary,
              ),
              _chip(member.teamName ?? 'Takım atanmadı', palette.success),
              _chip(
                member.status,
                member.statusCode == 'passive'
                    ? palette.danger
                    : palette.success,
              ),
              _chip(member.trackedHoursLabel, palette.warning),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infoBox(
                'E-posta',
                member.email.isEmpty ? 'Kayıt yok' : member.email,
              ),
              _infoBox(
                'Telefon',
                member.phone.isEmpty ? 'Kayıt yok' : member.phone,
              ),
              _infoBox(
                'Departman',
                member.department.isEmpty ? 'Kayıt yok' : member.department,
              ),
              _infoBox(
                'Unvan',
                member.jobTitle.isEmpty ? 'Kayıt yok' : member.jobTitle,
              ),
              _infoBox(
                'Çalışma',
                member.workPreference.isEmpty
                    ? 'Kayıt yok'
                    : member.workPreference,
              ),
              _infoBox('İş yükü', member.workloadStatusLabel),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniMetric('Aktif Görev', '${member.activeTasks}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMetric('Tamamlanan', '${member.completedTasks}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniMetric('Performans', '%${member.performanceScore}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Atanan Yetkiler',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (member.permissions.isEmpty)
            Text(
              'Ek izin tanımı yok. Rol bazlı yetkiler geçerli.',
              style: TextStyle(color: palette.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in member.permissions.toList()..sort())
                  _chip(item, palette.primary),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Odak Notu',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            member.focusNote,
            style: TextStyle(color: palette.muted, height: 1.5),
          ),
          if (_controller.canManageWorkspace) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Yönetici notu',
                hintText: 'İzin, görev veya takip notu yaz',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _controller.isSaving ? null : _saveManagerNote,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Notu Kaydet'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamsCard() {
    final palette = context.rolePalette;
    return _card(
      title: 'Takımlar',
      subtitle: _teamCardSubtitle,
      action: _controller.canManageWorkspace
          ? OutlinedButton.icon(
              onPressed: _controller.isSaving ? null : _openCreateTeam,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Takım Ekle'),
            )
          : null,
      child: Column(
        children: [
          if (_controller.teams.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Henüz takım kaydı yok.'),
            )
          else
            for (final team in _controller.teams)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Takım kodu: ${team.code}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_controller.canManageWorkspace)
                            IconButton(
                              onPressed: () => _openEditTeam(team),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(
                            team.managerName ?? 'Takım sorumlusu yok',
                            palette.primary,
                          ),
                          _chip('${team.memberCount} üye', palette.success),
                          _chip(
                            '${team.activeTaskCount} aktif görev',
                            palette.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final member in _controller.members.where(
                            (m) => m.teamId == team.id,
                          ))
                            _chip(
                              '${member.name} (${member.loginName})',
                              palette.sidebarSoft,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _signalsCard({
    required String title,
    required String subtitle,
    required Widget action,
    required List<Widget> items,
    required String empty,
  }) {
    return _card(
      title: title,
      subtitle: subtitle,
      action: action,
      child: items.isEmpty
          ? Align(alignment: Alignment.centerLeft, child: Text(empty))
          : Column(children: items),
    );
  }

  Widget _signalTile(
    String title,
    String subtitle,
    String detail, {
    String? badge,
  }) {
    final palette = context.rolePalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (badge != null) _chip(badge, palette.warning),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(detail, style: TextStyle(color: palette.muted, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) {
    final palette = context.rolePalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: palette.muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, String caption) {
    final palette = context.rolePalette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption, style: TextStyle(color: palette.muted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    final palette = context.rolePalette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    final palette = context.rolePalette;
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _openCreateMember() async {
    final draft = await showTeamMemberDialog(
      context,
      teams: _controller.teams,
      permissionOptions: _controller.permissionOptions,
      roleOptions: _controller.roleOptions,
    );
    if (!mounted || draft == null) {
      return;
    }
    final success = await _controller.createMember(draft);
    _feedback(
      success,
      'Çalışan kaydı oluşturuldu.',
      'Çalışan kaydı oluşturulamadı.',
    );
  }

  Future<void> _openEditMember(TeamMember member) async {
    final draft = await showTeamMemberDialog(
      context,
      teams: _controller.teams,
      permissionOptions: _controller.permissionOptions,
      roleOptions: _controller.roleOptions,
      initial: member,
    );
    if (!mounted || draft == null) {
      return;
    }
    final success = await _controller.updateMember(
      memberId: member.id,
      draft: draft,
    );
    _feedback(
      success,
      'Çalışan bilgileri güncellendi.',
      'Çalışan kaydı güncellenemedi.',
    );
  }

  Future<void> _openCreateTeam() async {
    final draft = await showTeamGroupDialog(
      context,
      members: _controller.members,
    );
    if (!mounted || draft == null) {
      return;
    }
    final success = await _controller.createTeam(draft);
    _feedback(success, 'Takım oluşturuldu.', 'Takım oluşturulamadı.');
  }

  Future<void> _openEditTeam(ManagedTeam team) async {
    final draft = await showTeamGroupDialog(
      context,
      members: _controller.members,
      initial: team,
    );
    if (!mounted || draft == null) {
      return;
    }
    final success = await _controller.updateTeam(teamId: team.id, draft: draft);
    _feedback(success, 'Takım bilgileri güncellendi.', 'Takım güncellenemedi.');
  }

  Future<void> _saveManagerNote() async {
    final success = await _controller.addManagerNote(_noteController.text);
    _feedback(
      success,
      'Yönetici notu kaydedildi.',
      'Yönetici notu kaydedilemedi.',
    );
  }

  void _feedback(bool success, String ok, String fallback) {
    if (!mounted) {
      return;
    }
    final message = success ? ok : (_controller.errorMessage ?? fallback);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _initials(String value) {
  final parts = value
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _riskColor(MemberRiskLevel riskLevel, AppRolePalette palette) =>
    switch (riskLevel) {
      MemberRiskLevel.low => palette.success,
      MemberRiskLevel.medium => palette.warning,
      MemberRiskLevel.high => palette.danger,
    };
