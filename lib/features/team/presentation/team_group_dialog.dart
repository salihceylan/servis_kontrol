import 'package:flutter/material.dart';
import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

Future<TeamGroupDraft?> showTeamGroupDialog(
  BuildContext context, {
  required List<TeamMember> members,
  ManagedTeam? initial,
}) {
  return showDialog<TeamGroupDraft>(
    context: context,
    builder: (context) => _TeamGroupDialog(members: members, initial: initial),
  );
}

class _TeamGroupDialog extends StatefulWidget {
  const _TeamGroupDialog({required this.members, this.initial});

  final List<TeamMember> members;
  final ManagedTeam? initial;

  @override
  State<_TeamGroupDialog> createState() => _TeamGroupDialogState();
}

class _TeamGroupDialogState extends State<_TeamGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _managerUserId;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _managerUserId = widget.initial?.managerUserId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      TeamGroupDraft(name: _nameController.text, managerUserId: _managerUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Takımi Düzenle' : 'Yeni Takım'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Takım adı'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Takım adı gerekli.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _managerUserId,
                decoration: const InputDecoration(labelText: 'Takım sorumlusu'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Takım sorumlusu atama'),
                  ),
                  for (final member in widget.members)
                    DropdownMenuItem<String?>(
                      value: member.id,
                      child: Text('${member.name} - ${member.role}'),
                    ),
                ],
                onChanged: (value) => setState(() => _managerUserId = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Kaydet' : 'Takımi Oluştur'),
        ),
      ],
    );
  }
}
