import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/application/revision_controller.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

class RevisionPage extends StatefulWidget {
  const RevisionPage({super.key, required this.user});

  final AppUser user;

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
    _controller = RevisionController(user: widget.user);
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
        final selected = _controller.selectedItem;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RevisionHeader(),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.metrics)
                  SizedBox(
                    width: 250,
                    child: _RevisionMetricCard(metric: metric),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _RevisionSearch(searchController: _searchController),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final queues = _RevisionQueues(
                  pendingItems: _controller.pendingItems,
                  revisionItems: _controller.revisionItems,
                  completedItems: _controller.completedItems,
                  selectedId: selected?.id,
                  onSelect: _controller.selectItem,
                );
                final detail = _RevisionDetailPanel(
                  userRole: widget.user.role,
                  item: selected,
                  employeeUpdateController: _employeeUpdateController,
                  onApprove: () {
                    _controller.approveSelected();
                    _showFeedback('Revizyon onaylandı.');
                  },
                  onRequestRevision: () async {
                    final reason = await _askRevisionReason(context);
                    if (reason != null && reason.trim().isNotEmpty) {
                      _controller.requestRevision(reason);
                      _showFeedback('Revizyon talebi gönderildi.');
                    }
                  },
                  onEmployeeUpdate: () {
                    final note = _employeeUpdateController.text.trim();
                    if (note.isEmpty) {
                      return;
                    }
                    _controller.markEmployeeUpdated(note);
                    _employeeUpdateController.clear();
                    _showFeedback('Güncelleme incelemeye gönderildi.');
                  },
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: queues),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: detail),
                    ],
                  );
                }

                return Column(
                  children: [
                    queues,
                    const SizedBox(height: 16),
                    detail,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askRevisionReason(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Revizyon Talep Et'),
            content: SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Sebep / açıklama',
                  hintText: 'Revizyon nedeni zorunludur.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(reason);
                },
                child: const Text('Revizyon İste'),
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

class _RevisionHeader extends StatelessWidget {
  const _RevisionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revizyonlar',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'İnceleme bekleyen işleri onayla veya açıklama zorunlu revizyon iste. Revizyon sayısı eşik aşarsa erken uyarı tetiklensin.',
          style: TextStyle(color: AppPalette.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _RevisionMetricCard extends StatelessWidget {
  const _RevisionMetricCard({required this.metric});

  final RevisionMetric metric;

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
          Text(
            metric.caption,
            style: const TextStyle(color: AppPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _RevisionSearch extends StatelessWidget {
  const _RevisionSearch({required this.searchController});

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
      child: SizedBox(
        width: 320,
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Görev / proje / kişi ara...',
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
    );
  }
}

class _RevisionQueues extends StatelessWidget {
  const _RevisionQueues({
    required this.pendingItems,
    required this.revisionItems,
    required this.completedItems,
    required this.selectedId,
    required this.onSelect,
  });

  final List<RevisionItem> pendingItems;
  final List<RevisionItem> revisionItems;
  final List<RevisionItem> completedItems;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QueueCard(
                title: 'İnceleme Bekleyen',
                subtitle: 'Onay veya revizyon kararı bekleyenler',
                items: pendingItems,
                selectedId: selectedId,
                onSelect: onSelect,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QueueCard(
                title: 'Revizyonda',
                subtitle: 'Çalışana açıklama ile geri dönenler',
                items: revisionItems,
                selectedId: selectedId,
                onSelect: onSelect,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _QueueCard(
          title: 'Tamamlanan',
          subtitle: 'Performans verisi üretilen onaylı kayıtlar',
          items: completedItems,
          selectedId: selectedId,
          onSelect: onSelect,
          compact: true,
        ),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<RevisionItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final bool compact;

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
          if (items.isEmpty)
            const _EmptyState(
              title: 'Kayıt yok',
              message: 'Bu kuyruğa düşen revizyon kaydı bulunmuyor.',
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RevisionTile(
                  item: item,
                  selected: item.id == selectedId,
                  compact: compact,
                  onTap: () => onSelect(item.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _RevisionTile extends StatelessWidget {
  const _RevisionTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final RevisionItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.primarySoft : AppPalette.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (item.earlyWarning)
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppPalette.danger,
                      size: 18,
                    ),
                ],
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
                  _BadgeChip(
                    label: item.stage.label,
                    color: _stageColor(item.stage),
                  ),
                  _BadgeChip(
                    label: '${item.revisionCount} revizyon',
                    color: item.earlyWarning
                        ? AppPalette.danger
                        : AppPalette.warning,
                  ),
                  if (!compact)
                    _BadgeChip(
                      label: item.category,
                      color: const Color(0xFF7A7AE6),
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

class _RevisionDetailPanel extends StatelessWidget {
  const _RevisionDetailPanel({
    required this.userRole,
    required this.item,
    required this.employeeUpdateController,
    required this.onApprove,
    required this.onRequestRevision,
    required this.onEmployeeUpdate,
  });

  final UserRole userRole;
  final RevisionItem? item;
  final TextEditingController employeeUpdateController;
  final VoidCallback onApprove;
  final VoidCallback onRequestRevision;
  final VoidCallback onEmployeeUpdate;

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
      child: item == null
          ? const _EmptyState(
              title: 'Revizyon Detayı',
              message: 'Detay görmek için soldaki listeden bir kayıt seç.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Revizyon Detayı',
                  subtitle:
                      'Onayla, revizyon iste veya çalışan güncellemesini tekrar incelemeye gönder',
                ),
                const SizedBox(height: 18),
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
                    _BadgeChip(
                      label: item!.stage.label,
                      color: _stageColor(item!.stage),
                    ),
                    _BadgeChip(
                      label: '${item!.revisionCount} revizyon',
                      color: item!.earlyWarning
                          ? AppPalette.danger
                          : AppPalette.warning,
                    ),
                    _BadgeChip(
                      label: item!.category,
                      color: const Color(0xFF7A7AE6),
                    ),
                    if (item!.performanceReady)
                      const _BadgeChip(
                        label: 'Performans Verisi Üretildi',
                        color: AppPalette.success,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _InfoRow(label: 'Proje', value: item!.project),
                _InfoRow(label: 'Sorumlu', value: item!.owner),
                _InfoRow(
                  label: 'Güncelleme',
                  value: _formatDateTime(item!.updatedAt),
                ),
                const SizedBox(height: 14),
                Text(
                  item!.summary,
                  style: const TextStyle(color: AppPalette.muted, height: 1.6),
                ),
                if (item!.revisionReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item!.earlyWarning
                            ? AppPalette.danger.withValues(alpha: 0.18)
                            : AppPalette.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Revizyon Sebebi',
                              style: TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item!.earlyWarning) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppPalette.danger,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item!.revisionReason!,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
                        decoration: InputDecoration(
                          labelText: 'Yapılan güncelleme',
                          hintText:
                              'Sebep + açıklama ile çalışanın yaptığı güncelleme notunu gir.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onEmployeeUpdate,
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
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Onayla'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onRequestRevision,
                        icon: const Icon(Icons.reply_rounded),
                        label: const Text('Revizyon İste'),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                const _SectionHeader(
                  title: 'Revizyon Geçmişi',
                  subtitle:
                      'Onay, revizyon isteme, çalışan bildirimi ve erken uyarı kayıtları',
                ),
                const SizedBox(height: 14),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  history.title,
                                  style: const TextStyle(
                                    color: AppPalette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDateTime(history.timestamp),
                                style: const TextStyle(
                                  color: AppPalette.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            history.detail,
                            style: const TextStyle(
                              color: AppPalette.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            history.actor,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

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
          Text(message, style: const TextStyle(color: AppPalette.muted)),
        ],
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
