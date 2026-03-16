import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';

Future<TaskStartDraft?> showTaskStartDialog(BuildContext context) {
  return showDialog<TaskStartDraft>(
    context: context,
    builder: (context) => const _TaskStartDialog(),
  );
}

Future<TaskSubmissionDraft?> showTaskSubmitDialog(BuildContext context) {
  return showDialog<TaskSubmissionDraft>(
    context: context,
    builder: (context) => const _TaskSubmitDialog(),
  );
}

class _TaskStartDialog extends StatefulWidget {
  const _TaskStartDialog();

  @override
  State<_TaskStartDialog> createState() => _TaskStartDialogState();
}

class _TaskStartDialogState extends State<_TaskStartDialog> {
  final _startNoteController = TextEditingController();

  @override
  void dispose() {
    _startNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Görevi Başlat',
        style: TextStyle(color: AppPalette.text, fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _startNoteController,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Çıkış / hazırlık notu',
          hintText:
              'Sahaya çıkış saati, hazırlık durumu veya ekip için ilk notunu yaz.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(TaskStartDraft(startNote: _startNoteController.text));
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Başlat'),
        ),
      ],
    );
  }
}

class _TaskSubmitDialog extends StatefulWidget {
  const _TaskSubmitDialog();

  @override
  State<_TaskSubmitDialog> createState() => _TaskSubmitDialogState();
}

class _TaskSubmitDialogState extends State<_TaskSubmitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _completionSummaryController = TextEditingController();
  final _fieldNotesController = TextEditingController();
  final _blockerNotesController = TextEditingController();
  final _actualMinutesController = TextEditingController();

  @override
  void dispose() {
    _completionSummaryController.dispose();
    _fieldNotesController.dispose();
    _blockerNotesController.dispose();
    _actualMinutesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final actualMinutesText = _actualMinutesController.text.trim();
    final actualMinutes = actualMinutesText.isEmpty
        ? null
        : int.parse(actualMinutesText);

    Navigator.of(context).pop(
      TaskSubmissionDraft(
        completionSummary: _completionSummaryController.text,
        fieldNotes: _fieldNotesController.text,
        blockerNotes: _blockerNotesController.text,
        actualMinutes: actualMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Teslim Özeti',
        style: TextStyle(color: AppPalette.text, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _completionSummaryController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Teslim özeti',
                    hintText:
                        'Sahada ne yapıldığını ve hangi sonucun çıktığını net şekilde yaz.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Teslim özeti gerekli.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fieldNotesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Saha gözlemi',
                    hintText:
                        'Tespit edilen durumlar, ölçümler veya dikkat çeken saha bilgileri.',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _blockerNotesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Risk / engel notu',
                    hintText:
                        'Tamamlanamayan kısım, takip ihtiyacı veya sahadaki engeli yaz.',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _actualMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harcanan süre (dk)',
                    hintText: '120',
                  ),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    if (normalized.isEmpty) {
                      return null;
                    }
                    final minutes = int.tryParse(normalized);
                    if (minutes == null || minutes <= 0) {
                      return 'Dakika olarak sayı gir.';
                    }
                    return null;
                  },
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
          icon: const Icon(Icons.assignment_turned_in_rounded),
          label: const Text('İncelemeye Gönder'),
        ),
      ],
    );
  }
}
