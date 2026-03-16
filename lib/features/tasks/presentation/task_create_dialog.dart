import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

Future<TaskDraft?> showTaskCreateDialog(
  BuildContext context, {
  required TaskComposerSnapshot snapshot,
  required UserRole role,
}) {
  return showDialog<TaskDraft>(
    context: context,
    builder: (context) => _TaskCreateDialog(snapshot: snapshot, role: role),
  );
}

class _TaskCreateDialog extends StatefulWidget {
  const _TaskCreateDialog({required this.snapshot, required this.role});

  final TaskComposerSnapshot snapshot;
  final UserRole role;

  @override
  State<_TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<_TaskCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateController = TextEditingController();
  final _tagController = TextEditingController();
  final _serviceLocationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _accessNotesController = TextEditingController();
  final _expectedOutcomeController = TextEditingController();
  final _managerBriefController = TextEditingController();
  final _leadBriefController = TextEditingController();

  String? _teamId;
  String? _projectId;
  late String _assigneeId;
  TaskPriority _priority = TaskPriority.medium;
  bool _hasPlannedStart = false;
  late DateTime _plannedStartDate;
  late TimeOfDay _plannedStartTime;
  bool _hasDueDate = true;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;

  bool get _showsManagerBrief => widget.role == UserRole.manager;

  String get _title => switch (widget.role) {
    UserRole.teamLead => 'Takıma Görev Ata',
    _ => 'Yeni Görev',
  };

  String get _subtitle => switch (widget.role) {
    UserRole.manager =>
      'Müşteri, saha ve teslim beklentisini netleştirerek ekip için görev aç.',
    UserRole.teamLead =>
      'Ekibine görev ata, operasyon planını gir ve sahaya net brief bırak.',
    _ => 'Görev kapsamını, atamayı ve planlamayı kaydederek yeni kayıt aç.',
  };

  List<TaskFormOption> get _visibleProjects {
    if (_teamId == null || _teamId!.isEmpty) {
      return widget.snapshot.projects;
    }
    return widget.snapshot.projects
        .where(
          (project) => project.groupId == null || project.groupId == _teamId,
        )
        .toList(growable: false);
  }

