import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerRequestsPage extends StatefulWidget {
  const OwnerRequestsPage({super.key, required this.repository});

  final OwnerPortalRepository repository;

  @override
  State<OwnerRequestsPage> createState() => _OwnerRequestsPageState();
}

class _OwnerRequestsPageState extends State<OwnerRequestsPage> {
  OwnerRequestsSnapshot? _snapshot;
  String? _errorMessage;
  bool _loading = true;
  String _filter = 'all';

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
      final snapshot = await widget.repository.loadRequests();
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
        title: 'Talepler yukleniyor',
        message: 'Kaydol ve sifre talepleri listeleniyor.',
      );
    }
    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
    }
    final snapshot = _snapshot;
    if (snapshot == null) {
      return StatePanel.empty(
        title: 'Talep yok',
        message: 'Owner talep listesi bos.',
        onRetry: _load,
      );
    }

    final items = snapshot.items
        .where((item) {
          return switch (_filter) {
            'sign_up_requested' => item.type == 'sign_up_requested',
            'forgot_password_requested' =>
              item.type == 'forgot_password_requested',
            _ => true,
          };
        })
        .toList(growable: false);

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
                    'Kaydol Talepleri',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Kaydol ve sifre sifirlama taleplerini owner arka ofisinden takip et.',
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Tum Talepler'),
              selected: _filter == 'all',
              onSelected: (_) => setState(() => _filter = 'all'),
            ),
            ChoiceChip(
              label: const Text('Kaydol'),
              selected: _filter == 'sign_up_requested',
              onSelected: (_) => setState(() => _filter = 'sign_up_requested'),
            ),
            ChoiceChip(
              label: const Text('Sifre'),
              selected: _filter == 'forgot_password_requested',
              onSelected: (_) =>
                  setState(() => _filter = 'forgot_password_requested'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          StatePanel.empty(
            title: 'Kayit bulunamadi',
            message: 'Secilen filtre icin talep yok.',
            onRetry: _load,
          )
        else
          Container(
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
            child: Column(
              children: [
                for (final item in items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: item.typeColor.withValues(alpha: 0.12),
                        child: Icon(
                          item.type == 'sign_up_requested'
                              ? Icons.person_add_alt_1_rounded
                              : Icons.lock_reset_rounded,
                          color: item.typeColor,
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
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                item.typeLabel,
                                if (item.fullName.isNotEmpty) item.fullName,
                                if (item.companyName.isNotEmpty)
                                  item.companyName,
                              ].join(' • '),
                              style: const TextStyle(color: AppPalette.muted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (item.phone.isNotEmpty) item.phone,
                                if (item.ipAddress.isNotEmpty) item.ipAddress,
                              ].join(' • '),
                              style: const TextStyle(
                                color: AppPalette.muted,
                                fontSize: 12,
                              ),
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
                  if (item != items.last) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }
}
