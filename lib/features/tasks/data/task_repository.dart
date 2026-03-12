import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> load({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    TaskDateFilter? dateFilter,
    String? assignee,
    String? tag,
  });

  Future<TaskItem> start(String taskId);

  Future<TaskItem> addComment({
    required String taskId,
    required String message,
  });

  Future<TaskItem> scheduleMeeting(String taskId);

  Future<TaskItem> submit(String taskId);
}