  List<TaskFormOption> get _visibleAssignees {
    if (_teamId == null || _teamId!.isEmpty) {
      return widget.snapshot.assignees;
    }
    return widget.snapshot.assignees
        .where((assignee) => assignee.groupId == _teamId)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _teamId = widget.snapshot.teams.isNotEmpty
        ? widget.snapshot.teams.first.id
        : null;
    _projectId = _visibleProjects.isNotEmpty ? _visibleProjects.first.id : null;
    _assigneeId = _visibleAssignees.isNotEmpty
        ? _visibleAssignees.first.id
        : widget.snapshot.assignees.first.id;
    _plannedStartDate = DateTime.now().add(const Duration(hours: 4));
    _plannedStartTime = const TimeOfDay(hour: 9, minute: 0);
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _dueTime = const TimeOfDay(hour: 18, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimateController.dispose();
    _tagController.dispose();
    _serviceLocationController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _accessNotesController.dispose();
    _expectedOutcomeController.dispose();
    _managerBriefController.dispose();
    _leadBriefController.dispose();
    super.dispose();
  }

  Future<void> _pickPlannedStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _plannedStartDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _plannedStartTime.hour,
        _plannedStartTime.minute,
      );
    });
  }

  Future<void> _pickPlannedStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _plannedStartTime,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _plannedStartTime = picked;
      _plannedStartDate = DateTime(
        _plannedStartDate.year,
        _plannedStartDate.month,
        _plannedStartDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueTime.hour,
        _dueTime.minute,
      );
    });
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dueTime = picked;
      _dueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _handleTeamChanged(String? value) {
    setState(() {
      _teamId = value;
      final visibleProjects = _visibleProjects;
      if (visibleProjects.every((item) => item.id != _projectId)) {
        _projectId = visibleProjects.isNotEmpty
            ? visibleProjects.first.id
            : null;
      }
      final visibleAssignees = _visibleAssignees;
      if (visibleAssignees.every((item) => item.id != _assigneeId)) {
        _assigneeId = visibleAssignees.isNotEmpty
            ? visibleAssignees.first.id
            : widget.snapshot.assignees.first.id;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final estimateText = _estimateController.text.trim();
    final estimatedMinutes = estimateText.isEmpty
        ? null
        : int.parse(estimateText);

    final plannedStartAt = _hasPlannedStart
        ? DateTime(
            _plannedStartDate.year,
            _plannedStartDate.month,
            _plannedStartDate.day,
            _plannedStartTime.hour,
            _plannedStartTime.minute,
          )
        : null;

    final dueAt = _hasDueDate
        ? DateTime(
            _dueDate.year,
            _dueDate.month,
            _dueDate.day,
            _dueTime.hour,
            _dueTime.minute,
          )
        : null;

    if (plannedStartAt != null &&
        dueAt != null &&
        dueAt.isBefore(plannedStartAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Son teslim tarihi planlanan başlangıçtan önce olamaz.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        projectId: _projectId,
        teamId: _teamId,
        assigneeId: _assigneeId,
        priority: _priority,
        plannedStartAt: plannedStartAt,
        dueAt: dueAt,
        estimatedMinutes: estimatedMinutes,
        tag: _tagController.text,
        serviceLocation: _serviceLocationController.text,
        contactName: _contactNameController.text,
        contactPhone: _contactPhoneController.text,
        accessNotes: _accessNotesController.text,
        expectedOutcome: _expectedOutcomeController.text,
        managerBrief: _showsManagerBrief ? _managerBriefController.text : null,
        leadBrief: _leadBriefController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProjects = _visibleProjects;
    final visibleAssignees = _visibleAssignees;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: const TextStyle(
              color: AppPalette.muted,
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Görev başlığı',
                    hintText: 'Örnek: Saha bakım kontrolünü tamamla',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Başlık gerekli.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'İş tanımı',
                    hintText:
                        'Görevin kapsamını, teslim beklentisini ve kritik notları yaz.',
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Atama ve öncelik',
                  subtitle:
                      'Görev hangi takıma ve çalışana gidecek, ne kadar sürecek?',
                  child: Column(
                    children: [
                      if (widget.snapshot.teams.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _teamId,
                          decoration: const InputDecoration(labelText: 'Takım'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Takım seçmeden devam et'),
                            ),
                            for (final team in widget.snapshot.teams)
                              DropdownMenuItem<String?>(
                                value: team.id,
                                child: Text(
                                  team.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _handleTeamChanged,
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              initialValue: _projectId,
                              decoration: const InputDecoration(
                                labelText: 'Proje',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Proje bağlama'),
                                ),
                                for (final project in visibleProjects)
                                  DropdownMenuItem<String?>(
                                    value: project.id,
                                    child: Text(
                                      project.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _projectId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _assigneeId,
                              decoration: const InputDecoration(
                                labelText: 'Atanan kişi',
                              ),
                              items: [
                                for (final assignee in visibleAssignees)
                                  DropdownMenuItem<String>(
                                    value: assignee.id,
                                    child: Text(
                                      assignee.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _assigneeId = value;
                                });
                              },
                              validator: (_) {
                                if (visibleAssignees.isEmpty) {
                                  return 'Seçili takım için atanabilir kullanıcı yok.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              isExpanded: true,
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Öncelik',
                              ),
                              items: [
                                for (final priority in TaskPriority.values)
                                  DropdownMenuItem<TaskPriority>(
                                    value: priority,
                                    child: Text(
                                      priority.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _priority = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _estimateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tahmini süre (dk)',
                                hintText: '90',
                              ),
                              validator: (value) {
                                final normalized = value?.trim() ?? '';
                                if (normalized.isEmpty) {
                                  return null;
                                }
                                final estimate = int.tryParse(normalized);
                                if (estimate == null || estimate <= 0) {
                                  return 'Dakika olarak sayı gir.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori / etiket',
                          hintText: 'Bakım, Revizyon, Saha, Kontrol',
                        ),
                      ),
                      if (widget.snapshot.tagSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag
                                in widget.snapshot.tagSuggestions.take(8))
                              ActionChip(
                                label: Text(tag),
                                onPressed: () {
                                  _tagController.text = tag;
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Saha ve iletişim bilgisi',
                  subtitle:
                      'Göreve gidecek ekip için lokasyon, irtibat ve erişim bilgisini yaz.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _serviceLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Servis / saha konumu',
                          hintText: 'Örnek: Merkez Plaza B blok çatı katı',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(
                                labelText: 'Saha irtibat kişisi',
                                hintText: 'Salih Ceylan',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'İrtibat telefonu',
                                hintText: '0555 000 00 00',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _accessNotesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Erişim / hazırlık notu',
                          hintText:
                              'Kapı kodu, güvenlik bilgisi, ekipman gereksinimi gibi sahaya çıkış notları.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Hedef ve brief',
                  subtitle:
                      'Manager kapsamı ve teslim beklentisini, takım lideri operasyon planını bırakır.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _expectedOutcomeController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Beklenen çıktı',
                          hintText:
                              'Görev sonunda hangi teslimin veya sonucun çıkması gerektiğini yaz.',
                        ),
                      ),
                      if (_showsManagerBrief) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _managerBriefController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Yönetici notu',
                            hintText:
                                'Müşteri beklentisi, dikkat edilmesi gereken kritik nokta veya öncelik bilgisi.',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _leadBriefController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: widget.role == UserRole.teamLead
                              ? 'Takım lideri planı'
                              : 'Takım liderine brief',
                          hintText: widget.role == UserRole.teamLead
                              ? 'Ekibin çalışma sırasını, kontrol listesini ve hazırlık planını yaz.'
                              : 'Takım liderine aktarılacak operasyon notunu yaz.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Takvim',
                  subtitle:
                      'İstersen planlanan başlangıç ve son teslim tarihini saatli olarak gir.',
                  child: Column(
                    children: [
                      _ScheduleBlock(
                        title: 'Planlanan başlangıç',
                        value: _hasPlannedStart,
                        onChanged: (value) {
                          setState(() {
                            _hasPlannedStart = value;
                          });
                        },
                        dateLabel: _formatDate(_plannedStartDate),
                        timeLabel: _plannedStartTime.format(context),
                        onPickDate: _pickPlannedStartDate,
                        onPickTime: _pickPlannedStartTime,
                      ),
                      const SizedBox(height: 14),
                      _ScheduleBlock(
                        title: 'Son teslim tarihi',
                        value: _hasDueDate,
                        onChanged: (value) {
                          setState(() {
                            _hasDueDate = value;
                          });
                        },
                        dateLabel: _formatDate(_dueDate),
                        timeLabel: _dueTime.format(context),
                        onPickDate: _pickDueDate,
                        onPickTime: _pickDueTime,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Görevi Oluştur'),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, color: AppPalette.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
          if (value) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateActionCard(
                    title: 'Tarih',
                    value: dateLabel,
                    icon: Icons.calendar_today_outlined,
                    onPressed: onPickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateActionCard(
                    title: 'Saat',
                    value: timeLabel,
                    icon: Icons.schedule_rounded,
                    onPressed: onPickTime,
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

class _DateActionCard extends StatelessWidget {
  const _DateActionCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
