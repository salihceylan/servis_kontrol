import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/dashboard/application/dashboard_controller.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(apiClient: widget.apiClient);
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
            title: 'Panel yükleniyor',
            message: 'Operasyon özeti ve KPI kartları sunucudan alınıyor.',
          );
        }
        if (_controller.errorMessage != null) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }

        final snapshot = _controller.snapshot;
        if (snapshot == null) {
          return const StatePanel.empty(
            title: 'Panel verisi bulunamadı',
            message: 'Bu kullanıcı için dashboard snapshot kaydı yok.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkflowHeroBanner(snapshot: snapshot),
            const SizedBox(height: 18),
            _PageHeader(title: snapshot.title, subtitle: snapshot.subtitle),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final metric in snapshot.summaryCards)
                      SizedBox(
                        width: wide ? 252 : double.infinity,
                        child: _MetricCard(metric: metric),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _KpiPanel(metrics: snapshot.kpiCards)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _NotificationPanel(
                          notifications: snapshot.notifications,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _KpiPanel(metrics: snapshot.kpiCards),
                    const SizedBox(height: 16),
                    _NotificationPanel(notifications: snapshot.notifications),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                if (wide) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _FocusPanel(items: snapshot.focusItems),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _ProjectPanel(projects: snapshot.projects),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _AutomationPanel(
                              automations: snapshot.automations,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _ActivityFeedPanel(
                              items: snapshot.activityFeed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _WorkloadPanel(rows: snapshot.workloadRows),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _RequestFormsPanel(
                              forms: snapshot.requestForms,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _FocusPanel(items: snapshot.focusItems),
                    const SizedBox(height: 16),
                    _ProjectPanel(projects: snapshot.projects),
                    const SizedBox(height: 16),
                    _AutomationPanel(automations: snapshot.automations),
                    const SizedBox(height: 16),
                    _ActivityFeedPanel(items: snapshot.activityFeed),
                    const SizedBox(height: 16),
                    _WorkloadPanel(rows: snapshot.workloadRows),
                    const SizedBox(height: 16),
                    _RequestFormsPanel(forms: snapshot.requestForms),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _WorkflowHeroBanner extends StatelessWidget {
  const _WorkflowHeroBanner({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.sidebar, AppPalette.sidebarSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.heroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            snapshot.heroMessage,
            style: const TextStyle(color: Color(0xC8FFFFFF), height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              snapshot.heroHighlight,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppPalette.muted)),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

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
      child: child,
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppPalette.muted)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: SizedBox(
        height: 182,
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -18,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: metric.color.withValues(alpha: 0.14),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(metric.icon, size: 18, color: metric.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        metric.label,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.caption,
                  style: const TextStyle(color: AppPalette.muted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 8,
                    backgroundColor: AppPalette.primarySoft,
                    valueColor: AlwaysStoppedAnimation<Color>(metric.color),
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

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'KPI Widgetları',
            subtitle: 'Performans puanı, süre ve kalite özetleri',
          ),
          const SizedBox(height: 18),
          for (final metric in metrics)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: metric.color.withValues(alpha: 0.15),
                      child: Icon(metric.icon, color: metric.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.label,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            metric.caption,
                            style: const TextStyle(color: AppPalette.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      metric.value,
                      style: TextStyle(
                        color: metric.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
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

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.notifications});

  final List<DashboardNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Bildirim Merkezi',
            subtitle: 'Okunmamış özetler ve kritik uyarılar',
          ),
          const SizedBox(height: 18),
          for (final notification in notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          notification.color.withValues(alpha: 0.14),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 18,
                        color: notification.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.subtitle,
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
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.items});

  final List<DashboardFocusItem> items;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Bugün Ne Yapılmalı?',
            subtitle: 'Panelin karar ve aksiyon listesi',
          ),
          const SizedBox(height: 18),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppPalette.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppPalette.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.sidebar,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AutomationPanel extends StatelessWidget {
  const _AutomationPanel({required this.automations});

  final List<DashboardAutomation> automations;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Otomasyon Merkezi',
            subtitle: 'Monday benzeri kural ve tetik görünümü',
          ),
          const SizedBox(height: 18),
          if (automations.isEmpty)
            const Text(
              'Henüz otomasyon kuralı görünmüyor.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final automation in automations)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        automation.name,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        automation.summary,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DashboardPill(
                            label: automation.statusLabel,
                            color: AppPalette.primary,
                          ),
                          _DashboardPill(
                            label: automation.lastRunLabel,
                            color: AppPalette.success,
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
}

class _ActivityFeedPanel extends StatelessWidget {
  const _ActivityFeedPanel({required this.items});

  final List<DashboardActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Aktivite Akışı',
            subtitle: 'Öğe güncellemeleri, yorumlar ve otomasyon sonuçları',
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Text(
              'Henüz aktivite kaydı görünmüyor.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppPalette.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                Text(
                                  item.ageLabel,
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.detail,
                              style: const TextStyle(
                                color: AppPalette.muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.actor,
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
              ),
        ],
      ),
    );
  }
}

class _WorkloadPanel extends StatelessWidget {
  const _WorkloadPanel({required this.rows});

  final List<DashboardWorkloadRow> rows;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'İş Yükü',
            subtitle: 'Kişi bazlı kapasite ve takip edilen süre',
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const Text(
              'İş yükü verisi henüz görünmüyor.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.name,
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            row.statusLabel,
                            style: const TextStyle(
                              color: AppPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${row.assignedCount} aktif iş · ${row.trackedHoursLabel}',
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (row.capacityPercent / 100).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: AppPalette.primarySoft,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            row.capacityPercent >= 100
                                ? AppPalette.danger
                                : AppPalette.success,
                          ),
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

class _RequestFormsPanel extends StatelessWidget {
  const _RequestFormsPanel({required this.forms});

  final List<DashboardRequestForm> forms;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'İstek Formları',
            subtitle: 'Formdan açılan iş akışları',
          ),
          const SizedBox(height: 18),
          if (forms.isEmpty)
            const Text(
              'Henüz form akışı tanımlanmamış.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final form in forms)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.title,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${form.targetTeam} · Bugün ${form.submissionsToday} kayıt',
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 10),
                      _DashboardPill(
                        label: form.ctaLabel,
                        color: const Color(0xFF7A7AE6),
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

class _DashboardPill extends StatelessWidget {
  const _DashboardPill({
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProjectPanel extends StatelessWidget {
  const _ProjectPanel({required this.projects});

  final List<DashboardProject> projects;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Aktif Projeler',
            subtitle: 'Panel ana sayfasında izlenen proje akışı',
          ),
          const SizedBox(height: 18),
          for (final project in projects) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    project.name.isEmpty ? '?' : project.name[0],
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
                        project.name,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.type,
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(project.progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: project.progress,
                minHeight: 8,
                backgroundColor: AppPalette.primarySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
