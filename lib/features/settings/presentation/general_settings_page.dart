import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/settings/application/settings_controller.dart';
import 'package:servis_kontrol/features/settings/domain/general_settings.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  late final SettingsController _controller;
  final _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(apiClient: widget.apiClient);
    _controller.addListener(_syncFields);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFields);
    _controller.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _syncFields() {
    final settings = _controller.settings;
    if (settings == null) {
      return;
    }
    if (_companyController.text != settings.companyName) {
      _companyController.text = settings.companyName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const StatePanel.loading(
            title: 'Ayarlar yükleniyor',
            message: 'Şirket yapılandırması sunucudan alınıyor.',
          );
        }
        if (_controller.errorMessage != null) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }

        final settings = _controller.settings;
        if (settings == null) {
          return const StatePanel.empty(
            title: 'Ayar kaydı bulunamadı',
            message: 'Bu şirket için genel ayarlar henüz oluşturulmamış.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              title: 'Genel Ayarlar',
              subtitle:
                  'Şirket, dil, zaman dilimi ve bildirim varsayılanlarını yönet.',
            ),
            const SizedBox(height: 18),
            _SettingsCard(
              title: 'Şirket Kimliği',
              subtitle: '6 haneli şirket kodu ve görünür ad bilgisi',
              child: Column(
                children: [
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Şirket adı'),
                  ),
                  const SizedBox(height: 14),
                  _ReadOnlyField(
                    label: 'Şirket kodu',
                    value: settings.companyCode.isEmpty
                        ? 'Tanımlanmadı'
                        : settings.companyCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final workspace = _SettingsCard(
                  title: 'Çalışma Alanı',
                  subtitle: 'Dil, takvim ve zaman dilimi varsayılanları',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoChip(
                        label: 'Dil',
                        value: settings.defaultLanguage.toUpperCase(),
                      ),
                      _InfoChip(
                        label: 'Zaman dilimi',
                        value: settings.timezone,
                      ),
                      _InfoChip(
                        label: 'Hafta başlangıcı',
                        value: settings.weekStartsOn,
                      ),
                      _InfoChip(
                        label: 'Tarih formatı',
                        value: settings.dateFormat,
                      ),
                    ],
                  ),
                );
                final notifications = _SettingsCard(
                  title: 'Bildirim Varsayılanları',
                  subtitle: 'Yeni kullanıcılar için açılacak kanallar',
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Günlük özet',
                        value: settings.notificationSummaryEnabled,
                      ),
                      _ToggleRow(
                        label: 'E-posta bildirimleri',
                        value: settings.emailNotificationsEnabled,
                      ),
                      _ToggleRow(
                        label: 'Slack bildirimleri',
                        value: settings.slackNotificationsEnabled,
                      ),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      workspace,
                      const SizedBox(height: 16),
                      notifications,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: workspace),
                    const SizedBox(width: 16),
                    Expanded(child: notifications),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final modules = _SettingsCard(
                  title: 'Platform Modülleri',
                  subtitle: 'Form, otomasyon ve zaman takibi varsayılanları',
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Otomasyon merkezi',
                        value: settings.automationCenterEnabled,
                      ),
                      _ToggleRow(
                        label: 'İstek formları',
                        value: settings.workFormsEnabled,
                      ),
                      _ToggleRow(
                        label: 'Zaman takibi',
                        value: settings.timeTrackingEnabled,
                      ),
                    ],
                  ),
                );
                final integrations = _SettingsCard(
                  title: 'Entegrasyonlar',
                  subtitle: 'Harici servis bağlantıları ve durumları',
                  child: settings.integrations.isEmpty
                      ? const Text(
                          'Henüz entegrasyon bağlantısı görünmüyor.',
                          style: TextStyle(color: AppPalette.muted),
                        )
                      : Column(
                          children: [
                            for (final integration in settings.integrations)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _IntegrationTile(integration: integration),
                              ),
                          ],
                        ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      modules,
                      const SizedBox(height: 16),
                      integrations,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: modules),
                    const SizedBox(width: 16),
                    Expanded(child: integrations),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'İzin Profilleri',
              subtitle: 'Tahta, görev ve rapor erişim profilleri',
              child: settings.permissionProfiles.isEmpty
                  ? const Text(
                      'Henüz izin profili görünmüyor.',
                      style: TextStyle(color: AppPalette.muted),
                    )
                  : Column(
                      children: [
                        for (final profile in settings.permissionProfiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PermissionTile(profile: profile),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _controller.isSaving ? null : () => _save(settings),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _controller.isSaving
                      ? 'Kaydediliyor...'
                      : 'Ayarları Kaydet',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save(GeneralSettings settings) async {
    final nextSettings = settings.copyWith(
      companyName: _companyController.text.trim(),
    );
    final success = await _controller.save(nextSettings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ayarlar kaydedildi.'
              : (_controller.errorMessage ?? 'Ayarlar kaydedilemedi.'),
        ),
      ),
    );
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
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
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            value ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            color: value ? AppPalette.success : AppPalette.muted,
          ),
        ],
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({required this.integration});

  final IntegrationSetting integration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  integration.name,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  integration.statusLabel,
                  style: const TextStyle(color: AppPalette.muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: integration.connected,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.profile});

  final PermissionProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            profile.title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.summary,
            style: const TextStyle(
              color: AppPalette.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
