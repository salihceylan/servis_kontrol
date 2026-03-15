import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/reports/application/report_controller.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.user, required this.apiClient});

  final AppUser user;
  final ApiClient apiClient;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final ReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportController(
      user: widget.user,
      apiClient: widget.apiClient,
    );
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
        if (_controller.isLoading) {
          return const StatePanel.loading(
            title: 'Raporlar yükleniyor',
            message:
                'Durum dağılımı, rapor çalıştırmaları ve son aktiviteler alınıyor.',
          );
        }
        if (_controller.errorMessage != null && !_controller.hasData) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }
        if (!_controller.hasData) {
          return const StatePanel.empty(
            title: 'Rapor kaydı bulunamadı',
            message: 'Bu şirket için henüz rapor çalıştırması oluşmamış.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              title: 'Raporlar',
              subtitle:
                  'Filtrele, yeni rapor üret ve hazır çıktıları indir veya e-posta ile gönder.',
            ),
            const SizedBox(height: 18),
            _FilterBar(controller: _controller, onCreateReport: _createReport),
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
                  child: Column(
                    children: [
                      for (final row in _controller.statusCounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.label,
                                  style: const TextStyle(
                                    color: AppPalette.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${row.count}',
                                style: const TextStyle(
                                  color: AppPalette.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
                final activities = _SectionCard(
                  title: 'Son Aktiviteler',
                  subtitle: 'Rapor üretim ve paylaşım hareketleri',
                  child: Column(
                    children: [
                      for (final activity in _controller.activities)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.title,
                                  style: const TextStyle(
                                    color: AppPalette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  activity.subtitle,
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      distribution,
                      const SizedBox(height: 16),
                      activities,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: distribution),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: activities),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Rapor Çalıştırmaları',
              subtitle: 'Hazırlanan raporlar ve çıktı aksiyonları',
              child: Column(
                children: [
                  for (final run in _controller.runs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
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
                                    style: const TextStyle(
                                      color: AppPalette.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: run.status == ReportRunStatus.ready
                                  ? () => _feedback(
                                      'Rapor indirme akışı backend dosya servisine bağlanacak.',
                                    )
                                  : null,
                              icon: const Icon(Icons.file_download_outlined),
                              label: const Text('İndir'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createReport() async {
    final scope =
        _controller.teamFilter ??
        (_controller.teamOptions.isEmpty
            ? 'Genel'
            : _controller.teamOptions.first);
    final success = await _controller.createReport(
      scope: scope,
      format: ReportFormat.pdf,
    );
    _feedback(
      success
          ? 'Rapor oluşturma talebi kaydedildi.'
          : (_controller.errorMessage ?? 'Rapor oluşturulamadı.'),
    );
  }

  void _feedback(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
  const _FilterBar({required this.controller, required this.onCreateReport});

  final ReportController controller;
  final Future<void> Function() onCreateReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Dropdown<String?>(
            label: 'Ekip',
            value: controller.teamFilter,
            items: [null, ...controller.teamOptions],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateTeamFilter,
          ),
          _Dropdown<String?>(
            label: 'Kullanıcı',
            value: controller.userFilter,
            items: [null, ...controller.userOptions],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateUserFilter,
          ),
          _Dropdown<ReportType>(
            label: 'Tür',
            value: controller.typeFilter,
            items: ReportType.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => controller.updateTypeFilter(value!),
          ),
          FilledButton.icon(
            onPressed: controller.creating ? null : onCreateReport,
            icon: const Icon(Icons.post_add_rounded),
            label: Text(
              controller.creating ? 'Hazırlanıyor...' : 'Yeni Rapor Oluştur',
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
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

class _RunBadge extends StatelessWidget {
  const _RunBadge({required this.status, required this.format});

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
