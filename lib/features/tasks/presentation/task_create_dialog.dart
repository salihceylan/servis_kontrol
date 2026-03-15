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

  late String _projectId;
  late String _assigneeId;
  TaskPriority _priority = TaskPriority.medium;
  late DateTime _dueAt;

  @override
  void initState() {
    super.initState();
    _projectId = widget.snapshot.projects.first.id;
    _assigneeId = widget.snapshot.assignees.first.id;
    _dueAt = _defaultDueAt(DateTime.now().add(const Duration(days: 1)));
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
      initialDate: _dueAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dueAt = _defaultDueAt(picked);
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

    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        projectId: _projectId,
        assigneeId: _assigneeId,
        priority: _priority,
        dueAt: _dueAt,
        estimatedMinutes: estimatedMinutes,
        tag: _tagController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Proje, atanan kisi, oncelik ve teslim tarihini belirleyerek yeni bir is kaydi ac.',
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
        width: 560,
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _projectId,
                        decoration: const InputDecoration(labelText: 'Proje'),
                        items: [
                          for (final project in widget.snapshot.projects)
                            DropdownMenuItem<String>(
                              value: project.id,
                              child: Text(project.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _projectId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _assigneeId,
                        decoration: const InputDecoration(
                          labelText: 'Atanan kisi',
                        ),
                        items: [
                          for (final assignee in widget.snapshot.assignees)
                            DropdownMenuItem<String>(
                              value: assignee.id,
                              child: Text(assignee.label),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(labelText: 'Oncelik'),
                        items: [
                          for (final priority in TaskPriority.values)
                            DropdownMenuItem<TaskPriority>(
                              value: priority,
                              child: Text(priority.label),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teslim tarihi',
                              style: TextStyle(
                                color: AppPalette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(_dueAt),
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Tarih sec'),
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

  DateTime _defaultDueAt(DateTime value) {
    return DateTime(value.year, value.month, value.day, 18);
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
