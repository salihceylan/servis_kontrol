import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/application/revision_controller.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

class RevisionPage extends StatefulWidget {
  const RevisionPage({
    super.key,
    required this.user,
    required this.apiClient,
  });

  final AppUser user;
  final ApiClient apiClient;

  @override
  State<RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<RevisionPage> {
  late final RevisionController _controller;
  final _searchController = TextEditingController();
  final _employeeUpdateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RevisionController(
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
    _employeeUpdateController.dispose();
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
            title: 'Revizyon akışı yükleniyor',
            message: 'Onay ve geri bildirim kayıtları sunucudan alınıyor.',
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
            title: 'Revizyon kaydı bulunamadı',
            message:
                'Bu kullanıcı veya şirket için aktif revizyon kaydı görünmüyor.',
            onRetry: _controller.load,
          );
        }

        final selected = _controller.selectedItem;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              title: 'Revizyonlar',
              subtitle:
                  'Gerçek onay kayıtlarını izle, revizyon iste ve çalışan güncellemesini tekrar incelemeye al.',
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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Görev, proje veya kişi ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final queuePanel = _QueuePanel(
                  controller: _controller,
                  selectedId: selected?.id,
                );
                final detailPanel = _DetailPanel(
                  controller: _controller,
                  userRole: widget.user.role,
                  item: selected,
                  employeeUpdateController: _employeeUpdateController,
                  onApprove: _approve,
                  onRequestRevision: _requestRevision,
                  onEmployeeUpdate: _sendEmployeeUpdate,
                );
                if (!wide) {
                  return Column(
                    children: [
                      queuePanel,
                      const SizedBox(height: 16),
                      detailPanel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: queuePanel),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: detailPanel),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _approve() async {
    final success = await _controller.approveSelected();
    _showFeedback(
      success
          ? 'Revizyon onaylandı.'
          : (_controller.errorMessage ?? 'Revizyon onaylanamadı.'),
    );
  }

  Future<void> _requestRevision() async {
    final reason = await _askReason(context);
    if (reason == null || reason.trim().isEmpty) {
      return;
    }
    final success = await _controller.requestRevision(reason);
    _showFeedback(
      success
          ? 'Revizyon talebi gönderildi.'
          : (_controller.errorMessage ?? 'Revizyon talebi gönderilemedi.'),
    );
  }

  Future<void> _sendEmployeeUpdate() async {
    final note = _employeeUpdateController.text.trim();
    if (note.isEmpty) {
      return;
    }
    final success = await _controller.markEmployeeUpdated(note);
    if (success) {
      _employeeUpdateController.clear();
    }
    _showFeedback(
      success
          ? 'Güncelleme incelemeye gönderildi.'
          : (_controller.errorMessage ?? 'Güncelleme kaydedilemedi.'),
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Revizyon Talep Et'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Sebep',
                hintText: 'Geri gönderme nedenini yaz.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Gönder'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
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
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final RevisionMetric metric;

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
          Text(
            metric.caption,
            style: const TextStyle(color: AppPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({
    required this.controller,
    required this.selectedId,
  });

  final RevisionController controller;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Revizyon Kuyruğu',
      subtitle: 'Bekleyen, revizyonda ve tamamlanan kayıtlar',
      child: Column(
        children: [
          for (final group in [
            ('İnceleme Bekleyen', controller.pendingItems),
            ('Revizyonda', controller.revisionItems),
            ('Tamamlanan', controller.completedItems),
          ]) ...[
            _SubsectionTitle(title: group.$1),
            const SizedBox(height: 10),
            if (group.$2.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Bu kuyruğa düşen kayıt yok.',
                  style: TextStyle(color: AppPalette.muted),
                ),
              )
            else
              for (final item in group.$2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: item.id == selectedId
                        ? AppPalette.primarySoft
                        : AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => controller.selectItem(item.id),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item.project} • ${item.owner}',
                              style: const TextStyle(color: AppPalette.muted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _BadgeChip(label: item.stage.label, color: _stageColor(item.stage)),
                                _BadgeChip(
                                  label: '${item.revisionCount} revizyon',
                                  color: item.earlyWarning
                                      ? AppPalette.danger
                                      : AppPalette.warning,
                                ),
                                _BadgeChip(label: item.category, color: const Color(0xFF7A7AE6)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.controller,
    required this.userRole,
    required this.item,
    required this.employeeUpdateController,
    required this.onApprove,
    required this.onRequestRevision,
    required this.onEmployeeUpdate,
  });

  final RevisionController controller;
  final UserRole userRole;
  final RevisionItem? item;
  final TextEditingController employeeUpdateController;
  final Future<void> Function() onApprove;
  final Future<void> Function() onRequestRevision;
  final Future<void> Function() onEmployeeUpdate;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const StatePanel.empty(
        title: 'Revizyon detayı yok',
        message: 'Listeden bir kayıt seçildiğinde detay burada açılır.',
      );
    }

    return _SectionCard(
      title: 'Revizyon Detayı',
      subtitle: 'Onay, geri gönderme ve çalışan yanıtı akışı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item!.title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BadgeChip(label: item!.stage.label, color: _stageColor(item!.stage)),
              _BadgeChip(
                label: '${item!.revisionCount} revizyon',
                color: item!.earlyWarning ? AppPalette.danger : AppPalette.warning,
              ),
              _BadgeChip(label: item!.category, color: const Color(0xFF7A7AE6)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item!.summary,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          if (item!.revisionReason != null) ...[
            const SizedBox(height: 16),
            Text(
              'Son revizyon nedeni',
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item!.revisionReason!,
              style: const TextStyle(color: AppPalette.muted, height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          if (userRole == UserRole.employee)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: employeeUpdateController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Yapılan güncelleme',
                    hintText: 'Düzeltmeyi ve açıklamayı yaz.',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : onEmployeeUpdate,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Güncellemeyi Gönder'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Onayla'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isSaving ? null : onRequestRevision,
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('Revizyon İste'),
                ),
              ],
            ),
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
          const SizedBox(height: 18),
          const _SubsectionTitle(title: 'Revizyon Geçmişi'),
          const SizedBox(height: 10),
          for (final history in item!.histories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
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
                      history.title,
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      history.detail,
                      style: const TextStyle(color: AppPalette.muted, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${history.actor} • ${_formatDateTime(history.timestamp)}',
                      style: const TextStyle(
                        color: AppPalette.primary,
                        fontWeight: FontWeight.w700,
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
            color: AppPalette.shadow,
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

class _SubsectionTitle extends StatelessWidget {
  const _SubsectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppPalette.text,
        fontWeight: FontWeight.w800,
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _stageColor(RevisionStage stage) => switch (stage) {
  RevisionStage.pendingReview => const Color(0xFF7A7AE6),
  RevisionStage.inRevision => AppPalette.warning,
  RevisionStage.completed => AppPalette.success,
};

String _formatDate(DateTime value) {
  const months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]}';
}

String _formatDateTime(DateTime value) {
  return '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
