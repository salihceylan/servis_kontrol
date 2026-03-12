import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/tasks/application/task_controller.dart';
import 'package:servis_kontrol/features/tasks/domain/task_item.dart';

void main() {
  const manager = AppUser(
    name: 'Merve Aydın',
    email: 'yonetici@workflow.local',
    role: UserRole.manager,
    department: 'Operasyon',
    jobTitle: 'Operasyon Yöneticisi',
    workPreference: 'Karma operasyon',
    notificationChannels: {NotificationChannel.system},
    isFirstLogin: false,
    wantsQuickTour: false,
  );

  test('durum filtresi ve görev aksiyonları çalışır', () {
    final controller = TaskController(user: manager);

    expect(controller.filteredTasks, isNotEmpty);

    controller.updateStatusFilter(TaskStatus.pending);
    expect(
      controller.filteredTasks.every((task) => task.status == TaskStatus.pending),
      isTrue,
    );

    controller.clearFilters();
    expect(controller.selectedTask, isNotNull);

    controller.startSelectedTask();
    expect(controller.selectedTask!.status, TaskStatus.inProgress);

    controller.addComment('Revizyon öncesi son kontrol notu.');
    expect(controller.selectedTask!.timeline.first.title, 'Yorum eklendi');

    controller.scheduleMeeting();
    expect(controller.selectedTask!.meetingLink, isNotNull);

    controller.submitSelectedTask();
    expect(controller.selectedTask!.status, TaskStatus.inReview);
  });
}
