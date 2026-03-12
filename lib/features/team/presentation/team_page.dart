import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({
    super.key,
    required this.user,
    required this.onOpenTasks,
    required this.onOpenRevisions,
  });

  final AppUser user;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenRevisions;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  late final TeamController _controller;
  final _searchController = TextEditingController();
  final _managerNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TeamController(user: widget.user);
    _searchController.addListener(() {
      _controller.updateQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _managerNoteController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeamHeader(
              role: widget.user.role,
              canToggleManagerMode: _controller.canToggleManagerMode,
              managerMode: _controller.managerMode,
              onManagerModeChanged: _controller.toggleManagerMode,
            ),
            const SizedBox(height: 18),
            _QuickActions(
              role: widget.user.role,
              correctionsCount: _controller.corrections.length,
              alertsCount: _controller.alerts.length,
              flaggedOnly: _controller.flaggedOnly,
              onOpenTasks: widget.onOpenTasks,
              onOpenRevisions: widget.onOpenRevisions,
              onToggleRiskMode: () {
                final nextValue = !_controller.flaggedOnly;
                _controller.toggleFlaggedOnly(nextValue);
                _showFeedback(
                  nextValue
                      ? 'Alarm takibi açıldı. Kritik kişiler filtrelendi.'
                      : 'Alarm filtresi kapatıldı.',
                );
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.metrics)
                  SizedBox(width: 250, child: _MetricCard(metric: metric)),
              ],
            ),
            const SizedBox(height: 18),
            _FilterBar(
              searchController: _searchController,
              flaggedOnly: _controller.flaggedOnly,
              onFlaggedOnlyChanged: _controller.toggleFlaggedOnly,
              onReset: () {
                _searchController.clear();
                _controller.toggleFlaggedOnly(false);
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final membersPanel = _MembersPanel(
                  members: _controller.members,
                  selectedMemberId: _controller.selectedMember?.id,
                  onSelect: _controller.selectMember,
                );
                final detailPanel = _MemberDetailPanel(
                  role: widget.user.role,
                  member: _controller.selectedMember,
                  managerNoteController: _managerNoteController,
                  onSaveNote: () {
                    final note = _managerNoteController.text.trim();
                    if (note.isEmpty) {
                      return;
                    }
                    _controller.addManagerNote(note);
                    _managerNoteController.clear();
                    _showFeedback('Yönetici yorumu kaydedildi.');
                  },
                  onOpenTasks: widget.onOpenTasks,
                  onOpenRevisions: widget.onOpenRevisions,
                );
                final queues = _QueuesPanel(
                  corrections: _controller.corrections,
                  alerts: _controller.alerts,
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: membersPanel),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            detailPanel,
                            const SizedBox(height: 16),
                            queues,
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    membersPanel,
                    const SizedBox(height: 16),
                    detailPanel,
                    const SizedBox(height: 16),
                    queues,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.role,
    required this.canToggleManagerMode,
    required this.managerMode,
    required this.onManagerModeChanged,
  });

  final UserRole role;
  final bool canToggleManagerMode;
  final bool managerMode;
  final ValueChanged<bool> onManagerModeChanged;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (role) {
      UserRole.employee => (
        'Bağlı Olduğun Ekip',
        'Lider, yönetici ve risk görünümü tek akışta burada.',
      ),
      UserRole.teamLead => (
        'Ekip Yönetimi',
        'Çalışan kartları, düzeltme kuyruğu ve bayraklı işler burada.',
      ),
      UserRole.manager => (
        'Yönetici Modu',
        'Görev dağıtımı, revizyon onayı ve alarm takibi tek panelde.',
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppPalette.muted, height: 1.5),
              ),
            ],
          ),
        ),
        if (canToggleManagerMode) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppPalette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yönetici modu',
                      style: TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daha geniş kuyruk ve alarm görünümü',
                      style: TextStyle(color: AppPalette.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Switch.adaptive(
                  value: managerMode,
                  onChanged: onManagerModeChanged,
                  activeThumbColor: AppPalette.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.role,
    required this.correctionsCount,
    required this.alertsCount,
    required this.flaggedOnly,
    required this.onOpenTasks,
    required this.onOpenRevisions,
    required this.onToggleRiskMode,
  });

  final UserRole role;
  final int correctionsCount;
  final int alertsCount;
  final bool flaggedOnly;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenRevisions;
  final VoidCallback onToggleRiskMode;

  @override
  Widget build(BuildContext context) {
    final taskTitle = role == UserRole.manager ? 'Görev Ata' : 'Görev Akışı';
    final taskSubtitle = role == UserRole.employee
        ? 'Kendi açık işlerini ve teslimlerini aç'
        : 'İş yükünü açıp sorumluları yönlendir';

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 260,
          child: _ActionCard(
            icon: Icons.assignment_ind_rounded,
            title: taskTitle,
            subtitle: taskSubtitle,
            badgeText: role == UserRole.manager ? 'Canlı' : null,
            buttonLabel: 'Görevlere Git',
            onPressed: onOpenTasks,
          ),
        ),
        SizedBox(
          width: 260,
          child: _ActionCard(
            icon: Icons.rate_review_rounded,
            title: 'Revizyon Kuyruğu',
            subtitle: '$correctionsCount kayıt aksiyon bekliyor',
            badgeText: '$correctionsCount',
            buttonLabel: 'Revizyonları Aç',
            onPressed: onOpenRevisions,
          ),
        ),
        SizedBox(
          width: 260,
          child: _ActionCard(
            icon: Icons.flag_circle_rounded,
            title: 'Alarm Takibi',
            subtitle: alertsCount == 0
                ? 'Şu an bayraklı iş görünmüyor'
                : '$alertsCount alarm yakın takip istiyor',
            badgeText: flaggedOnly ? 'Açık' : '$alertsCount',
            buttonLabel: flaggedOnly ? 'Filtreyi Kapat' : 'Kritikleri Filtrele',
            onPressed: onToggleRiskMode,
            highlight: flaggedOnly,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.badgeText,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? badgeText;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? AppPalette.danger : AppPalette.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight
              ? AppPalette.danger.withValues(alpha: 0.22)
              : AppPalette.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051830),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final TeamMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051830),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(metric.caption, style: const TextStyle(color: AppPalette.muted)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.flaggedOnly,
    required this.onFlaggedOnlyChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final bool flaggedOnly;
  final ValueChanged<bool> onFlaggedOnlyChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Çalışan / rol / durum ara...',
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
          FilterChip(
            selected: flaggedOnly,
            onSelected: onFlaggedOnlyChanged,
            label: const Text('Sadece kritik risk'),
            avatar: const Icon(Icons.flag_circle_rounded, size: 18),
            selectedColor: AppPalette.danger.withValues(alpha: 0.16),
            checkmarkColor: AppPalette.danger,
            labelStyle: TextStyle(
              color: flaggedOnly ? AppPalette.danger : AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Filtreleri Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({
    required this.members,
    required this.selectedMemberId,
    required this.onSelect,
  });

  final List<TeamMember> members;
  final String? selectedMemberId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ekip Kartları',
      subtitle: 'Skor, iş yükü ve risk seviyesine göre sıralanır',
      child: members.isEmpty
          ? const _EmptyState(
              title: 'Çalışan bulunamadı',
              message: 'Arama ve alarm filtresine uyan kişi görünmüyor.',
            )
          : Column(
              children: [
                for (final member in members)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MemberTile(
                      member: member,
                      selected: member.id == selectedMemberId,
                      onTap: () => onSelect(member.id),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final TeamMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.primarySoft : AppPalette.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials(member.name),
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
                          member.name,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.role,
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppPalette.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _BadgeChip(
                    label: member.status,
                    color: _statusColor(member.status),
                  ),
                  _BadgeChip(
                    label: member.riskLevel.label,
                    color: _riskColor(member.riskLevel),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InlineMetric(
                      label: 'Aktif',
                      value: '${member.activeTasks}',
                    ),
                  ),
                  Expanded(
                    child: _InlineMetric(
                      label: 'Tamamlanan',
                      value: '${member.completedTasks}',
                    ),
                  ),
                  Expanded(
                    child: _InlineMetric(
                      label: 'Skor',
                      value: '${member.performanceScore}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberDetailPanel extends StatelessWidget {
  const _MemberDetailPanel({
    required this.role,
    required this.member,
    required this.managerNoteController,
    required this.onSaveNote,
    required this.onOpenTasks,
    required this.onOpenRevisions,
  });

  final UserRole role;
  final TeamMember? member;
  final TextEditingController managerNoteController;
  final VoidCallback onSaveNote;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenRevisions;

  @override
  Widget build(BuildContext context) {
    final canManage = role != UserRole.employee;

    return _SectionCard(
      title: 'Çalışan Kartı',
      subtitle: canManage
          ? 'Görev ata, revizyon aç ve yönetici yorumu bırak'
          : 'Ekip içindeki konumun ve güncel risk görünümün',
      child: member == null
          ? const _EmptyState(
              title: 'Çalışan seçilmedi',
              message: 'Detay görmek için soldan bir ekip kartı seç.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppPalette.primarySoft,
                      child: Text(
                        _initials(member!.name),
                        style: const TextStyle(
                          color: AppPalette.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member!.name,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            member!.role,
                            style: const TextStyle(color: AppPalette.muted),
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
                    _BadgeChip(
                      label: member!.status,
                      color: _statusColor(member!.status),
                    ),
                    _BadgeChip(
                      label: member!.riskLevel.label,
                      color: _riskColor(member!.riskLevel),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SmallStatCard(
                      label: 'Aktif Görev',
                      value: '${member!.activeTasks}',
                    ),
                    _SmallStatCard(
                      label: 'Tamamlanan',
                      value: '${member!.completedTasks}',
                    ),
                    _SmallStatCard(
                      label: 'Performans',
                      value: '${member!.performanceScore}/100',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoBlock(title: 'Odak Notu', content: member!.focusNote),
                if (member!.riskLevel == MemberRiskLevel.high) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppPalette.danger.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppPalette.danger,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bu çalışan kritik seviyede. Önce revizyon kuyruğu ve geciken görevleri kontrol et.',
                            style: TextStyle(
                              color: AppPalette.text,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (member!.lastManagerNote != null) ...[
                  const SizedBox(height: 16),
                  _InfoBlock(
                    title: 'Son Yönetici Yorumu',
                    content: member!.lastManagerNote!,
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onOpenTasks,
                      icon: const Icon(Icons.assignment_turned_in_rounded),
                      label: Text(
                        role == UserRole.manager ? 'Görev Ata' : 'Görevlere Git',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenRevisions,
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text('Revizyonları Aç'),
                    ),
                  ],
                ),
                if (canManage) ...[
                  const SizedBox(height: 18),
                  TextField(
                    controller: managerNoteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Yönetici yorumu',
                      hintText:
                          'Performans, yönlendirme veya aksiyon notu bırak.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onSaveNote,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Yorumu Kaydet'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _QueuesPanel extends StatelessWidget {
  const _QueuesPanel({
    required this.corrections,
    required this.alerts,
  });

  final List<TeamCorrection> corrections;
  final List<TeamAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final correctionsPanel = _SectionCard(
          title: 'Bekleyen Düzeltmeler',
          subtitle: 'Revizyon veya yönetici kararı bekleyen kayıtlar',
          child: corrections.isEmpty
              ? const _EmptyState(
                  title: 'Kuyruk boş',
                  message: 'Bekleyen düzeltme görünmüyor.',
                )
              : Column(
                  children: [
                    for (final correction in corrections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QueueTile(
                          title: correction.title,
                          subtitle:
                              '${correction.owner} • ${correction.ageLabel}',
                          detail: correction.summary,
                          color: AppPalette.warning,
                        ),
                      ),
                  ],
                ),
        );
        final alertsPanel = _SectionCard(
          title: 'Alarm Takibi',
          subtitle: 'Bayraklı görevler ve risk seviyesi yüksek sinyaller',
          child: alerts.isEmpty
              ? const _EmptyState(
                  title: 'Alarm yok',
                  message: 'Şu an yakın takip isteyen kayıt görünmüyor.',
                )
              : Column(
                  children: [
                    for (final alert in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QueueTile(
                          title: alert.title,
                          subtitle: alert.project,
                          detail: alert.detail,
                          color: _riskColor(alert.riskLevel),
                        ),
                      ),
                  ],
                ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: correctionsPanel),
              const SizedBox(width: 16),
              Expanded(child: alertsPanel),
            ],
          );
        }

        return Column(
          children: [
            correctionsPanel,
            const SizedBox(height: 16),
            alertsPanel,
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051830),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
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
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppPalette.primary)),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
  'Aktif' => AppPalette.success,
  'Sahada' => AppPalette.primary,
  'İzinde' => AppPalette.warning,
  _ => AppPalette.muted,
};

Color _riskColor(MemberRiskLevel level) => switch (level) {
  MemberRiskLevel.low => AppPalette.success,
  MemberRiskLevel.medium => AppPalette.warning,
  MemberRiskLevel.high => AppPalette.danger,
};

String _initials(String name) {
  final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
