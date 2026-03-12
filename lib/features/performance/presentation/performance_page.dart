import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/performance/application/performance_controller.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key, required this.user});

  final AppUser user;

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  late final PerformanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceController(user: widget.user);
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
        final snapshot = _controller.snapshot;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(
              title: 'Performans',
              subtitle:
                  'Özet kartlar, trend grafiği ve görev bazlı kalite görünümü.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final range in PerformanceRange.values)
                      ChoiceChip(
                        label: Text(range.label),
                        selected: _controller.range == range,
                        onSelected: (_) => _controller.updateRange(range),
                      ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showFeedback(context, 'CSV export hazırlandı.'),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('CSV İndir'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in snapshot.metrics)
                  SizedBox(width: 250, child: _MetricCard(metric: metric)),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final trend = _SectionCard(
                  title: 'Trend Grafiği',
                  subtitle: 'Son 6 ay trendi ve hedef çizgisi',
                  child: _TrendChart(points: snapshot.trendPoints),
                );
                final table = _SectionCard(
                  title: 'Görev Bazlı Tablo',
                  subtitle: 'Revizyon ve kalite puanı ile biten işler',
                  child: _PerformanceTable(rows: snapshot.rows),
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: trend),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: table),
                    ],
                  );
                }

                return Column(
                  children: [
                    trend,
                    const SizedBox(height: 16),
                    table,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showFeedback(BuildContext context, String message) {
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final PerformanceMetric metric;

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

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<PerformanceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxValue = points
            .expand((point) => [point.score, point.target])
            .fold<double>(0, (current, value) => value > current ? value : current) +
        8;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            point.score.toStringAsFixed(0),
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 34,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: AppPalette.surfaceMuted,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Positioned(
                                  bottom: (point.target / maxValue) * 180,
                                  child: Container(
                                    width: 42,
                                    height: 2,
                                    color: AppPalette.warning,
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: (point.score / maxValue) * 180,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppPalette.primary,
                                        AppPalette.sidebarSoft,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          point.label,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            _LegendDot(color: AppPalette.primary, label: 'Gerçek skor'),
            SizedBox(width: 16),
            _LegendDot(color: AppPalette.warning, label: 'Hedef çizgisi'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PerformanceTable extends StatelessWidget {
  const _PerformanceTable({required this.rows});

  final List<TaskPerformanceRow> rows;

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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
              DataColumn(label: Text('Görev')),
              DataColumn(label: Text('Sorumlu')),
              DataColumn(label: Text('Kapanış')),
              DataColumn(label: Text('Revizyon')),
              DataColumn(label: Text('Kalite')),
              DataColumn(label: Text('Süre')),
              DataColumn(label: Text('Durum')),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        row.taskTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(row.owner)),
                    DataCell(Text(row.completedAt)),
                    DataCell(Text('${row.revisionCount}')),
                    DataCell(_ScoreBadge(score: row.qualityScore)),
                    DataCell(Text(row.durationLabel)),
                    DataCell(_StatusBadge(label: row.statusLabel)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? AppPalette.success
        : score >= 75
        ? AppPalette.primary
        : score >= 70
        ? AppPalette.warning
        : AppPalette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score / 100',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Güçlü' => AppPalette.success,
      'Güvenli' => AppPalette.primary,
      'Dengeli' => AppPalette.warning,
      'İzle' => AppPalette.danger,
      'Dikkat' => AppPalette.warning,
      'Kritik' => AppPalette.danger,
      _ => AppPalette.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
