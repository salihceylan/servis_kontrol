import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

Future<TaskDraft?> showTaskCreateDialog(
  BuildContext context, {
  required TaskComposerSnapshot snapshot,
}) {
  return showDialog<TaskDraft>(
    context: context,
    builder: (context) => _TaskCreateDialog(snapshot: snapshot),
  );
}

class _TaskCreateDialog extends StatefulWidget {
  const _TaskCreateDialog({required this.snapshot});

  final TaskComposerSnapshot snapshot;

  @override
  State<_TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends State<_TaskCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateController = TextEditingController();
  final _tagController = TextEditingController();

  String? _teamId;
  String? _projectId;
  late String _assigneeId;
  TaskPriority _priority = TaskPriority.medium;
  bool _hasDueDate = true;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;

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
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _dueTime = const TimeOfDay(hour: 18, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimateController.dispose();
    _tagController.dispose();
    super.dispose();
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

    final dueAt = _hasDueDate
        ? DateTime(
            _dueDate.year,
            _dueDate.month,
            _dueDate.day,
            _dueTime.hour,
            _dueTime.minute,
          )
        : null;

    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        projectId: _projectId,
        teamId: _teamId,
        assigneeId: _assigneeId,
        priority: _priority,
        dueAt: dueAt,
        estimatedMinutes: estimatedMinutes,
        tag: _tagController.text,
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yeni Gorev',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Takim, atanan kisi, oncelik ve istenirse teslim tarihi belirleyerek yeni kayit ac.',
            style: TextStyle(
              color: AppPalette.muted,
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
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
                    labelText: 'Gorev basligi',
                    hintText: 'Ornek: Saha kontrol listesini tamamla',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Baslik gerekli.';
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
                    labelText: 'Aciklama',
                    hintText: 'Gorevin detayini ve beklenen ciktiyi yaz.',
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.snapshot.teams.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _teamId,
                    decoration: const InputDecoration(labelText: 'Takim'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Takim secmeden devam et'),
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
                if (widget.snapshot.teams.isNotEmpty)
                  const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _projectId,
                        decoration: const InputDecoration(labelText: 'Proje'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Proje baglama'),
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
                          labelText: 'Atanan kisi',
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
                            return 'Secili takim icin atanabilir kullanici yok.';
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
                        decoration: const InputDecoration(labelText: 'Oncelik'),
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
                          labelText: 'Tahmini sure (dk)',
                          hintText: '90',
                        ),
                        validator: (value) {
                          final normalized = value?.trim() ?? '';
                          if (normalized.isEmpty) {
                            return null;
                          }
                          final estimate = int.tryParse(normalized);
                          if (estimate == null || estimate <= 0) {
                            return 'Dakika olarak sayi gir.';
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
                    labelText: 'Etiket',
                    hintText: 'Kontrol, Revizyon, Saha',
                  ),
                ),
                if (widget.snapshot.tagSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in widget.snapshot.tagSuggestions.take(8))
                        ActionChip(
                          label: Text(tag),
                          onPressed: () {
                            _tagController.text = tag;
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            color: AppPalette.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Son teslim tarihi kullan',
                              style: TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _hasDueDate,
                            onChanged: (value) {
                              setState(() {
                                _hasDueDate = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_hasDueDate) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DueCard(
                                title: 'Tarih',
                                value: _formatDate(_dueDate),
                                icon: Icons.calendar_today_outlined,
                                onPressed: _pickDueDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DueCard(
                                title: 'Saat',
                                value: _dueTime.format(context),
                                icon: Icons.schedule_rounded,
                                onPressed: _pickDueTime,
                              ),
                            ),
                          ],
                        ),
                      ],
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
          child: const Text('Vazgec'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Gorevi Olustur'),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Oca',
      'Sub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Agu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({
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
