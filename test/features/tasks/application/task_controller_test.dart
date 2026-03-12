import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/data/task_repository.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

import '../../../support/test_support.dart';

void main() {
  test('durum filtresi ve gorev aksiyonlari calisir', () async {
    final controller = TaskController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeTaskRepository(),
    );

    await controller.load();
    expect(controller.filteredTasks, isNotEmpty);

    controller.updateStatusFilter(TaskStatus.pending);
    expect(
      controller.filteredTasks.every((task) => task.status == TaskStatus.pending),
      isTrue,
    );

    controller.clearFilters();
    expect(controller.selectedTask, isNotNull);

    await controller.startSelectedTask();
    expect(controller.selectedTask!.status, TaskStatus.inProgress);

    await controller.addComment('Revizyon oncesi son kontrol notu.');
    expect(controller.selectedTask!.timeline.first.title, 'Yorum eklendi');

    await controller.scheduleMeeting();
    expect(controller.selectedTask!.meetingLink, isNotNull);

    await controller.submitSelectedTask();
    expect(controller.selectedTask!.status, TaskStatus.inReview);
  });
}

class _FakeTaskRepository implements TaskRepository {
  final Map<String, TaskItem> _items = {
    '1': TaskItem(
      id: '1',
      title: 'Saha kontrolu',
      project: 'Merkez Plaza',
      assignee: 'Merve',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      dueAt: DateTime(2026, 3, 12, 17),
      updatedAt: DateTime(2026, 3, 12, 9),
      tag: 'Kontrol',
      description: 'Kontrol kaydi',
      checklistCompleted: 1,
      checklistTotal: 3,
      timeline: [
        TaskTimelineEntry(
          title: 'Gorev olusturuldu',
          detail: 'Kayit acildi',
          actor: 'Sistem',
          timestamp: DateTime(2026, 3, 12, 9),
        ),
      ],
    ),
  };

  @override
  Future<List<TaskItem>> load({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    TaskDateFilter? dateFilter,
    String? assignee,
    String? tag,
  }) async {
    return _items.values.toList(growable: false);
  }

  @override
  Future<TaskItem> start(String taskId) async {
    final item = _items[taskId]!;
    final updated = item.copyWith(status: TaskStatus.inProgress);
    _items[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskItem> addComment({
    required String taskId,
    required String message,
  }) async {
    final item = _items[taskId]!;
    final updated = item.copyWith(
      timeline: [
        TaskTimelineEntry(
          title: 'Yorum eklendi',
          detail: message,
          actor: 'Merve',
          timestamp: DateTime(2026, 3, 12, 10),
        ),
        ...item.timeline,
      ],
    );
    _items[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskItem> scheduleMeeting(String taskId) async {
    final item = _items[taskId]!;
    final updated = item.copyWith(meetingLink: 'https://meet.example.com/1');
    _items[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskItem> submit(String taskId) async {
    final item = _items[taskId]!;
    final updated = item.copyWith(status: TaskStatus.inReview);
    _items[taskId] = updated;
    return updated;
  }
}
