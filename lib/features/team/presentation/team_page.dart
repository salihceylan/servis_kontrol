import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

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
  final _managerNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TeamController(user: widget.user, apiClient: widget.apiClient);
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
        if (_controller.isLoading) {
          return const StatePanel.loading(
            title: 'Ekip verileri yükleniyor',
            message: 'Çalışan kartları, risk sinyalleri ve düzeltme kuyrukları alınıyor.',
          );
        }
        if (_controller.errorMessage != null && !_controller.hasData) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }
        if (!_controller.hasData) {
          return StatePanel.empty(
            title: 'Ekip kaydı bulunamadı',
            message: 'Bu şirket için ekip verisi henüz oluşmamış.',
            onRetry: _controller.load,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              role: widget.user.role,
              canToggleManagerMode: _controller.canToggleManagerMode,
              managerMode: _controller.managerMode,
              onManagerModeChanged: _controller.toggleManagerMode,
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
              controller: _controller,
              searchController: _searchController,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final members = _MembersPanel(
                  controller: _controller,
                );
                final detail = _DetailPanel(
                  controller: _controller,
                  role: widget.user.role,
                  managerNoteController: _managerNoteController,
                  onSaveNote: _saveManagerNote,
                  onOpenTasks: widget.onOpenTasks,
                  onOpenRevisions: widget.onOpenRevisions,
                );
                final queues = _QueuesPanel(controller: _controller);

                if (!wide) {
                  return Column(
                    children: [
                      members,
                      const SizedBox(height: 16),
                      detail,
                      const SizedBox(height: 16),
                      queues,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: members),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          detail,
                          const SizedBox(height: 16),
                          queues,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveManagerNote() async {
    final note = _managerNoteController.text.trim();
    if (note.isEmpty) {
      return;
    }
    final success = await _controller.addManagerNote(note);
    if (success) {
      _managerNoteController.clear();
    }
    _showFeedback(
      success
          ? 'Yönetici notu kaydedildi.'
          : (_controller.errorMessage ?? 'Yönetici notu kaydedilemedi.'),
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

class _Header extends StatelessWidget {
  const _Header({
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
        'Çalışan kartları, düzeltme kuyruğu ve riskli işler burada.',
      ),
      UserRole.manager => (
        'Yönetici Modu',
        'Görev dağıtımı, revizyon onayı ve alarm takibi tek panelde.',
      ),
    };

    return Row(
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
        if (canToggleManagerMode)
          Switch.adaptive(
            value: managerMode,
            onChanged: onManagerModeChanged,
          ),
      ],
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
    required this.controller,
    required this.searchController,
  });

  final TeamController controller;
  final TextEditingController searchController;

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
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Çalışan, rol veya durum ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          FilterChip(
            selected: controller.flaggedOnly,
            onSelected: controller.toggleFlaggedOnly,
            label: const Text('Sadece kritik risk'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              searchController.clear();
              controller.toggleFlaggedOnly(false);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Filtreleri Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({required this.controller});

  final TeamController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ekip Kartları',
      subtitle: 'Canlı çalışan, iş yükü ve risk görünümü',
      child: Column(
        children: [
          for (final member in controller.members)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: member.id == controller.selectedMember?.id
                    ? AppPalette.primarySoft
                    : AppPalette.background,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => controller.selectMember(member.id),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          member.role,
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _BadgeChip(label: member.status, color: _statusColor(member.status)),
                            _BadgeChip(label: member.riskLevel.label, color: _riskColor(member.riskLevel)),
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
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.controller,
    required this.role,
    required this.managerNoteController,
    required this.onSaveNote,
    required this.onOpenTasks,
    required this.onOpenRevisions,
  });

  final TeamController controller;
  final UserRole role;
  final TextEditingController managerNoteController;
  final Future<void> Function() onSaveNote;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenRevisions;

  @override
  Widget build(BuildContext context) {
    final member = controller.selectedMember;
    if (member == null) {
      return const StatePanel.empty(
        title: 'Çalışan detayı yok',
        message: 'Soldan bir ekip kartı seçildiğinde detay burada açılır.',
      );
    }

    return _SectionCard(
      title: 'Çalışan Kartı',
      subtitle: 'Görev ve revizyon aksiyonları bu karttan izlenir.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.name,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(member.role, style: const TextStyle(color: AppPalette.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BadgeChip(label: member.status, color: _statusColor(member.status)),
              _BadgeChip(label: member.riskLevel.label, color: _riskColor(member.riskLevel)),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniStat(label: 'Aktif Görev', value: '${member.activeTasks}'),
              _MiniStat(label: 'Tamamlanan', value: '${member.completedTasks}'),
              _MiniStat(label: 'Performans', value: '${member.performanceScore}/100'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            member.focusNote,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          if (member.lastManagerNote != null) ...[
            const SizedBox(height: 16),
            Text(
              'Son yönetici notu',
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              member.lastManagerNote!,
              style: const TextStyle(color: AppPalette.muted, height: 1.5),
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
                label: Text(role == UserRole.manager ? 'Görev Ata' : 'Görevlere Git'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenRevisions,
                icon: const Icon(Icons.rate_review_rounded),
                label: const Text('Revizyonları Aç'),
              ),
            ],
          ),
          if (role != UserRole.employee) ...[
            const SizedBox(height: 18),
            TextField(
              controller: managerNoteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Yönetici notu',
                hintText: 'Çalışan için yönlendirme veya takip notu bırak.',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.isSaving ? null : onSaveNote,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Notu Kaydet'),
            ),
          ],
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              controller.errorMessage!,
              style: const TextStyle(
                color: AppPalette.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueuesPanel extends StatelessWidget {
  const _QueuesPanel({required this.controller});

  final TeamController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final corrections = _SectionCard(
          title: 'Bekleyen Düzeltmeler',
          subtitle: 'Aksiyon bekleyen revizyon veya yönetici kararları',
          child: Column(
            children: [
              if (controller.corrections.isEmpty)
                const Text('Bekleyen düzeltme görünmüyor.')
              else
                for (final correction in controller.corrections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QueueTile(
                      title: correction.title,
                      subtitle: '${correction.owner} • ${correction.ageLabel}',
                      detail: correction.summary,
                      color: AppPalette.warning,
                    ),
                  ),
            ],
          ),
        );
        final alerts = _SectionCard(
          title: 'Alarm Takibi',
          subtitle: 'Bayraklı görevler ve yüksek risk sinyalleri',
          child: Column(
            children: [
              if (controller.alerts.isEmpty)
                const Text('Alarm kaydı görünmüyor.')
              else
                for (final alert in controller.alerts)
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

        if (!wide) {
          return Column(
            children: [
              corrections,
              const SizedBox(height: 16),
              alerts,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: corrections),
            const SizedBox(width: 16),
            Expanded(child: alerts),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
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
        color: AppPalette.surfaceMuted,
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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppPalette.primary)),
          const SizedBox(height: 6),
          Text(detail, style: const TextStyle(color: AppPalette.muted)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

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
