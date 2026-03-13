import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/tasks/data/api_task_repository.dart';
import 'package:servis_kontrol/features/tasks/data/task_repository.dart';
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
    required ApiClient apiClient,
    TaskRepository? repository,
  }) : _repository = repository ?? ApiTaskRepository(apiClient) {
    load();
  }

  final TaskRepository _repository;

  List<TaskItem> _allTasks = const [];
  String _query = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  TaskDateFilter _dateFilter = TaskDateFilter.all;
  String? _assigneeFilter;
  String? _tagFilter;
  String? _selectedTaskId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String get query => _query;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  TaskDateFilter get dateFilter => _dateFilter;
  String? get assigneeFilter => _assigneeFilter;
  String? get tagFilter => _tagFilter;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasData => _allTasks.isNotEmpty;

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
    final blockedCount = _allTasks.where((task) => task.blockedByCount > 0).length;
    final trackedMinutes = _allTasks.fold<int>(
      0,
      (total, task) => total + task.trackedMinutes,
    );

    final metrics = [
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
    metrics.addAll([
      TaskSummaryMetric(
        label: 'Bağımlı İş',
        value: '$blockedCount',
        caption: 'Başka kaydı bekleyen görevler',
      ),
      TaskSummaryMetric(
        label: 'Zaman Takibi',
        value: '${trackedMinutes ~/ 60}s ${trackedMinutes % 60}dk',
        caption: 'Toplam izlenen çalışma süresi',
      ),
    ]);
    return metrics;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allTasks = await _repository.load(
        query: _query,
        status: _statusFilter,
        priority: _priorityFilter,
        dateFilter: _dateFilter,
        assignee: _assigneeFilter,
        tag: _tagFilter,
      );
      _ensureSelection();
    } on ApiException catch (error) {
      _allTasks = const [];
      _selectedTaskId = null;
      _errorMessage = error.message;
    } catch (_) {
      _allTasks = const [];
      _selectedTaskId = null;
      _errorMessage = 'Görev verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<bool> startSelectedTask() async {
    final task = selectedTask;
    if (task == null) {
      return false;
    }
    return _persistTask(() => _repository.start(task.id));
  }

  Future<bool> addComment(String message) async {
    final task = selectedTask;
    final normalized = message.trim();
    if (task == null || normalized.isEmpty) {
      return false;
    }
    return _persistTask(
      () => _repository.addComment(taskId: task.id, message: normalized),
    );
  }

  Future<bool> scheduleMeeting() async {
    final task = selectedTask;
    if (task == null) {
      return false;
    }
    return _persistTask(() => _repository.scheduleMeeting(task.id));
  }

  Future<bool> submitSelectedTask() async {
    final task = selectedTask;
    if (task == null) {
      return false;
    }
    return _persistTask(() => _repository.submit(task.id));
  }

  Future<bool> _persistTask(Future<TaskItem> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedTask = await action();
      _writeTask(updatedTask);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Görev güncellemesi kaydedilemedi.';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _writeTask(TaskItem updatedTask) {
    _allTasks = [
      for (final task in _allTasks)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    _selectedTaskId = updatedTask.id;
    _ensureSelection();
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
