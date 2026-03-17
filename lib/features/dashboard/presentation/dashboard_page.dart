import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/dashboard/application/dashboard_controller.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.apiClient});

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
            message: 'Operasyon özeti sunucudan alınıyor.',
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return wide
                ? _buildWide(snapshot)
                : _buildNarrow(snapshot);
          },
        );
      },
    );
  }

  // ── Desktop layout ────────────────────────────────────────────────────────

  Widget _buildWide(DashboardSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GreetingBanner(snapshot: snapshot),
        const SizedBox(height: 20),
        _StatGrid(metrics: snapshot.summaryCards, crossAxisCount: 4),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _KpiPanel(metrics: snapshot.kpiCards),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _NotificationPanel(notifications: snapshot.notifications),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              child: _AutomationPanel(automations: snapshot.automations),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _ActivityFeedPanel(items: snapshot.activityFeed),
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
              child: _RequestFormsPanel(forms: snapshot.requestForms),
            ),
          ],
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────

  Widget _buildNarrow(DashboardSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GreetingBanner(snapshot: snapshot),
        const SizedBox(height: 16),
        _StatGrid(metrics: snapshot.summaryCards, crossAxisCount: 2),
        const SizedBox(height: 16),
        _FocusPanel(items: snapshot.focusItems),
        const SizedBox(height: 16),
        _ActivityFeedPanel(items: snapshot.activityFeed.take(3).toList()),
      ],
    );
  }
}

// ── Greeting banner ───────────────────────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({required this.snapshot});
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final palette = context.rolePalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.primary,
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.heroTitle,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  snapshot.heroHighlight,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat grid ─────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.metrics, required this.crossAxisCount});
  final List<DashboardMetric> metrics;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: crossAxisCount == 4 ? 2.0 : 1.8,
      ),
      itemBuilder: (context, i) => _StatCard(metric: metrics[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.metric});
  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 16, color: metric.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 4,
              backgroundColor: AppPalette.border,
              valueColor: AlwaysStoppedAnimation<Color>(metric.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: AppPalette.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── KPI Panel ─────────────────────────────────────────────────────────────────

class _KpiPanel extends StatelessWidget {
  const _KpiPanel({required this.metrics});
  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'KPI Widgetları',
      subtitle: 'Performans puanı, süre ve kalite özetleri',
      child: Column(
        children: [
          for (int i = 0; i < metrics.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(metrics[i].icon, color: metrics[i].color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics[i].label,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          metrics[i].caption,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    metrics[i].value,
                    style: TextStyle(
                      color: metrics[i].color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Notification Panel ────────────────────────────────────────────────────────

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.notifications});
  final List<DashboardNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Bildirimler',
      subtitle: 'Okunmamış özetler ve kritik uyarılar',
      child: Column(
        children: [
          for (int i = 0; i < notifications.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: notifications[i].color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notifications[i].title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notifications[i].subtitle,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Focus Panel ───────────────────────────────────────────────────────────────

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.items});
  final List<DashboardFocusItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.rolePalette;
    return _PanelCard(
      title: 'Bugün Ne Yapılmalı?',
      subtitle: 'Karar ve aksiyon listesi',
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: palette.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          items[i].subtitle,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      items[i].badge,
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Project Panel ─────────────────────────────────────────────────────────────

class _ProjectPanel extends StatelessWidget {
  const _ProjectPanel({required this.projects});
  final List<DashboardProject> projects;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Aktif Projeler',
      subtitle: 'İzlenen proje akışı',
      child: Column(
        children: [
          for (int i = 0; i < projects.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    projects[i].name.isEmpty ? '?' : projects[i].name[0],
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              projects[i].name,
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${(projects[i].progress * 100).round()}%',
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: projects[i].progress,
                          minHeight: 5,
                          backgroundColor: AppPalette.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppPalette.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Automation Panel ──────────────────────────────────────────────────────────

class _AutomationPanel extends StatelessWidget {
  const _AutomationPanel({required this.automations});
  final List<DashboardAutomation> automations;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Otomasyon Merkezi',
      subtitle: 'Aktif kural ve tetikler',
      child: automations.isEmpty
          ? const Text(
              'Henüz otomasyon kuralı yok.',
              style: TextStyle(color: AppPalette.muted, fontSize: 13),
            )
          : Column(
              children: [
                for (int i = 0; i < automations.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          automations[i].name,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          automations[i].summary,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            _Pill(
                              label: automations[i].statusLabel,
                              color: AppPalette.primary,
                            ),
                            _Pill(
                              label: automations[i].lastRunLabel,
                              color: AppPalette.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Activity Feed ─────────────────────────────────────────────────────────────

class _ActivityFeedPanel extends StatelessWidget {
  const _ActivityFeedPanel({required this.items});
  final List<DashboardActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Aktivite Akışı',
      subtitle: 'Güncellemeler, yorumlar ve otomasyon sonuçları',
      child: items.isEmpty
          ? const Text(
              'Henüz aktivite kaydı yok.',
              style: TextStyle(color: AppPalette.muted, fontSize: 13),
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: AppPalette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      items[i].title,
                                      style: const TextStyle(
                                        color: AppPalette.text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    items[i].ageLabel,
                                    style: const TextStyle(
                                      color: AppPalette.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].detail,
                                style: const TextStyle(
                                  color: AppPalette.muted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].actor,
                                style: const TextStyle(
                                  color: AppPalette.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Workload Panel ────────────────────────────────────────────────────────────

class _WorkloadPanel extends StatelessWidget {
  const _WorkloadPanel({required this.rows});
  final List<DashboardWorkloadRow> rows;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'İş Yükü',
      subtitle: 'Kişi bazlı kapasite ve takip edilen süre',
      child: rows.isEmpty
          ? const Text(
              'İş yükü verisi henüz yok.',
              style: TextStyle(color: AppPalette.muted, fontSize: 13),
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rows[i].name,
                                style: const TextStyle(
                                  color: AppPalette.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '${rows[i].assignedCount} iş · ${rows[i].trackedHoursLabel}',
                              style: const TextStyle(
                                color: AppPalette.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (rows[i].capacityPercent / 100).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: AppPalette.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rows[i].capacityPercent >= 100
                                  ? AppPalette.danger
                                  : AppPalette.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Request Forms Panel ───────────────────────────────────────────────────────

class _RequestFormsPanel extends StatelessWidget {
  const _RequestFormsPanel({required this.forms});
  final List<DashboardRequestForm> forms;

  @override
  Widget build(BuildContext context) {
    final palette = context.rolePalette;
    return _PanelCard(
      title: 'İstek Formları',
      subtitle: 'Formdan açılan iş akışları',
      child: forms.isEmpty
          ? const Text(
              'Henüz form akışı tanımlanmamış.',
              style: TextStyle(color: AppPalette.muted, fontSize: 13),
            )
          : Column(
              children: [
                for (int i = 0; i < forms.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                forms[i].title,
                                style: const TextStyle(
                                  color: AppPalette.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${forms[i].targetTeam} · Bugün ${forms[i].submissionsToday} kayıt',
                                style: const TextStyle(
                                  color: AppPalette.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Pill(label: forms[i].ctaLabel, color: palette.primary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Shared: Pill ──────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

