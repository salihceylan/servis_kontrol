import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerSupportPage extends StatefulWidget {
  const OwnerSupportPage({
    super.key,
    required this.repository,
    required this.onOpenCompany,
  });

  final OwnerPortalRepository repository;
  final ValueChanged<String> onOpenCompany;

  @override
  State<OwnerSupportPage> createState() => _OwnerSupportPageState();
}

class _OwnerSupportPageState extends State<OwnerSupportPage> {
  OwnerSupportSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  String? _busyCompanyId;

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
      final snapshot = await widget.repository.loadSupport();
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

  Future<void> _registerSupportAccess(String companyId) async {
    setState(() => _busyCompanyId = companyId);
    try {
      await widget.repository.registerSupportAccess(companyId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destek erisim kaydi olusturuldu.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _busyCompanyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StatePanel.loading(
        title: 'Destek verileri yukleniyor',
        message: 'Tenant rosteri ve owner destek erisim kayitlari aliniyor.',
      );
    }
    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return StatePanel.empty(
        title: 'Destek verisi yok',
        message: 'Owner destek listesi bos.',
        onRetry: _load,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destek / Erisim',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tenant destek temaslarini izle ve owner tarafindan acilan erisim kayitlarini logla.',
                    style: TextStyle(color: AppPalette.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final companies = _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tenant Destek Rosteri',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final company in snapshot.companies) ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onOpenCompany(company.id),
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
                                  '${company.ownerEmail} • ${company.subscription.planName}',
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _busyCompanyId == company.id
                              ? null
                              : () => _registerSupportAccess(company.id),
                          icon: const Icon(Icons.shield_outlined),
                          label: Text(
                            _busyCompanyId == company.id
                                ? 'Kaydediliyor...'
                                : 'Erisim Kaydi',
                          ),
                        ),
                      ],
                    ),
                    if (company != snapshot.companies.last) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            );

            final logs = _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son Owner Erisim Kayitlari',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.accessLogs.isEmpty)
                    const Text(
                      'Henüz destek erişim kaydı yok.',
                      style: TextStyle(color: AppPalette.muted),
                    )
                  else
                    for (final item in snapshot.accessLogs) ...[
                      Text(
                        item.companyName,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.actorName} • ${item.actorEmail}',
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatOwnerDateTime(item.createdAt),
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (item != snapshot.accessLogs.last) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                    ],
                ],
              ),
            );

            if (!wide) {
              return Column(
                children: [companies, const SizedBox(height: 18), logs],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: companies),
                const SizedBox(width: 18),
                Expanded(child: logs),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

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
