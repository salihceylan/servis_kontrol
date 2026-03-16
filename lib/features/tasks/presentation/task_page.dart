import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_action_dialogs.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_create_dialog.dart';
import 'package:servis_kontrol/features/tasks/presentation/task_detail_panel.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.user, required this.apiClient});

  final AppUser user;
  final ApiClient apiClient;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late final TaskController _controller;
  final _searchController = TextEditingController();
  final _commentController = TextEditingController();

  UserRole get _role => widget.user.role;

  String get _pageTitle => switch (_role) {
    UserRole.employee => 'Görevlerim',
    UserRole.teamLead => 'Takım Görevleri',
    _ => 'Görevler',
  };

  String get _pageSubtitle => switch (_role) {
    UserRole.employee =>
      'Üzerine atanan işleri takip et, sahadaki ilerlemeyi kaydet ve teslim sürecini yönet.',
    UserRole.teamLead =>
      'Ekibinin görevlerini filtrele, operasyon planını yönlendir ve saha akışını kontrol et.',
    _ =>
      'Gerçek görev kayıtlarını filtrele, kapsamı netleştir ve ekipler arası dağıtımı doğrudan veritabanına işle.',
  };

  String get _emptyTaskMessage => switch (_role) {
    UserRole.employee => 'Veritabanında sana atanmış görünen bir görev yok.',
    UserRole.teamLead => 'Ekibin için görünen bir görev kaydı yok.',
    _ => 'Veritabanında bu kullanıcı için henüz görünen bir görev yok.',
  };

  String get _createActionLabel => switch (_role) {
    UserRole.teamLead => 'Takıma Görev Ata',
    _ => 'Yeni Görev',
  };

  TaskCommentKind get _commentKind => switch (_role) {
    UserRole.manager => TaskCommentKind.managerNote,
    UserRole.teamLead => TaskCommentKind.coordination,
    UserRole.employee => TaskCommentKind.fieldUpdate,
    _ => TaskCommentKind.comment,
  };

  String get _commentSuccessMessage => switch (_role) {
    UserRole.manager => 'Yönetici notu kaydedildi.',
    UserRole.teamLead => 'Takım lideri koordinasyon notu kaydedildi.',
    UserRole.employee => 'Saha güncellemesi kaydedildi.',
    _ => 'Yorum göreve eklendi.',
  };

  @override
  void initState() {
    super.initState();
    _controller = TaskController(
      user: widget.user,
      apiClient: widget.apiClient,
    );
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
          return StatePanel.loading(
            title: 'Görevler yükleniyor',
            message: _pageSubtitle,
          );
        }
        if (_controller.errorMessage != null && !_controller.hasData) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }

        final action = _controller.canCreateTask
            ? FilledButton.icon(
                onPressed:
                    (_controller.isSaving || _controller.isPreparingComposer)
                    ? null
                    : _createTask,
                icon: const Icon(Icons.add_task_rounded),
                label: Text(
                  _controller.isPreparingComposer
                      ? 'Hazırlanıyor...'
                      : _createActionLabel,
                ),
              )
            : null;

        if (!_controller.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                title: _pageTitle,
                subtitle: _pageSubtitle,
                action: action,
              ),
              const SizedBox(height: 18),
              StatePanel.empty(
                title: 'Görev kaydı bulunamadı',
                message: _emptyTaskMessage,
                onRetry: _controller.load,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: _pageTitle,
              subtitle: _pageSubtitle,
              action: action,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in _controller.summaryMetrics)
                  SizedBox(width: 240, child: _MetricCard(metric: metric)),
              ],
            ),
            const SizedBox(height: 18),
            _FilterCard(
              controller: _controller,
              searchController: _searchController,
              onCreate: _controller.canCreateTask ? _createTask : null,
              createLabel: _createActionLabel,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1140;
                final selectedTask = _controller.selectedTask;
                final listPanel = _TaskListPanel(
                  tasks: _controller.filteredTasks,
                  selectedTaskId: selectedTask?.id,
                  onSelect: compact
                      ? _openTaskDetailSheet
                      : _controller.selectTask,
                  opensDetailSheet: compact,
                );
                final detailPanel = TaskDetailPanel(
                  controller: _controller,
                  role: _role,
                  task: selectedTask,
                  commentController: _commentController,
                  onStart: _startTask,
                  onComment: _saveComment,
                  onMeeting: _createMeeting,
                  onSubmit: _submitTask,
                );

                if (compact) {
                  return listPanel;
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

  Future<void> _createTask() async {
    final prepared = await _controller.prepareComposer();
    if (!mounted) return;
    if (!prepared) {
      _showFeedback(
        _controller.composerErrorMessage ??
            _controller.errorMessage ??
            'Görev formu hazırlanamadı.',
      );
      return;
    }

    final composer = _controller.composer;
    if (composer == null || composer.assignees.isEmpty) {
      _showFeedback('Görev açmak için en az bir atanabilir kullanıcı gerekli.');
      return;
    }

    final draft = await showTaskCreateDialog(
      context,
      snapshot: composer,
      role: _role,
    );
    if (!mounted || draft == null) return;

    final success = await _controller.createTask(draft);
    if (!mounted) return;
    if (success) {
      _searchController.clear();
      _commentController.clear();
    }
    _showFeedback(
      success
          ? 'Görev oluşturuldu.'
          : (_controller.errorMessage ?? 'Görev oluşturulamadı.'),
    );
  }

  Future<void> _startTask() async {
    final draft = await showTaskStartDialog(context);
    if (!mounted || draft == null) return;
    final success = await _controller.startSelectedTask(draft);
    _showFeedback(
      success
          ? 'Görev başlatıldı.'
          : (_controller.errorMessage ?? 'Görev başlatılamadı.'),
    );
  }

  Future<void> _saveComment() async =>
      _saveCommentWithFeedback(_commentController);

  Future<void> _saveCommentWithFeedback(
    TextEditingController controller,
  ) async {
    final comment = controller.text.trim();
    if (comment.isEmpty) return;
    final success = await _controller.addComment(comment, kind: _commentKind);
    if (success) controller.clear();
    _showFeedback(
      success
          ? _commentSuccessMessage
          : (_controller.errorMessage ?? 'Not kaydedilemedi.'),
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
    final draft = await showTaskSubmitDialog(context);
    if (!mounted || draft == null) return;
    final success = await _controller.submitSelectedTask(draft);
    _showFeedback(
      success
          ? 'Görev incelemeye gönderildi.'
          : (_controller.errorMessage ?? 'Görev teslim edilemedi.'),
    );
  }

  Future<void> _openTaskDetailSheet(String taskId) async {
    _controller.selectTask(taskId);
    final commentController = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.55,
            maxChildSize: 0.94,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: TaskDetailPanel(
                controller: _controller,
                role: _role,
                task: _controller.selectedTask,
                commentController: commentController,
                onStart: _startTask,
                onComment: () => _saveCommentWithFeedback(commentController),
                onMeeting: _createMeeting,
                onSubmit: _submitTask,
              ),
            ),
          ),
        ),
      );
    } finally {
      commentController.dispose();
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle, this.action});
  final String title;
  final String subtitle;
  final Widget? action;

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
        if (action != null) ...[const SizedBox(height: 14), action!],
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
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(metric.caption, style: const TextStyle(color: AppPalette.muted)),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.controller,
    required this.searchController,
    this.onCreate,
    required this.createLabel,
  });

  final TaskController controller;
  final TextEditingController searchController;
  final Future<void> Function()? onCreate;
  final String createLabel;

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
                hintText: 'Görev, proje, takım veya etiket ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          _FilterDropdown<TaskStatus?>(
            label: 'Durum',
            value: controller.statusFilter,
            items: const [null, ...TaskStatus.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: controller.updateStatusFilter,
          ),
          _FilterDropdown<TaskPriority?>(
            label: 'Öncelik',
            value: controller.priorityFilter,
            items: const [null, ...TaskPriority.values],
            itemLabel: (value) => value?.label ?? 'Tümü',
            onChanged: controller.updatePriorityFilter,
          ),
          _FilterDropdown<TaskDateFilter>(
            label: 'Tarih',
            value: controller.dateFilter,
            items: TaskDateFilter.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => controller.updateDateFilter(value!),
          ),
          _FilterDropdown<String?>(
            label: 'Takım',
            value: controller.teamFilter,
            items: [null, ...controller.teams],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateTeamFilter,
          ),
          _FilterDropdown<String?>(
            label: 'Kişi',
            value: controller.assigneeFilter,
            items: [null, ...controller.assignees],
            itemLabel: (value) => value ?? 'Tümü',
            onChanged: controller.updateAssigneeFilter,
          ),
          _FilterDropdown<String?>(
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
          if (onCreate != null)
            FilledButton.icon(
              onPressed: (controller.isSaving || controller.isPreparingComposer)
                  ? null
                  : () => onCreate!.call(),
              icon: const Icon(Icons.add_task_rounded),
              label: Text(
                controller.isPreparingComposer
                    ? 'Hazırlanıyor...'
                    : createLabel,
              ),
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
        isExpanded: true,
        initialValue: value,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    required this.opensDetailSheet,
  });

  final List<TaskItem> tasks;
  final String? selectedTaskId;
  final ValueChanged<String> onSelect;
  final bool opensDetailSheet;

  @override
  Widget build(BuildContext context) {
    return TaskPanelCard(
      title: 'Görev Listesi',
      subtitle: opensDetailSheet
          ? 'Kayda dokununca detay ve aksiyonlar açılır.'
          : 'Seçilen kayıt sağdaki detay kartında açılır.',
      child: tasks.isEmpty
          ? const StatePanel.empty(
              title: 'Filtreye uygun görev yok',
              message:
                  'Arama veya filtreler mevcut kayıtlarla eşleşmiyor. Filtreleri sıfırlayıp tekrar dene.',
            )
          : Column(
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
                                _taskSubline(task),
                                style: const TextStyle(color: AppPalette.muted),
                              ),
                              if (hasValue(task.serviceLocation)) ...[
                                const SizedBox(height: 6),
                                Text(
                                  task.serviceLocation!,
                                  style: const TextStyle(
                                    color: AppPalette.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TaskBadgeChip(
                                    label: task.status.label,
                                    color: statusColor(task.status),
                                  ),
                                  TaskBadgeChip(
                                    label: task.priority.label,
                                    color: priorityColor(task.priority),
                                  ),
                                  if (task.team.isNotEmpty)
                                    TaskBadgeChip(
                                      label: task.team,
                                      color: const Color(0xFF0A7F5A),
                                    ),
                                  TaskBadgeChip(
                                    label: task.tag,
                                    color: const Color(0xFF7A7AE6),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: task.progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppPalette.primary,
                                      ),
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

  String _taskSubline(TaskItem task) {
    final parts = <String>[
      if (task.project.isNotEmpty) task.project,
      if (task.team.isNotEmpty) task.team,
      task.assignee,
    ];
    return parts.join(' - ');
  }
}
