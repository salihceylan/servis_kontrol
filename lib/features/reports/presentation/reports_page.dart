import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/reports/application/report_controller.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.user});

  final AppUser user;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final ReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportController(user: widget.user);
  }

  @override
  void dispose() {
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
            const _PageHeader(
              title: 'Raporlar',
              subtitle:
                  'Filtrele, rapor oluştur, hazırlık durumunu izle ve çıktıyı indir.',
            ),
            const SizedBox(height: 18),
            _FilterBar(
              teamFilter: _controller.teamFilter,
              userFilter: _controller.userFilter,
              typeFilter: _controller.typeFilter,
              teamOptions: _controller.teamOptions,
              userOptions: _controller.userOptions,
              onTeamChanged: _controller.updateTeamFilter,
              onUserChanged: _controller.updateUserFilter,
              onTypeChanged: _controller.updateTypeFilter,
              onCreateReport: () => _openCreateReportDialog(context),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.metrics)
                  SizedBox(width: 240, child: _MetricCard(metric: metric)),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final distribution = _SectionCard(
                  title: 'Durum Dağılımı',
                  subtitle: 'Toplam görev ve süreç adetleri',
                  child: _StatusTable(rows: _controller.statusCounts),
                );
                final activities = _SectionCard(
                  title: 'Son Aktiviteler',
                  subtitle: 'Son 20 rapor ve paylaşım hareketi',
                  child: _ActivityList(activities: _controller.activities),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: distribution),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: activities),
                    ],
                  );
                }

                return Column(
                  children: [
                    distribution,
                    const SizedBox(height: 16),
                    activities,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Rapor Çalıştırmaları',
              subtitle: 'Hazırlanıyor, indir ve e-posta ile gönder akışı',
              child: _ReportRunsList(
                runs: _controller.runs,
                canEmail: _controller.canEmail,
                onDownload: (run) => _showFeedback(
                  'Rapor hazır: ${run.title} (${run.format.label}) indiriliyor.',
                ),
                onEmail: (run) => _showFeedback(
                  'Rapor e-posta ile gönderildi: ${run.title}',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCreateReportDialog(BuildContext context) async {
    String scope = _controller.teamFilter ?? _controller.teamOptions.first;
    ReportFormat format = ReportFormat.pdf;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'Yeni Rapor Oluştur',
                style: TextStyle(
                  color: AppPalette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kapsam ve format seç. Hazırlık bittiğinde rapor hazır listesine düşecek.',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: scope,
                      items: [
                        for (final option in _controller.teamOptions)
                          DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => scope = value);
                      },
                      decoration: const InputDecoration(labelText: 'Kapsam'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReportFormat>(
                      initialValue: format,
                      items: [
                        for (final option in ReportFormat.values)
                          DropdownMenuItem<ReportFormat>(
                            value: option,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => format = value);
                      },
                      decoration: const InputDecoration(labelText: 'Format'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: _controller.creating
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _controller.createReport(
                            scope: scope,
                            format: format,
                          );
                          if (!mounted) {
                            return;
                          }
                          _showFeedback('Rapor hazırlandı: ${format.label}');
                        },
                  child: Text(
                    _controller.creating ? 'Hazırlanıyor...' : 'Rapor Oluştur',
                  ),
                ),
              ],
            );
          },
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
          style: const TextStyle(
            color: AppPalette.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.teamFilter,
    required this.userFilter,
    required this.typeFilter,
    required this.teamOptions,
    required this.userOptions,
    required this.onTeamChanged,
    required this.onUserChanged,
    required this.onTypeChanged,
    required this.onCreateReport,
  });

  final String? teamFilter;
  final String? userFilter;
  final ReportType typeFilter;
  final List<String> teamOptions;
  final List<String> userOptions;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<ReportType> onTypeChanged;
  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DropdownField<String?>(
            width: 180,
            label: 'Ekip',
            value: teamFilter,
            items: [null, ...teamOptions],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: onTeamChanged,
          ),
          _DropdownField<String?>(
            width: 180,
            label: 'Kullanıcı',
            value: userFilter,
            items: [null, ...userOptions],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: onUserChanged,
          ),
          _DropdownField<ReportType>(
            width: 180,
            label: 'Tür',
            value: typeFilter,
            items: ReportType.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => onTypeChanged(value!),
          ),
          FilledButton.icon(
            onPressed: onCreateReport,
            icon: const Icon(Icons.post_add_rounded),
            label: const Text('Yeni Rapor Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final double width;
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, fillColor: AppPalette.surfaceMuted),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: const TextStyle(color: AppPalette.muted, fontWeight: FontWeight.w700),
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
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
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

class _StatusTable extends StatelessWidget {
  const _StatusTable({required this.rows});

  final List<ReportStatusCount> rows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.border),
        ),
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppPalette.muted,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w500,
          ),
          columns: const [
            DataColumn(label: Text('Durum')),
            DataColumn(label: Text('Adet')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(Text(row.label)),
                  DataCell(
                    Text(
                      '${row.count}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<ReportActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppPalette.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppPalette.primary,
                      size: 18,
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
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.subtitle,
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportRunsList extends StatelessWidget {
  const _ReportRunsList({
    required this.runs,
    required this.canEmail,
    required this.onDownload,
    required this.onEmail,
  });

  final List<ReportRun> runs;
  final bool canEmail;
  final ValueChanged<ReportRun> onDownload;
  final ValueChanged<ReportRun> onEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final run in runs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                children: [
                  _RunBadge(status: run.status, format: run.format),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          run.title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${run.scope} • ${run.createdAtLabel}',
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: run.status == ReportRunStatus.ready
                        ? () => onDownload(run)
                        : null,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('İndir'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: run.status == ReportRunStatus.ready && canEmail
                        ? () => onEmail(run)
                        : null,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('E-posta ile Gönder'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RunBadge extends StatelessWidget {
  const _RunBadge({
    required this.status,
    required this.format,
  });

  final ReportRunStatus status;
  final ReportFormat format;

  @override
  Widget build(BuildContext context) {
    final color = status == ReportRunStatus.ready
        ? AppPalette.success
        : AppPalette.warning;
    final label = status == ReportRunStatus.ready
        ? '${format.label} Hazır'
        : 'Hazırlanıyor';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
