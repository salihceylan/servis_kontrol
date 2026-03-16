import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class TaskDetailPanel extends StatelessWidget {
  const TaskDetailPanel({
    super.key,
    required this.controller,
    required this.role,
    required this.task,
    required this.commentController,
    required this.onStart,
    required this.onComment,
    required this.onMeeting,
    required this.onSubmit,
  });

  final TaskController controller;
  final UserRole role;
  final TaskItem? task;
  final TextEditingController commentController;
  final Future<void> Function() onStart;
  final Future<void> Function() onComment;
  final Future<void> Function() onMeeting;
  final Future<void> Function() onSubmit;

  bool get _canStartAndSubmit => role == UserRole.employee;
  bool get _canScheduleMeeting => role != UserRole.employee;

  String get _subtitle => switch (role) {
    UserRole.employee =>
      'Yönetici kapsamını ve ekip planını gör, sahadaki ilerlemeyi kayıt altına al.',
    UserRole.teamLead =>
      'Manager kapsamını operasyon planına çevir, ekibi yönlendir ve teslimi takip et.',
    _ => 'Müşteri, saha ve ekip akışını tek görev kartında yönet.',
  };

  String get _workflowTitle => switch (role) {
    UserRole.employee => 'Saha ekibi akışı',
    UserRole.teamLead => 'Takım lideri akışı',
    _ => 'Manager akışı',
  };

  String get _workflowMessage => switch (role) {
    UserRole.employee =>
      'Çalışan bu kartta saha konumu, irtibat, beklenen çıktı ve ekip briefini görür; başlatırken çıkış notu, teslimde saha özeti ve harcanan süreyi girer.',
    UserRole.teamLead =>
      'Takım lideri managerın kapsamını operasyon planına çevirir, ekip için koordinasyon notu bırakır, toplantı açar ve teslim öncesi riskleri takip eder.',
    _ =>
      'Manager müşteri beklentisini, saha erişim bilgisini ve beklenen teslimi netleştirir; görev kapsamı ve önceliği bu karttan okunur.',
  };

  String get _commentLabel => switch (role) {
    UserRole.employee => 'Saha güncellemesi',
    UserRole.teamLead => 'Takım lideri koordinasyon notu',
    _ => 'Yönetici notu',
  };

  String get _commentHint => switch (role) {
    UserRole.employee =>
      'Ara durum, tespit veya sahadaki ek bilgiyi göreve kaydet.',
    UserRole.teamLead =>
      'Ekip yönlendirmesi, iş sırası veya operasyon takibini kaydet.',
    _ =>
      'Müşteri beklentisi, kapsam değişikliği veya öncelik yönlendirmesini kaydet.',
  };

  String get _commentButtonLabel => switch (role) {
    UserRole.employee => 'Saha Notu Kaydet',
    UserRole.teamLead => 'Koordinasyon Notu Kaydet',
    _ => 'Yönetici Notu Kaydet',
  };

  @override
  Widget build(BuildContext context) {
    final item = task;
    if (item == null) {
      return const StatePanel.empty(
        title: 'Görev detayı yok',
        message: 'Listeden bir görev seçildiğinde detay burada açılır.',
      );
    }

    return TaskPanelCard(
      title: 'Görev Detayı',
      subtitle: _subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskBadgeChip(
                label: item.status.label,
                color: statusColor(item.status),
              ),
              TaskBadgeChip(
                label: item.priority.label,
                color: priorityColor(item.priority),
              ),
              if (item.team.isNotEmpty)
                TaskBadgeChip(label: item.team, color: const Color(0xFF0A7F5A)),
              TaskBadgeChip(label: item.tag, color: const Color(0xFF7A7AE6)),
            ],
          ),
          const SizedBox(height: 18),
          _CalloutCard(title: _workflowTitle, message: _workflowMessage),
          const SizedBox(height: 18),
          Text(
            item.description.isEmpty
                ? 'İş tanımı girilmemiş.'
                : item.description,
            style: const TextStyle(color: AppPalette.muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Görev kodu', value: item.taskNo),
          _InfoRow(label: 'Proje', value: item.project),
          _InfoRow(
            label: 'Takım',
            value: item.team.isEmpty ? 'Takım bağlanmadı' : item.team,
          ),
          _InfoRow(label: 'Atanan', value: item.assignee),
          _InfoRow(
            label: 'Planlanan başlangıç',
            value: formatDateTimeOrFallback(item.plannedStartAt),
          ),
          _InfoRow(
            label: 'Son teslim',
            value: formatDateTimeOrFallback(item.dueAt),
          ),
          _InfoRow(label: 'Güncelleme', value: formatDateTime(item.updatedAt)),
          if (hasValue(item.requestSource))
            _InfoRow(label: 'Talep kaynağı', value: item.requestSource!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniStat(
                label: 'Kontrol',
                value: '${item.checklistCompleted}/${item.checklistTotal}',
              ),
              _MiniStat(
                label: 'Tahmini',
                value: formatMinutes(item.estimatedMinutes),
              ),
              _MiniStat(
                label: 'İzlenen',
                value: formatMinutes(item.trackedMinutes),
              ),
              _MiniStat(label: 'Alt iş', value: '${item.subtaskCount}'),
            ],
          ),
          if (_hasOperationalSection(item)) ...[
            const SizedBox(height: 18),
            _DetailSection(
              title: 'Saha ve iletişim',
              children: [
                if (hasValue(item.serviceLocation))
                  _DetailValueCard(
                    label: 'Saha konumu',
                    value: item.serviceLocation!,
                  ),
                if (hasValue(item.contactName))
                  _DetailValueCard(
                    label: 'İrtibat kişisi',
                    value: item.contactName!,
                  ),
                if (hasValue(item.contactPhone))
                  _DetailValueCard(
                    label: 'İrtibat telefonu',
                    value: item.contactPhone!,
                  ),
                if (hasValue(item.accessNotes))
                  _DetailValueCard(
                    label: 'Erişim / hazırlık notu',
                    value: item.accessNotes!,
                  ),
              ],
            ),
          ],
          if (_hasScopeSection(item)) ...[
            const SizedBox(height: 18),
            _DetailSection(
              title: 'Kapsam ve brief',
              children: [
                if (hasValue(item.expectedOutcome))
                  _DetailValueCard(
                    label: 'Beklenen çıktı',
                    value: item.expectedOutcome!,
                  ),
                if (hasValue(item.managerBrief))
                  _DetailValueCard(
                    label: 'Yönetici notu',
                    value: item.managerBrief!,
                  ),
                if (hasValue(item.leadBrief))
                  _DetailValueCard(
                    label: 'Takım lideri planı',
                    value: item.leadBrief!,
                  ),
              ],
            ),
          ],
          if (_hasFieldSection(item)) ...[
            const SizedBox(height: 18),
            _DetailSection(
              title: 'Saha çıktısı',
              children: [
                if (hasValue(item.fieldNotes))
                  _DetailValueCard(
                    label: 'Saha gözlemi',
                    value: item.fieldNotes!,
                  ),
                if (hasValue(item.completionSummary))
                  _DetailValueCard(
                    label: 'Teslim özeti',
                    value: item.completionSummary!,
                  ),
                if (hasValue(item.blockerNotes))
                  _DetailValueCard(
                    label: 'Risk / engel notu',
                    value: item.blockerNotes!,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_canStartAndSubmit)
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Göreve Çık'),
                ),
              if (_canScheduleMeeting)
                OutlinedButton.icon(
                  onPressed: controller.isSaving ? null : onMeeting,
                  icon: const Icon(Icons.video_call_rounded),
                  label: const Text('Toplantı Oluştur'),
                ),
              if (_canStartAndSubmit)
                OutlinedButton.icon(
                  onPressed: controller.isSaving ? null : onSubmit,
                  icon: const Icon(Icons.assignment_turned_in_rounded),
                  label: const Text('Teslim Et'),
                ),
            ],
          ),
          if (hasValue(item.meetingLink)) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.meetingLink!,
                style: const TextStyle(
                  color: AppPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: commentController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _commentLabel,
              hintText: _commentHint,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: controller.isSaving ? null : onComment,
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(_commentButtonLabel),
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              controller.errorMessage!,
              style: const TextStyle(
                color: AppPalette.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Son Hareketler',
            style: TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in item.timeline)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          formatDateTime(entry.timestamp),
                          style: const TextStyle(
                            color: AppPalette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.detail,
                      style: const TextStyle(
                        color: AppPalette.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.actor,
                      style: const TextStyle(
                        color: AppPalette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasOperationalSection(TaskItem item) =>
      hasValue(item.serviceLocation) ||
      hasValue(item.contactName) ||
      hasValue(item.contactPhone) ||
      hasValue(item.accessNotes);

  bool _hasScopeSection(TaskItem item) =>
      hasValue(item.expectedOutcome) ||
      hasValue(item.managerBrief) ||
      hasValue(item.leadBrief);

  bool _hasFieldSection(TaskItem item) =>
      hasValue(item.fieldNotes) ||
      hasValue(item.completionSummary) ||
      hasValue(item.blockerNotes);
}

class TaskPanelCard extends StatelessWidget {
  const TaskPanelCard({
    super.key,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 20,
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

class TaskBadgeChip extends StatelessWidget {
  const TaskBadgeChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(16),
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
            message,
            style: const TextStyle(color: AppPalette.text, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _DetailValueCard extends StatelessWidget {
  const _DetailValueCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.background,
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: AppPalette.text, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
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

Color statusColor(TaskStatus status) => switch (status) {
  TaskStatus.pending => AppPalette.warning,
  TaskStatus.inProgress => AppPalette.primary,
  TaskStatus.inReview => const Color(0xFF7A7AE6),
  TaskStatus.revision => AppPalette.danger,
  TaskStatus.delivered => AppPalette.success,
};

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => AppPalette.success,
  TaskPriority.medium => AppPalette.warning,
  TaskPriority.high => AppPalette.danger,
};

String formatMinutes(int minutes) {
  if (minutes <= 0) return 'Kayıt yok';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '$remainingMinutes dk';
  return '${hours}s ${remainingMinutes}dk';
}

String formatDate(DateTime? value) {
  if (value == null) return 'Planlanmadı';
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

String formatDateTime(DateTime value) {
  return '${formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String formatDateTimeOrFallback(DateTime? value) {
  if (value == null) return 'Planlanmadı';
  return formatDateTime(value);
}

bool hasValue(String? value) => value != null && value.trim().isNotEmpty;
