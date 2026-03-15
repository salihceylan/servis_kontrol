import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/tasks/data/task_repository.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

class ApiTaskRepository implements TaskRepository {
  const ApiTaskRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<TaskItem>> load({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    TaskDateFilter? dateFilter,
    String? assignee,
    String? tag,
  }) async {
    final items = await _client.getList(
      'tasks',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (status != null) 'status': status.apiValue,
        if (priority != null) 'priority': priority.apiValue,
        if (dateFilter != null) 'date_filter': dateFilter.apiValue,
        if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      },
    );
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<TaskComposerSnapshot> loadComposer() async {
    final payload = await _client.getMap('tasks/meta');
    return TaskComposerSnapshot.fromJson(payload);
  }

  @override
  Future<TaskItem> createTask(TaskDraft draft) async {
    final payload = await _client.postMap('tasks', body: draft.toJson());
    return TaskItem.fromJson(
      payload['task'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<TaskItem> start(String taskId) async {
    final payload = await _client.postMap('tasks/$taskId/start');
    return TaskItem.fromJson(
      payload['task'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<TaskItem> addComment({
    required String taskId,
    required String message,
  }) async {
    final payload = await _client.postMap(
      'tasks/$taskId/comment',
      body: {'message': message},
    );
    return TaskItem.fromJson(
      payload['task'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<TaskItem> scheduleMeeting(String taskId) async {
    final payload = await _client.postMap('tasks/$taskId/meeting');
    return TaskItem.fromJson(
      payload['task'] as Map<String, dynamic>? ?? payload,
    );
  }

  @override
  Future<TaskItem> submit(String taskId) async {
    final payload = await _client.postMap('tasks/$taskId/submit');
    return TaskItem.fromJson(
      payload['task'] as Map<String, dynamic>? ?? payload,
    );
  }
}
