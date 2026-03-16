import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/data/task_repository.dart';
import 'package:servis_kontrol/features/tasks/domain/task_composer.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

import '../../../support/test_support.dart';

void main() {
  test('durum ve takim filtresi ile gorev aksiyonlari calisir', () async {
    final controller = TaskController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeTaskRepository(),
    );

    await controller.load();
    expect(controller.filteredTasks, isNotEmpty);

    controller.updateStatusFilter(TaskStatus.pending);
    expect(
      controller.filteredTasks.every(
        (task) => task.status == TaskStatus.pending,
      ),
      isTrue,
    );

    controller.updateTeamFilter('Merkez Ekip');
    expect(
      controller.filteredTasks.every((task) => task.team == 'Merkez Ekip'),
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

  test(
    'yonetici gorev olusturma verisini yukler ve takimli gorev olusturur',
    () async {
      final controller = TaskController(
        user: managerUser,
        apiClient: createTestApiClient(),
        repository: _FakeTaskRepository(),
      );

      expect(controller.canCreateTask, isTrue);
      expect(await controller.prepareComposer(), isTrue);
      expect(controller.composer!.projects, isNotEmpty);
      expect(controller.composer!.teams, isNotEmpty);

      controller.updateStatusFilter(TaskStatus.delivered);
      final success = await controller.createTask(
        TaskDraft(
          title: 'Yeni saha kontrolu',
          description: 'Detayli kontrol listesi acildi.',
          projectId: 'project-1',
          teamId: 'team-1',
          assigneeId: 'user-1',
          priority: TaskPriority.medium,
          dueAt: DateTime(2026, 3, 15, 18),
          estimatedMinutes: 120,
          tag: 'Saha',
        ),
      );

      expect(success, isTrue);
      expect(controller.statusFilter, isNull);
      expect(controller.selectedTask!.title, 'Yeni saha kontrolu');
      expect(controller.selectedTask!.team, 'Merkez Ekip');
      expect(controller.selectedTask!.dueAt, DateTime(2026, 3, 15, 18));
      expect(controller.composer!.tagSuggestions, contains('Saha'));
    },
  );

  test('opsiyonel son tarih olmadan gorev olusturabilir', () async {
    final controller = TaskController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeTaskRepository(),
    );

    await controller.prepareComposer();
    final success = await controller.createTask(
      const TaskDraft(
        title: 'Plansiz kontrol',
        description: 'Son tarih sonradan belirlenecek.',
        teamId: 'team-2',
        assigneeId: 'user-2',
        priority: TaskPriority.low,
      ),
    );

    expect(success, isTrue);
    expect(controller.selectedTask!.dueAt, isNull);
    expect(controller.selectedTask!.team, 'Saha Ekip');
  });

  test('employee kullanici varsayilan durumda gorev olusturamaz', () async {
    final controller = TaskController(
      user: managerUser.copyWith(
        role: UserRole.employee,
        permissions: const {},
      ),
      apiClient: createTestApiClient(),
      repository: _FakeTaskRepository(),
    );

    expect(controller.canCreateTask, isFalse);
    expect(await controller.prepareComposer(), isFalse);
    expect(
      await controller.createTask(
        const TaskDraft(
          title: 'Yetkisiz is',
          description: '',
          projectId: 'project-1',
          assigneeId: 'user-1',
          priority: TaskPriority.low,
        ),
      ),
      isFalse,
    );
  });
}

class _FakeTaskRepository implements TaskRepository {
  int _nextId = 2;
  final Map<String, TaskItem> _items = {
    '1': TaskItem(
      id: '1',
      taskNo: 'A12345ab10',
      title: 'Saha kontrolu',
      project: 'Merkez Plaza',
      team: 'Merkez Ekip',
      teamId: 'team-1',
      assignee: 'Merve',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      dueAt: DateTime(2026, 3, 12, 17),
      updatedAt: DateTime(2026, 3, 12, 9),
      tag: 'Kontrol',
      description: 'Kontrol kaydi',
      checklistCompleted: 1,
      checklistTotal: 3,
      estimatedMinutes: 180,
      trackedMinutes: 95,
      blockedByCount: 1,
      subtaskCount: 2,
      dependencies: const [
        TaskDependency(title: 'Malzeme onayi', statusLabel: 'Bekleniyor'),
      ],
      timeEntries: const [
        TaskTimeEntry(
          userName: 'Merve',
          durationLabel: '1s 35dk',
          startedAtLabel: '12.03.2026 09:00',
        ),
      ],
      timeline: [
        TaskTimelineEntry(
          title: 'Gorev olusturuldu',
          detail: 'Kayit acildi',
          actor: 'Sistem',
          timestamp: DateTime(2026, 3, 12, 9),
        ),
      ],
      requestSource: 'Saha Talep Formu',
    ),
  };

  @override
  Future<TaskComposerSnapshot> loadComposer() async {
    return const TaskComposerSnapshot(
      teams: [
        TaskFormOption(id: 'team-1', label: 'Merkez Ekip'),
        TaskFormOption(id: 'team-2', label: 'Saha Ekip'),
      ],
      projects: [
        TaskFormOption(
          id: 'project-1',
          label: 'Merkez Plaza',
          groupId: 'team-1',
        ),
        TaskFormOption(id: 'project-2', label: 'Saha Hat', groupId: 'team-2'),
      ],
      assignees: [
        TaskFormOption(id: 'user-1', label: 'Merve', groupId: 'team-1'),
        TaskFormOption(id: 'user-2', label: 'Onur', groupId: 'team-2'),
      ],
      tagSuggestions: ['Kontrol'],
    );
  }

  @override
  Future<TaskItem> createTask(TaskDraft draft) async {
    final composer = await loadComposer();
    final id = '${_nextId++}';
    final team = composer.teams.firstWhere(
      (item) => item.id == (draft.teamId ?? 'team-1'),
      orElse: () => const TaskFormOption(id: 'team-1', label: 'Merkez Ekip'),
    );
    final assignee = composer.assignees.firstWhere(
      (item) => item.id == draft.assigneeId,
      orElse: () => const TaskFormOption(id: 'user-1', label: 'Merve'),
    );
    final project = composer.projects.firstWhere(
      (item) => item.id == (draft.projectId ?? ''),
      orElse: () => TaskFormOption(
        id: 'project-none',
        label: team.label,
        groupId: team.id,
      ),
    );
    final timestamp = draft.dueAt ?? DateTime(2026, 3, 13, 9);

    final item = TaskItem(
      id: id,
      taskNo: 'B12345cd$id',
      title: draft.title,
      project: project.label,
      team: team.label,
      teamId: team.id,
      assignee: assignee.label,
      status: TaskStatus.pending,
      priority: draft.priority,
      dueAt: draft.dueAt,
      updatedAt: timestamp,
      tag: draft.tag?.trim().isNotEmpty == true ? draft.tag!.trim() : 'Genel',
      description: draft.description,
      checklistCompleted: 0,
      checklistTotal: 0,
      estimatedMinutes: draft.estimatedMinutes ?? 0,
      trackedMinutes: 0,
      blockedByCount: 0,
      subtaskCount: 0,
      dependencies: const [],
      timeEntries: const [],
      timeline: [
        TaskTimelineEntry(
          title: 'Gorev olusturuldu',
          detail: draft.description,
          actor: assignee.label,
          timestamp: timestamp,
        ),
      ],
    );
    _items[id] = item;
    return item;
  }

  @override
  Future<List<TaskItem>> load({
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
    TaskDateFilter? dateFilter,
    String? team,
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
