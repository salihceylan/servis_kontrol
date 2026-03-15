import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_formatters.dart';

class OwnerCompaniesPage extends StatefulWidget {
  const OwnerCompaniesPage({
    super.key,
    required this.repository,
    required this.onOpenCompany,
  });

  final OwnerPortalRepository repository;
  final ValueChanged<String> onOpenCompany;

  @override
  State<OwnerCompaniesPage> createState() => _OwnerCompaniesPageState();
}

class _OwnerCompaniesPageState extends State<OwnerCompaniesPage> {
  List<OwnerCompanyItem> _companies = const [];
  String? _errorMessage;
  bool _loading = true;
  bool _creating = false;

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

  Future<void> _createCompany() async {
    final draft = await showDialog<OwnerCompanyDraft>(
      context: context,
      builder: (context) => const _CreateCompanyDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _creating = true);
    try {
      final detail = await widget.repository.createCompany(draft);
      if (!mounted) {
        return;
      }
      await _load();
      widget.onOpenCompany(detail.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Yeni sirket olusturuldu.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StatePanel.loading(
        title: 'Sirketler yukleniyor',
        message: 'Tenant listesi ve lisans durumlari okunuyor.',
      );
    }

    if (_errorMessage != null) {
      return StatePanel.error(message: _errorMessage!, onRetry: _load);
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
                    'Sirketler',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tenantlari, owner hesaplarini ve lisans sinirlarini merkezi olarak yonet.',
                    style: TextStyle(color: AppPalette.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _creating ? null : _createCompany,
              icon: const Icon(Icons.add_business_rounded),
              label: Text(_creating ? 'Olusturuluyor...' : 'Yeni Sirket'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_companies.isEmpty)
          StatePanel.empty(
            title: 'Sirket bulunamadi',
            message: 'Owner panelinde henuz tenant kaydi yok.',
            onRetry: _load,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1120
                  ? 2
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - ((columns - 1) * 16)) / columns;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final company in _companies)
                    SizedBox(
                      width: itemWidth,
                      child: _CompanyCard(
                        company: company,
                        onTap: () => widget.onOpenCompany(company.id),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company, required this.onTap});

  final OwnerCompanyItem company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usageRatio = company.subscription.userLimit == 0
        ? 0.0
        : (company.stats.activeUsers / company.subscription.userLimit).clamp(
            0.0,
            1.0,
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${company.companyCode} • ${company.ownerName}',
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
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.workspace_premium_rounded,
                  label: company.subscription.planName,
                ),
                _InfoPill(
                  icon: Icons.people_alt_outlined,
                  label:
                      '${company.stats.activeUsers}/${company.subscription.userLimit} kullanici',
                ),
                _InfoPill(
                  icon: Icons.storage_rounded,
                  label:
                      '${formatStorageGb(company.stats.storageUsedGb)} / ${company.subscription.storageLimitGb} GB',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Aktif kullanici dolulugu',
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: usageRatio,
                minHeight: 10,
                color: AppPalette.primary,
                backgroundColor: AppPalette.surfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Acik gorev',
                    value: '${company.stats.openTasks}',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Revizyon',
                    value: '${company.stats.openRevisions}',
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    label: 'Lisans',
                    value: formatOwnerDate(company.subscription.licenseEndsAt),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppPalette.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _CreateCompanyDialog extends StatefulWidget {
  const _CreateCompanyDialog();

  @override
  State<_CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<_CreateCompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _departmentController = TextEditingController(text: 'Yonetim');
  final _teamController = TextEditingController(text: 'Merkez Operasyon');
  final _supportEmailController = TextEditingController(
    text: 'kodver@gudeteknoloji.com.tr',
  );
  final _slaController = TextEditingController(text: '4 is saati');
  final _userLimitController = TextEditingController(text: '25');
  final _storageLimitController = TextEditingController(text: '50');

  String _timezone = 'Europe/Istanbul';
  String _locale = 'tr';
  String _planName = 'Scale';
  DateTime _licenseEndsAt = DateTime.now().add(const Duration(days: 30));
  bool _reports = true;
  bool _revisions = true;
  bool _automations = false;
  bool _requestForms = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _departmentController.dispose();
    _teamController.dispose();
    _supportEmailController.dispose();
    _slaController.dispose();
    _userLimitController.dispose();
    _storageLimitController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      OwnerCompanyDraft(
        companyName: _companyNameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        adminEmail: _adminEmailController.text.trim(),
        adminPassword: _adminPasswordController.text,
        departmentName: _departmentController.text.trim(),
        teamName: _teamController.text.trim(),
        timezone: _timezone,
        locale: _locale,
        planName: _planName,
        userLimit: int.parse(_userLimitController.text),
        storageLimitGb: int.parse(_storageLimitController.text),
        licenseEndsAt: _licenseEndsAt,
        supportEmail: _supportEmailController.text.trim(),
        responseSla: _slaController.text.trim(),
        modules: OwnerCompanyModules(
          reports: _reports,
          revisions: _revisions,
          automations: _automations,
          requestForms: _requestForms,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Yeni Sirket'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_companyNameController, 'Sirket adi'),
                const SizedBox(height: 12),
                _field(_adminNameController, 'Ilk admin adi'),
                const SizedBox(height: 12),
                _field(
                  _adminEmailController,
                  'Ilk admin e-posta',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _field(
                  _adminPasswordController,
                  'Gecici parola',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _field(_departmentController, 'Departman'),
                const SizedBox(height: 12),
                _field(_teamController, 'Takim'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _timezone,
                        decoration: const InputDecoration(
                          labelText: 'Saat dilimi',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Europe/Istanbul',
                            child: Text('Europe/Istanbul'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _timezone = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _planName,
                        decoration: const InputDecoration(labelText: 'Plan'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Scale',
                            child: Text('Scale'),
                          ),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _userLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kullanici limiti',
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _storageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Depolama GB',
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
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
                _field(
                  _supportEmailController,
                  'Destek e-posta',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _field(_slaController, 'SLA'),
                const SizedBox(height: 16),
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
        FilledButton(onPressed: _submit, child: const Text('Olustur')),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label gerekli.';
        }
        if (keyboardType == TextInputType.emailAddress &&
            !value.contains('@')) {
          return 'Gecerli bir e-posta girin.';
        }
        return null;
      },
    );
  }

  String? _numberValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Gecerli bir sayi girin.';
    }
    return null;
  }
}
