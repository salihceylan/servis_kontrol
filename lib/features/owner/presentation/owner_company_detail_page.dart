import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerCompanyDetailPage extends StatefulWidget {
  const OwnerCompanyDetailPage({
    super.key,
    required this.companyId,
    required this.repository,
    required this.onBack,
  });

  final String companyId;
  final OwnerPortalRepository repository;
  final VoidCallback onBack;

  @override
  State<OwnerCompanyDetailPage> createState() => _OwnerCompanyDetailPageState();
}

class _OwnerCompanyDetailPageState extends State<OwnerCompanyDetailPage> {
  OwnerCompanyDetail? _detail;
  String? _errorMessage;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OwnerCompanyDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final detail = await widget.repository.loadCompanyDetail(
        widget.companyId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _detail = detail);
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

  Future<void> _updateProfile() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }
    final update = await showDialog<OwnerCompanyProfileUpdate>(
      context: context,
      builder: (context) => _CompanyProfileDialog(detail: detail),
    );
    if (update == null) {
      return;
    }

    await _runBusy(() async {
      final updated = await widget.repository.updateCompanyProfile(update);
      if (!mounted) {
        return;
      }
      setState(() => _detail = updated);
    });
  }

  Future<void> _updateSubscription() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }
    final update = await showDialog<OwnerSubscriptionUpdate>(
      context: context,
      builder: (context) => _SubscriptionDialog(detail: detail),
    );
    if (update == null) {
      return;
    }

    await _runBusy(() async {
      final updated = await widget.repository.updateSubscription(update);
      if (!mounted) {
        return;
      }
      setState(() => _detail = updated);
    });
  }

  Future<void> _registerSupportAccess() async {
    await _runBusy(
      () => widget.repository.registerSupportAccess(widget.companyId),
    );
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Islem tamamlandi.')));
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
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StatePanel.loading(
        title: 'Sirket detayi yukleniyor',
        message: 'Tenant lisansi, destek ayarlari ve aktiviteler okunuyor.',
      );
    }
    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
    }
    final detail = _detail;
    if (detail == null) {
      return StatePanel.empty(
        title: 'Sirket bulunamadi',
        message: 'Secilen tenant kaydi yok.',
        onRetry: _load,
      );
    }

    final modules = detail.subscription.modules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Sirketler'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _busy ? null : _registerSupportAccess,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Destek Erisimi'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _updateProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Genel Bilgi'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _updateSubscription,
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Abonelik'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.name,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${detail.companyCode} • ${detail.ownerName} • ${detail.ownerEmail}',
                style: const TextStyle(color: AppPalette.muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Chip(label: detail.subscription.planName),
                  _Chip(label: detail.statusLabel),
                  _Chip(
                    label:
                        'Lisans ${formatOwnerDate(detail.subscription.licenseEndsAt)}',
                  ),
                  _Chip(label: detail.timezone),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricCard(
              title: 'Kullanici',
              value:
                  '${detail.stats.activeUsers}/${detail.subscription.userLimit}',
              subtitle: 'Aktif hesap',
            ),
            _MetricCard(
              title: 'Acik Gorev',
              value: '${detail.stats.openTasks}',
              subtitle: 'Toplam ${detail.stats.taskCount} is',
            ),
            _MetricCard(
              title: 'Revizyon',
              value: '${detail.stats.openRevisions}',
              subtitle: 'Aktif kontrol kaydi',
            ),
            _MetricCard(
              title: 'Depolama',
              value:
                  '${formatStorageGb(detail.stats.storageUsedGb)} / ${detail.subscription.storageLimitGb} GB',
              subtitle: 'Ek dosya alani',
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1040;
            final left = _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ayarlar',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Line('Destek e-posta', detail.support.supportEmail),
                  _Line('SLA', detail.support.responseSla),
                  _Line('Dil', detail.locale),
                  _Line(
                    'Son giris',
                    formatOwnerDateTime(detail.stats.lastLoginAt),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ModuleChip(label: 'Raporlar', enabled: modules.reports),
                      _ModuleChip(
                        label: 'Revizyonlar',
                        enabled: modules.revisions,
                      ),
                      _ModuleChip(
                        label: 'Otomasyon',
                        enabled: modules.automations,
                      ),
                      _ModuleChip(
                        label: 'Form Merkezi',
                        enabled: modules.requestForms,
                      ),
                    ],
                  ),
                ],
              ),
            );
            final right = _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son Aktivite',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (detail.recentActivity.isEmpty)
                    const Text(
                      'Audit kaydi bulunmuyor.',
                      style: TextStyle(color: AppPalette.muted),
                    )
                  else
                    for (final item in detail.recentActivity) ...[
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.detail,
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
                      if (item != detail.recentActivity.last) ...[
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
                children: [
                  left,
                  const SizedBox(height: 18),
                  right,
                  const SizedBox(height: 18),
                  _LoginAttempts(detail: detail),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 18),
                    Expanded(child: right),
                  ],
                ),
                const SizedBox(height: 18),
                _LoginAttempts(detail: detail),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LoginAttempts extends StatelessWidget {
  const _LoginAttempts({required this.detail});

  final OwnerCompanyDetail detail;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giris Denemeleri',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (detail.loginActivity.isEmpty)
            const Text(
              'Giris denemesi kaydi yok.',
              style: TextStyle(color: AppPalette.muted),
            )
          else
            for (final item in detail.loginActivity) ...[
              Row(
                children: [
                  Icon(
                    item.isSuccess
                        ? Icons.verified_user_outlined
                        : Icons.error_outline_rounded,
                    color: item.isSuccess
                        ? AppPalette.success
                        : AppPalette.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.email} • ${item.ipAddress.isEmpty ? '-' : item.ipAddress}',
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatOwnerDateTime(item.attemptedAt),
                    style: const TextStyle(
                      color: AppPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (item != detail.loginActivity.last) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],
            ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppPalette.muted)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

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

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppPalette.success : AppPalette.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyProfileDialog extends StatefulWidget {
  const _CompanyProfileDialog({required this.detail});

  final OwnerCompanyDetail detail;

  @override
  State<_CompanyProfileDialog> createState() => _CompanyProfileDialogState();
}

class _CompanyProfileDialogState extends State<_CompanyProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _slaController;
  late String _status;
  late String _locale;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.name);
    _supportEmailController = TextEditingController(
      text: widget.detail.support.supportEmail,
    );
    _slaController = TextEditingController(
      text: widget.detail.support.responseSla,
    );
    _status = widget.detail.status;
    _locale = widget.detail.locale;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _supportEmailController.dispose();
    _slaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Genel Bilgi'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Sirket adi'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Durum'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  DropdownMenuItem(value: 'paused', child: Text('Beklemede')),
                  DropdownMenuItem(value: 'inactive', child: Text('Pasif')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _locale,
                decoration: const InputDecoration(labelText: 'Dil'),
                items: const [
                  DropdownMenuItem(value: 'tr', child: Text('tr')),
                  DropdownMenuItem(value: 'en', child: Text('en')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _locale = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _supportEmailController,
                decoration: const InputDecoration(labelText: 'Destek e-posta'),
                validator: _email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slaController,
                decoration: const InputDecoration(labelText: 'SLA'),
                validator: _required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgec'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              OwnerCompanyProfileUpdate(
                companyId: widget.detail.id,
                companyName: _nameController.text.trim(),
                status: _status,
                timezone: widget.detail.timezone,
                locale: _locale,
                supportEmail: _supportEmailController.text.trim(),
                responseSla: _slaController.text.trim(),
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan gerekli.';
    }
    return null;
  }

  String? _email(String? value) {
    final message = _required(value);
    if (message != null) {
      return message;
    }
    if (!(value?.contains('@') ?? false)) {
      return 'Gecerli bir e-posta girin.';
    }
    return null;
  }
}

class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog({required this.detail});

  final OwnerCompanyDetail detail;

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userLimitController;
  late final TextEditingController _storageController;
  late String _planName;
  late DateTime _licenseEndsAt;
  late bool _reports;
  late bool _revisions;
  late bool _automations;
  late bool _requestForms;

  @override
  void initState() {
    super.initState();
    _planName = widget.detail.subscription.planName;
    _userLimitController = TextEditingController(
      text: '${widget.detail.subscription.userLimit}',
    );
    _storageController = TextEditingController(
      text: '${widget.detail.subscription.storageLimitGb}',
    );
    _licenseEndsAt =
        widget.detail.subscription.licenseEndsAt ??
        DateTime.now().add(const Duration(days: 30));
    _reports = widget.detail.subscription.modules.reports;
    _revisions = widget.detail.subscription.modules.revisions;
    _automations = widget.detail.subscription.modules.automations;
    _requestForms = widget.detail.subscription.modules.requestForms;
  }

  @override
  void dispose() {
    _userLimitController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseEndsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _licenseEndsAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Abonelik'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _planName,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: const [
                    DropdownMenuItem(value: 'Scale', child: Text('Scale')),
                    DropdownMenuItem(value: 'Pro', child: Text('Pro')),
                    DropdownMenuItem(
                      value: 'Enterprise',
                      child: Text('Enterprise'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _planName = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kullanici limiti',
                  ),
                  validator: _number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _storageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Depolama GB'),
                  validator: _number,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Lisans bitis tarihi',
                    ),
                    child: Text(formatOwnerDate(_licenseEndsAt)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _reports,
                  onChanged: (value) => setState(() => _reports = value),
                  title: const Text('Raporlar'),
                ),
                SwitchListTile.adaptive(
                  value: _revisions,
                  onChanged: (value) => setState(() => _revisions = value),
                  title: const Text('Revizyonlar'),
                ),
                SwitchListTile.adaptive(
                  value: _automations,
                  onChanged: (value) => setState(() => _automations = value),
                  title: const Text('Otomasyon'),
                ),
                SwitchListTile.adaptive(
                  value: _requestForms,
                  onChanged: (value) => setState(() => _requestForms = value),
                  title: const Text('Form Merkezi'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgec'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              OwnerSubscriptionUpdate(
                companyId: widget.detail.id,
                planName: _planName,
                userLimit: int.parse(_userLimitController.text),
                storageLimitGb: int.parse(_storageController.text),
                licenseEndsAt: _licenseEndsAt,
                modules: OwnerCompanyModules(
                  reports: _reports,
                  revisions: _revisions,
                  automations: _automations,
                  requestForms: _requestForms,
                ),
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  String? _number(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Gecerli bir sayi girin.';
    }
    return null;
  }
}
