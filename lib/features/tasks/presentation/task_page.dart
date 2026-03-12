import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.user});

  final AppUser user;

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
    _controller = TaskController(user: widget.user);
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
        final selectedTask = _controller.selectedTask;
        final tasks = _controller.filteredTasks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TasksHeader(),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.summaryMetrics)
                  SizedBox(
                    width: 250,
                    child: _TaskMetricCard(metric: metric),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _TaskFilters(
              searchController: _searchController,
              statusFilter: _controller.statusFilter,
              priorityFilter: _controller.priorityFilter,
              dateFilter: _controller.dateFilter,
              assigneeFilter: _controller.assigneeFilter,
              tagFilter: _controller.tagFilter,
              assignees: _controller.assignees,
              tags: _controller.tags,
              onStatusChanged: _controller.updateStatusFilter,
              onPriorityChanged: _controller.updatePriorityFilter,
              onDateChanged: _controller.updateDateFilter,
              onAssigneeChanged: _controller.updateAssigneeFilter,
              onTagChanged: _controller.updateTagFilter,
              onClear: () {
                _searchController.clear();
                _controller.clearFilters();
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1140;
                final list = _TaskListPanel(
                  tasks: tasks,
                  selectedTaskId: selectedTask?.id,
                  onSelect: _controller.selectTask,
                );
                final detail = _TaskDetailPanel(
                  task: selectedTask,
                  commentController: _commentController,
                  onStart: () {
                    _controller.startSelectedTask();
                    _showFeedback('Görev başlatıldı.');
                  },
                  onComment: () {
                    final comment = _commentController.text.trim();
                    _controller.addComment(comment);
                    if (comment.isNotEmpty) {
                      _commentController.clear();
                      _showFeedback('Yorum göreve eklendi.');
                    }
                  },
                  onMeeting: () {
                    _controller.scheduleMeeting();
                    _showFeedback('Toplantı linki göreve eklendi.');
                  },
                  onSubmit: () {
                    _controller.submitSelectedTask();
                    _showFeedback('Görev incelemeye gönderildi.');
                  },
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: list),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: detail),
                    ],
                  );
                }

                return Column(
                  children: [
                    list,
                    const SizedBox(height: 16),
                    detail,
                  ],
                );
              },
            ),
          ],
        );
      },
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

class _TasksHeader extends StatelessWidget {
  const _TasksHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görevler',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kişi, durum, öncelik, tarih ve etiket filtreleriyle görev akışını yönet. Görev detay kartından başlat, yorum ekle, toplantı planla ve teslim et.',
          style: TextStyle(color: AppPalette.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _TaskMetricCard extends StatelessWidget {
  const _TaskMetricCard({required this.metric});

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
            color: Color(0x12051830),
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

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({
    required this.searchController,
    required this.statusFilter,
    required this.priorityFilter,
    required this.dateFilter,
    required this.assigneeFilter,
    required this.tagFilter,
    required this.assignees,
    required this.tags,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onDateChanged,
    required this.onAssigneeChanged,
    required this.onTagChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final TaskDateFilter dateFilter;
  final String? assigneeFilter;
  final String? tagFilter;
  final List<String> assignees;
  final List<String> tags;
  final ValueChanged<TaskStatus?> onStatusChanged;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final ValueChanged<TaskDateFilter> onDateChanged;
  final ValueChanged<String?> onAssigneeChanged;
  final ValueChanged<String?> onTagChanged;
  final VoidCallback onClear;

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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Görev / proje / etiket ara...',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppPalette.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppPalette.border),
                ),
              ),
            ),
          ),
          _FilterDropdown<TaskStatus?>(
            label: 'Durum',
            value: statusFilter,
            width: 170,
            items: const [null, ...TaskStatus.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: (value) => onStatusChanged(value),
          ),
          _FilterDropdown<TaskPriority?>(
            label: 'Öncelik',
            value: priorityFilter,
            width: 170,
            items: const [null, ...TaskPriority.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: (value) => onPriorityChanged(value),
          ),
          _FilterDropdown<TaskDateFilter>(
            label: 'Tarih',
            value: dateFilter,
            width: 170,
            items: TaskDateFilter.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => onDateChanged(value!),
          ),
          _FilterDropdown<String?>(
            label: 'Kişi',
            value: assigneeFilter,
            width: 170,
            items: [null, ...assignees],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: (value) => onAssigneeChanged(value),
          ),
          _FilterDropdown<String?>(
            label: 'Etiket',
            value: tagFilter,
            width: 170,
            items: [null, ...tags],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: (value) => onTagChanged(value),
          ),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Filtreleri Sıfırla'),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.width,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: AppPalette.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
        ),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
        ],
        onChanged: onChanged,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051830),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Görev Listesi',
            subtitle: 'Kişi, durum, öncelik, tarih ve etiket filtrelerine göre sonuçlar',
          ),
          const SizedBox(height: 18),
          if (tasks.isEmpty)
            const _EmptyState(
              title: 'Görev bulunamadı',
              message: 'Mevcut filtre kombinasyonuna uyan görev yok.',
            )
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TaskListTile(
                  task: task,
                  selected: task.id == selectedTaskId,
                  onTap: () => onSelect(task.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final TaskItem task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.primarySoft : AppPalette.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          task.title,
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${task.project} • ${task.assignee}',
                          style: const TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppPalette.primary,
                    ),
                ],
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
              const SizedBox(height: 10),
              Text(
                'Son teslim: ${_formatDate(task.dueAt)} • Güncelleme: ${_formatDateTime(task.updatedAt)}',
                style: const TextStyle(color: AppPalette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDetailPanel extends StatelessWidget {
  const _TaskDetailPanel({
    required this.task,
    required this.commentController,
    required this.onStart,
    required this.onComment,
    required this.onMeeting,
    required this.onSubmit,
  });

  final TaskItem? task;
  final TextEditingController commentController;
  final VoidCallback onStart;
  final VoidCallback onComment;
  final VoidCallback onMeeting;
  final VoidCallback onSubmit;

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
            color: Color(0x12051830),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: task == null
          ? const _EmptyState(
              title: 'Görev Detay Kartı',
              message: 'Detay görmek için soldaki listeden bir görev seç.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Görev Detay Kartı',
                  subtitle: 'Başlat, yorum ekle, toplantı planla ve teslim et',
                ),
                const SizedBox(height: 18),
                Text(
                  task!.title,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
                _InfoRow(
                  label: 'Güncelleme',
                  value: _formatDateTime(task!.updatedAt),
                ),
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
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Başlat'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onMeeting,
                      icon: const Icon(Icons.video_call_rounded),
                      label: const Text('Toplantı Başlat'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onSubmit,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toplantı Linki',
                          style: TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task!.meetingLink!,
                          style: const TextStyle(color: AppPalette.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: commentController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Yorum ekle',
                    hintText:
                        'Göreve not bırak, ilgililere bildirim gönderilsin.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onComment,
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Yorum Kaydet'),
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionHeader(
                  title: 'Son Hareketler',
                  subtitle: 'Görev akışında oluşan yorum, toplantı ve teslim kayıtları',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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
      ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppPalette.muted)),
        ],
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
