import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerSubscriptionsPage extends StatefulWidget {
  const OwnerSubscriptionsPage({
    super.key,
    required this.repository,
    required this.onOpenCompany,
  });

  final OwnerPortalRepository repository;
  final ValueChanged<String> onOpenCompany;

  @override
  State<OwnerSubscriptionsPage> createState() => _OwnerSubscriptionsPageState();
}

class _OwnerSubscriptionsPageState extends State<OwnerSubscriptionsPage> {
  List<OwnerCompanyItem> _companies = const [];
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
      final companies = await widget.repository.loadCompanies();
      if (!mounted) {
        return;
      }
      setState(() => _companies = companies);
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
        title: 'Abonelikler yukleniyor',
        message: 'Paket ve lisans sinirlari okunuyor.',
      );
    }
    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
    }

    final planCounts = <String, int>{};
    for (final company in _companies) {
      planCounts[company.subscription.planName] =
          (planCounts[company.subscription.planName] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Abonelik / Paket',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tum tenant planlarini ve lisans bitislerini tek listede takip et.',
          style: TextStyle(color: AppPalette.muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in planCounts.entries)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Surface(
          child: Column(
            children: [
              for (final company in _companies) ...[
                InkWell(
                  onTap: () => widget.onOpenCompany(company.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            company.name,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            company.subscription.planName,
                            style: const TextStyle(color: AppPalette.muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${company.stats.activeUsers}/${company.subscription.userLimit}',
                            style: const TextStyle(color: AppPalette.muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatOwnerDate(company.subscription.licenseEndsAt),
                            style: const TextStyle(color: AppPalette.muted),
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onOpenCompany(company.id),
                          child: const Text('Detay'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (company != _companies.last) const Divider(height: 1),
              ],
            ],
          ),
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
