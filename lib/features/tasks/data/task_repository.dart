import 'package:servis_kontrol/features/tasks/domain/task_item.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> load({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    TaskDateFilter? dateFilter,
    String? assignee,
    String? tag,
  });

  Future<TaskComposerSnapshot> loadComposer();

  Future<TaskItem> createTask(TaskDraft draft);

  Future<TaskItem> start(String taskId);

  Future<TaskItem> addComment({
    required String taskId,
    required String message,
  });

  Future<TaskItem> scheduleMeeting(String taskId);

  Future<TaskItem> submit(String taskId);
}
