import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

Future<TeamMemberDraft?> showTeamMemberDialog(
  BuildContext context, {
  required List<ManagedTeam> teams,
  required List<TeamPermissionOption> permissionOptions,
  required List<TeamRoleOption> roleOptions,
  TeamMember? initial,
}) {
  return showDialog<TeamMemberDraft>(
    context: context,
    builder: (context) {
      return _TeamMemberDialog(
        teams: teams,
        permissionOptions: permissionOptions,
        roleOptions: roleOptions,
        initial: initial,
      );
    },
  );
}

class _TeamMemberDialog extends StatefulWidget {
  const _TeamMemberDialog({
    required this.teams,
    required this.permissionOptions,
    required this.roleOptions,
    this.initial,
  });

  final List<ManagedTeam> teams;
  final List<TeamPermissionOption> permissionOptions;
  final List<TeamRoleOption> roleOptions;
  final TeamMember? initial;

  @override
  State<_TeamMemberDialog> createState() => _TeamMemberDialogState();
}

class _TeamMemberDialogState extends State<_TeamMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _loginController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _departmentController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _workPreferenceController;

  late String _roleCode;
  late String _statusCode;
  String? _teamId;
  late Set<String> _permissionCodes;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _loginController = TextEditingController(text: initial?.loginName ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _passwordController = TextEditingController();
    _departmentController = TextEditingController(
      text: initial?.department ?? '',
    );
    _jobTitleController = TextEditingController(text: initial?.jobTitle ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _workPreferenceController = TextEditingController(
      text: initial?.workPreference ?? '',
    );
    _roleCode = initial?.roleCode ?? widget.roleOptions.first.code;
    _statusCode = initial?.statusCode ?? 'active';
    _teamId = initial?.teamId;
    _permissionCodes = {...(initial?.permissions ?? const <String>{})};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _workPreferenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TeamMemberDraft(
        name: _nameController.text,
        loginName: _loginController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text,
        roleCode: _roleCode,
        department: _departmentController.text,
        jobTitle: _jobTitleController.text,
        phone: _phoneController.text,
        teamId: _teamId,
        workPreference: _workPreferenceController.text,
        statusCode: _statusCode,
        permissionCodes: _permissionCodes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(_isEdit ? 'Calisani Duzenle' : 'Yeni Calisan'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad soyad'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad gerekli.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanici adi',
                        ),
                        validator: (value) {
                          final normalized = value?.trim() ?? '';
                          final valid = RegExp(r'^[A-Za-z0-9._-]+$');
                          if (normalized.isEmpty) {
                            return 'Kullanici adi gerekli.';
                          }
                          if (!valid.hasMatch(normalized)) {
                            return 'Sadece harf, rakam, nokta, alt tire ve tire kullan.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _isEdit
                              ? 'Yeni sifre (opsiyonel)'
                              : 'Sifre',
                        ),
                        validator: (value) {
                          final normalized = value?.trim() ?? '';
                          if (!_isEdit && normalized.isEmpty) {
                            return 'Sifre gerekli.';
                          }
                          if (normalized.isNotEmpty && normalized.length < 8) {
                            return 'En az 8 karakter gir.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta (opsiyonel)',
                    hintText: 'Bos birakirsan sistem teknik e-posta uretir',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _roleCode,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: [
                          for (final role in widget.roleOptions)
                            DropdownMenuItem<String>(
                              value: role.code,
                              child: Text(role.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _roleCode = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _statusCode,
                        decoration: const InputDecoration(labelText: 'Durum'),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Aktif'),
                          ),
                          DropdownMenuItem(
                            value: 'passive',
                            child: Text('Pasif'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _statusCode = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _teamId,
                  decoration: const InputDecoration(labelText: 'Takim'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Takim atama'),
                    ),
                    for (final team in widget.teams)
                      DropdownMenuItem<String?>(
                        value: team.id,
                        child: Text(team.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _teamId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Departman',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Gorev unvani',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _workPreferenceController,
                        decoration: const InputDecoration(
                          labelText: 'Calisma tercihi',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Yetkiler',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final option in widget.permissionOptions)
                      FilterChip(
                        selected: _permissionCodes.contains(option.code),
                        label: Text(option.label),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _permissionCodes.add(option.code);
                            } else {
                              _permissionCodes.remove(option.code);
                            }
                          });
                        },
                      ),
                  ],
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
          onPressed: _submit,
          child: Text(_isEdit ? 'Kaydet' : 'Calisani Olustur'),
        ),
      ],
    );
  }
}
