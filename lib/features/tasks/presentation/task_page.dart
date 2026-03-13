import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({
    super.key,
    required this.user,
    required this.apiClient,
  });

  final AppUser user;
  final ApiClient apiClient;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late final TaskController _controller;
  final _searchController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TaskController(user: widget.user, apiClient: widget.apiClient);
    _searchController.addListener(() {
      _controller.updateQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const StatePanel.loading(
            title: 'Görevler yükleniyor',
            message: 'Şirket görev kayıtları ve detayları sunucudan alınıyor.',
          );
        }
        if (_controller.errorMessage != null && !_controller.hasData) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }
        if (!_controller.hasData) {
          return StatePanel.empty(
            title: 'Görev kaydı bulunamadı',
            message:
                'Veritabanında bu kullanıcı için henüz görev görünmüyor.',
            onRetry: _controller.load,
          );
        }

        final selectedTask = _controller.selectedTask;
        final tasks = _controller.filteredTasks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              title: 'Görevler',
              subtitle:
                  'Gerçek görev kayıtlarını filtrele, detay aç ve aksiyonları doğrudan veritabanına işle.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.summaryMetrics)
                  SizedBox(
                    width: 250,
                    child: _MetricCard(metric: metric),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _FiltersCard(
              searchController: _searchController,
              controller: _controller,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final listPanel = _TaskListPanel(
                  tasks: tasks,
                  selectedTaskId: selectedTask?.id,
                  onSelect: _controller.selectTask,
                );
                final detailPanel = _TaskDetailPanel(
                  controller: _controller,
                  task: selectedTask,
                  commentController: _commentController,
                  onStart: _startTask,
                  onComment: _saveComment,
                  onMeeting: _createMeeting,
                  onSubmit: _submitTask,
                );

                if (!wide) {
                  return Column(
                    children: [
                      listPanel,
                      const SizedBox(height: 16),
                      detailPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: listPanel),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: detailPanel),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startTask() async {
    final success = await _controller.startSelectedTask();
    _showFeedback(
      success
          ? 'Görev başlatıldı.'
          : (_controller.errorMessage ?? 'Görev başlatılamadı.'),
    );
  }

  Future<void> _saveComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      return;
    }
    final success = await _controller.addComment(comment);
    if (success) {
      _commentController.clear();
    }
    _showFeedback(
      success
          ? 'Yorum göreve eklendi.'
          : (_controller.errorMessage ?? 'Yorum kaydedilemedi.'),
    );
  }

  Future<void> _createMeeting() async {
    final success = await _controller.scheduleMeeting();
    _showFeedback(
      success
          ? 'Toplantı bağlantısı oluşturuldu.'
          : (_controller.errorMessage ?? 'Toplantı bağlantısı oluşturulamadı.'),
    );
  }

  Future<void> _submitTask() async {
    final success = await _controller.submitSelectedTask();
    _showFeedback(
      success
          ? 'Görev incelemeye gönderildi.'
          : (_controller.errorMessage ?? 'Görev teslim edilemedi.'),
    );
  }

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final TaskSummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            metric.label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.caption,
            style: const TextStyle(color: AppPalette.muted),
          ),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.controller,
  });

  final TextEditingController searchController;
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Görev, proje veya etiket ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          _Dropdown<TaskStatus?>(
            label: 'Durum',
            value: controller.statusFilter,
            items: const [null, ...TaskStatus.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: controller.updateStatusFilter,
          ),
          _Dropdown<TaskPriority?>(
            label: 'Öncelik',
            value: controller.priorityFilter,
            items: const [null, ...TaskPriority.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: controller.updatePriorityFilter,
          ),
          _Dropdown<TaskDateFilter>(
            label: 'Tarih',
            value: controller.dateFilter,
            items: TaskDateFilter.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => controller.updateDateFilter(value!),
          ),
          _Dropdown<String?>(
            label: 'Kişi',
            value: controller.assigneeFilter,
            items: [null, ...controller.assignees],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateAssigneeFilter,
          ),
          _Dropdown<String?>(
            label: 'Etiket',
            value: controller.tagFilter,
            items: [null, ...controller.tags],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateTagFilter,
          ),
          OutlinedButton.icon(
            onPressed: () {
              searchController.clear();
              controller.clearFilters();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Filtreleri Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _TaskListPanel extends StatelessWidget {
  const _TaskListPanel({
    required this.tasks,
    required this.selectedTaskId,
    required this.onSelect,
  });

  final List<TaskItem> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Görev Listesi',
      subtitle: 'Seçilen kayıt sağdaki detay kartında açılır.',
      child: Column(
        children: [
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: task.id == selectedTaskId
                    ? AppPalette.primarySoft
                    : AppPalette.background,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => onSelect(task.id),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${task.project} • ${task.assignee}',
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _BadgeChip(label: task.status.label, color: _statusColor(task.status)),
                            _BadgeChip(label: task.priority.label, color: _priorityColor(task.priority)),
                            _BadgeChip(label: task.tag, color: const Color(0xFF7A7AE6)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: task.progress,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppPalette.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskDetailPanel extends StatelessWidget {
  const _TaskDetailPanel({
    required this.controller,
    required this.task,
    required this.commentController,
    required this.onStart,
    required this.onComment,
    required this.onMeeting,
    required this.onSubmit,
  });

  final TaskController controller;
  final TaskItem? task;
  final TextEditingController commentController;
  final Future<void> Function() onStart;
  final Future<void> Function() onComment;
  final Future<void> Function() onMeeting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return const StatePanel.empty(
        title: 'Görev detayı yok',
        message: 'Listeden bir görev seçildiğinde detay burada açılır.',
      );
    }

    return _SectionCard(
      title: 'Görev Detayı',
      subtitle: 'Başlat, yorum ekle, toplantı planla ve teslim et.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task!.title,
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
              _BadgeChip(label: task!.status.label, color: _statusColor(task!.status)),
              _BadgeChip(label: task!.priority.label, color: _priorityColor(task!.priority)),
              _BadgeChip(label: task!.tag, color: const Color(0xFF7A7AE6)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            task!.description,
            style: const TextStyle(color: AppPalette.muted, height: 1.6),
          ),
          const SizedBox(height: 18),
          _InfoRow(label: 'Proje', value: task!.project),
          _InfoRow(label: 'Atanan', value: task!.assignee),
          _InfoRow(label: 'Son teslim', value: _formatDate(task!.dueAt)),
          _InfoRow(label: 'Güncelleme', value: _formatDateTime(task!.updatedAt)),
          if (task!.requestSource != null && task!.requestSource!.isNotEmpty)
            _InfoRow(label: 'Talep kaynağı', value: task!.requestSource!),
          const SizedBox(height: 14),
          Text(
            'Kontrol ilerlemesi ${task!.checklistCompleted}/${task!.checklistTotal}',
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: task!.progress,
              minHeight: 10,
              backgroundColor: AppPalette.primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(AppPalette.primary),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatBlock(
                label: 'Tahmini süre',
                value: _formatMinutes(task!.estimatedMinutes),
              ),
              _StatBlock(
                label: 'İzlenen süre',
                value: _formatMinutes(task!.trackedMinutes),
              ),
              _StatBlock(
                label: 'Bağımlılık',
                value: '${task!.blockedByCount}',
              ),
              _StatBlock(
                label: 'Alt iş',
                value: '${task!.subtaskCount}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: controller.isSaving ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Başlat'),
              ),
              OutlinedButton.icon(
                onPressed: controller.isSaving ? null : onMeeting,
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Toplantı Oluştur'),
              ),
              OutlinedButton.icon(
                onPressed: controller.isSaving ? null : onSubmit,
                icon: const Icon(Icons.assignment_turned_in_rounded),
                label: const Text('Teslim Et'),
              ),
            ],
          ),
          if (task!.meetingLink != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                task!.meetingLink!,
                style: const TextStyle(
                  color: AppPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (task!.dependencies.isNotEmpty) ...[
            const Text(
              'Bağımlılıklar',
              style: TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            for (final dependency in task!.dependencies)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppPalette.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dependency.title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        dependency.statusLabel,
                        style: const TextStyle(
                          color: AppPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
          if (task!.timeEntries.isNotEmpty) ...[
            const Text(
              'Zaman Kayıtları',
              style: TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in task!.timeEntries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.userName,
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.startedAtLabel,
                              style: const TextStyle(color: AppPalette.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        entry.durationLabel,
                        style: const TextStyle(
                          color: AppPalette.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],
          TextField(
            controller: commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Yorum ekle',
              hintText: 'Göreve not bırak ve kaydet.',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: controller.isSaving ? null : onComment,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Yorum Kaydet'),
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
          const SizedBox(height: 14),
          for (final entry in task!.timeline)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                          _formatDateTime(entry.timestamp),
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

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
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
            width: 110,
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

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});

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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(TaskStatus status) => switch (status) {
  TaskStatus.pending => AppPalette.warning,
  TaskStatus.inProgress => AppPalette.primary,
  TaskStatus.inReview => const Color(0xFF7A7AE6),
  TaskStatus.revision => AppPalette.danger,
  TaskStatus.delivered => AppPalette.success,
};

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => AppPalette.success,
  TaskPriority.medium => AppPalette.warning,
  TaskPriority.high => AppPalette.danger,
};

String _formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) {
    return '$remainingMinutes dk';
  }
  return '${hours}s ${remainingMinutes}dk';
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
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]}';
}

String _formatDateTime(DateTime value) {
  return '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
