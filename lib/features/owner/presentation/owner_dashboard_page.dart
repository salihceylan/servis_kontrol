import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({
    super.key,
    required this.repository,
    required this.onOpenCompany,
  });

  final OwnerPortalRepository repository;
  final ValueChanged<String> onOpenCompany;

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  OwnerDashboardSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await widget.repository.loadDashboard();
      if (!mounted) {
        return;
      }
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '$error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StatePanel.loading(
        title: 'Owner paneli hazirlaniyor',
        message: 'Musteri ve lisans verileri sunucudan aliniyor.',
      );
    }

    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return StatePanel.empty(
        title: 'Veri bulunamadi',
        message: 'Owner paneli icin kayit bulunamadi.',
        onRetry: _load,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(snapshot: snapshot, onRefresh: _load),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1120;
            if (!wide) {
              return Column(
                children: [
                  _MetricGrid(metrics: snapshot.summaryCards),
                  const SizedBox(height: 18),
                  _PlanBreakdown(items: snapshot.planBreakdown),
                  const SizedBox(height: 18),
                  _RequestFeed(items: snapshot.recentRequests),
                  const SizedBox(height: 18),
                  _CompanyWatchlist(
                    items: snapshot.companyWatchlist,
                    onOpenCompany: widget.onOpenCompany,
                  ),
                ],
              );
            }

            return Column(
              children: [
                _MetricGrid(metrics: snapshot.summaryCards),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlanBreakdown(items: snapshot.planBreakdown),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _RequestFeed(items: snapshot.recentRequests),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _CompanyWatchlist(
                  items: snapshot.companyWatchlist,
                  onOpenCompany: widget.onOpenCompany,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.snapshot, required this.onRefresh});

  final OwnerDashboardSnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11274A), Color(0xFF173B62), Color(0xFFB15B21)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18071A39),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workflow Control Tower',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.subtitle,
                  style: const TextStyle(
                    color: Color(0xD6FFFFFF),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          FilledButton.icon(
            onPressed: onRefresh,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppPalette.text,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<OwnerMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: (constraints.maxWidth - ((columns - 1) * 16)) / columns,
                child: _SurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: metric.color.withValues(alpha: 0.12),
                        child: Icon(metric.icon, color: metric.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
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
                            const SizedBox(height: 8),
                            Text(
                              metric.value,
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              metric.caption,
                              style: const TextStyle(
                                color: AppPalette.muted,
                                height: 1.45,
                              ),
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
      },
    );
  }
}

class _PlanBreakdown extends StatelessWidget {
  const _PlanBreakdown({required this.items});

  final List<OwnerPlanBreakdown> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.companyCount);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paket Dagilimi',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aktif tenantlarin plan yogunlugu canli veriden okunuyor.',
            style: TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.planName,
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${item.companyCount} tenant',
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : item.companyCount / total,
                minHeight: 10,
                color: AppPalette.primary,
                backgroundColor: AppPalette.surfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _RequestFeed extends StatelessWidget {
  const _RequestFeed({required this.items});

  final List<OwnerRequestItem> items;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Talepler',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Acik talep yok.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.typeColor.withValues(alpha: 0.12),
                    child: Icon(
                      item.type == 'sign_up_requested'
                          ? Icons.person_add_alt_1_rounded
                          : Icons.lock_reset_rounded,
                      color: item.typeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.email,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.companyName.isEmpty
                              ? item.typeLabel
                              : '${item.typeLabel} • ${item.companyName}',
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatOwnerDateTime(item.createdAt),
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _CompanyWatchlist extends StatelessWidget {
  const _CompanyWatchlist({required this.items, required this.onOpenCompany});

  final List<OwnerCompanyItem> items;
  final ValueChanged<String> onOpenCompany;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Takip Listesi',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (final company in items) ...[
            InkWell(
              onTap: () => onOpenCompany(company.id),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${company.subscription.planName} • ${company.stats.openTasks} acik gorev',
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
                        color: company.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        company.statusLabel,
                        style: TextStyle(
                          color: company.statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppPalette.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (company != items.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
