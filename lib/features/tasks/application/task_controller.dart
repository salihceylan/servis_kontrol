import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/tasks/application/mock_task_repository.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class TaskSummaryMetric {
  const TaskSummaryMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class TaskController extends ChangeNotifier {
  TaskController({
    required AppUser user,
    MockTaskRepository? repository,
  })  : _user = user,
        _repository = repository ?? const MockTaskRepository() {
    _allTasks = _repository.loadFor(user);
    if (_allTasks.isNotEmpty) {
      _selectedTaskId = _allTasks.first.id;
    }
  }

  final AppUser _user;
  final MockTaskRepository _repository;

  late List<TaskItem> _allTasks;
  String _query = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  TaskDateFilter _dateFilter = TaskDateFilter.all;
  String? _assigneeFilter;
  String? _tagFilter;
  String? _selectedTaskId;

  String get query => _query;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  TaskDateFilter get dateFilter => _dateFilter;
  String? get assigneeFilter => _assigneeFilter;
  String? get tagFilter => _tagFilter;

  List<String> get assignees => {
    for (final task in _allTasks) task.assignee,
  }.toList()
    ..sort();

  List<String> get tags => {
    for (final task in _allTasks) task.tag,
  }.toList()
    ..sort();

  List<TaskItem> get filteredTasks {
    final normalizedQuery = _query.trim().toLowerCase();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(
      Duration(days: DateTime.daysPerWeek - now.weekday),
    );

    final tasks = _allTasks.where((task) {
      final queryMatches =
          normalizedQuery.isEmpty ||
          task.title.toLowerCase().contains(normalizedQuery) ||
          task.project.toLowerCase().contains(normalizedQuery) ||
          task.assignee.toLowerCase().contains(normalizedQuery) ||
          task.tag.toLowerCase().contains(normalizedQuery);

      final statusMatches =
          _statusFilter == null || task.status == _statusFilter;
      final priorityMatches =
          _priorityFilter == null || task.priority == _priorityFilter;
      final assigneeMatches =
          _assigneeFilter == null || task.assignee == _assigneeFilter;
      final tagMatches = _tagFilter == null || task.tag == _tagFilter;
      final dateMatches = switch (_dateFilter) {
        TaskDateFilter.all => true,
        TaskDateFilter.today =>
          task.dueAt.year == now.year &&
              task.dueAt.month == now.month &&
              task.dueAt.day == now.day,
        TaskDateFilter.thisWeek =>
          !task.dueAt.isBefore(startOfToday) && !task.dueAt.isAfter(endOfWeek),
        TaskDateFilter.overdue =>
          task.dueAt.isBefore(startOfToday) &&
              task.status != TaskStatus.delivered,
      };

      return queryMatches &&
          statusMatches &&
          priorityMatches &&
          assigneeMatches &&
          tagMatches &&
          dateMatches;
    }).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    return tasks;
  }

  TaskItem? get selectedTask {
    final visibleTasks = filteredTasks;
    if (visibleTasks.isEmpty) {
      return null;
    }

    final selected = visibleTasks.cast<TaskItem?>().firstWhere(
      (task) => task?.id == _selectedTaskId,
      orElse: () => null,
    );
    return selected ?? visibleTasks.first;
  }

  List<TaskSummaryMetric> get summaryMetrics {
    final now = DateTime.now();
    final todayCount = _allTasks.where((task) {
      return task.dueAt.year == now.year &&
          task.dueAt.month == now.month &&
          task.dueAt.day == now.day;
    }).length;
    final reviewCount = _allTasks.where((task) {
      return task.status == TaskStatus.inReview ||
          task.status == TaskStatus.revision;
    }).length;
    final highPriorityCount = _allTasks.where((task) {
      return task.priority == TaskPriority.high;
    }).length;

    return [
      TaskSummaryMetric(
        label: 'Toplam Görev',
        value: '${_allTasks.length}',
        caption: '${filteredTasks.length} görev filtreye uyuyor',
      ),
      TaskSummaryMetric(
        label: 'Bugün Teslim',
        value: '$todayCount',
        caption: 'Gün içi tamamlanacak işler',
      ),
      TaskSummaryMetric(
        label: 'İnceleme / Revizyon',
        value: '$reviewCount',
        caption: 'Karar bekleyen görevler',
      ),
      TaskSummaryMetric(
        label: 'Yüksek Öncelik',
        value: '$highPriorityCount',
        caption: 'Yakın takip gerektiren işler',
      ),
    ];
  }

  void updateQuery(String value) {
    _query = value;
    _ensureSelection();
    notifyListeners();
  }

  void updateStatusFilter(TaskStatus? value) {
    _statusFilter = value;
    _ensureSelection();
    notifyListeners();
  }

  void updatePriorityFilter(TaskPriority? value) {
    _priorityFilter = value;
    _ensureSelection();
    notifyListeners();
  }

  void updateDateFilter(TaskDateFilter value) {
    _dateFilter = value;
    _ensureSelection();
    notifyListeners();
  }

  void updateAssigneeFilter(String? value) {
    _assigneeFilter = value;
    _ensureSelection();
    notifyListeners();
  }

  void updateTagFilter(String? value) {
    _tagFilter = value;
    _ensureSelection();
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = null;
    _priorityFilter = null;
    _dateFilter = TaskDateFilter.all;
    _assigneeFilter = null;
    _tagFilter = null;
    _ensureSelection();
    notifyListeners();
  }

  void selectTask(String taskId) {
    _selectedTaskId = taskId;
    notifyListeners();
  }

  void startSelectedTask() {
    final task = selectedTask;
    if (task == null) {
      return;
    }

    _writeTask(
      task.copyWith(
        status: TaskStatus.inProgress,
        updatedAt: DateTime.now(),
        timeline: [
          TaskTimelineEntry(
            title: 'Başlatıldı',
            detail: 'Durum güncellendi, zaman sayacı başladı.',
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...task.timeline,
        ],
      ),
    );
  }

  void addComment(String message) {
    final task = selectedTask;
    final normalized = message.trim();
    if (task == null || normalized.isEmpty) {
      return;
    }

    _writeTask(
      task.copyWith(
        updatedAt: DateTime.now(),
        timeline: [
          TaskTimelineEntry(
            title: 'Yorum eklendi',
            detail: '$normalized İlgililere bildirim gönderildi.',
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...task.timeline,
        ],
      ),
    );
  }

  void scheduleMeeting() {
    final task = selectedTask;
    if (task == null) {
      return;
    }

    final link =
        task.meetingLink ?? 'https://meet.workflow.local/${task.id.toLowerCase()}';

    _writeTask(
      task.copyWith(
        meetingLink: link,
        updatedAt: DateTime.now(),
        timeline: [
          TaskTimelineEntry(
            title: 'Toplantı planlandı',
            detail: 'Toplantı linki göreve eklendi ve katılımcılara davet çıktı.',
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...task.timeline,
        ],
      ),
    );
  }

  void submitSelectedTask() {
    final task = selectedTask;
    if (task == null) {
      return;
    }

    _writeTask(
      task.copyWith(
        status: TaskStatus.inReview,
        updatedAt: DateTime.now(),
        checklistCompleted: task.checklistTotal,
        timeline: [
          TaskTimelineEntry(
            title: 'Teslim edildi',
            detail: 'Görev lider incelemesine gönderildi.',
            actor: _user.firstName,
            timestamp: DateTime.now(),
          ),
          ...task.timeline,
        ],
      ),
    );
  }

  void _writeTask(TaskItem updatedTask) {
    _allTasks = [
      for (final task in _allTasks)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    _selectedTaskId = updatedTask.id;
    _ensureSelection();
    notifyListeners();
  }

  void _ensureSelection() {
    final visibleTasks = filteredTasks;
    if (visibleTasks.isEmpty) {
      _selectedTaskId = null;
      return;
    }
    final exists = visibleTasks.any((task) => task.id == _selectedTaskId);
    if (!exists) {
      _selectedTaskId = visibleTasks.first.id;
    }
  }
}
