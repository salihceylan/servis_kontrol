import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/revisions/application/revision_controller.dart';
import 'package:servis_kontrol/features/revisions/domain/revision_item.dart';

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

  test('onay ve revizyon akışı çalışır', () {
    final controller = RevisionController(user: manager);

    expect(controller.pendingItems, isNotEmpty);
    controller.selectItem(controller.pendingItems.first.id);
    controller.approveSelected();
    expect(controller.selectedItem!.stage, RevisionStage.completed);
    expect(controller.selectedItem!.performanceReady, isTrue);

    final revisionTarget = controller.revisionItems.first;
    controller.selectItem(revisionTarget.id);
    controller.requestRevision('Fotoğraf ve toplantı notu eksik.');
    expect(controller.selectedItem!.stage, RevisionStage.inRevision);
    expect(controller.selectedItem!.revisionCount, revisionTarget.revisionCount + 1);
    expect(controller.selectedItem!.revisionReason, isNotNull);
    expect(controller.selectedItem!.earlyWarning, isTrue);
  });
}
