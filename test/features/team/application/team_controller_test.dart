import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

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

  test('ekip filtreleri ve yönetici yorumu çalışır', () {
    final controller = TeamController(user: manager);

    expect(controller.managerMode, isTrue);
    expect(controller.members, isNotEmpty);

    controller.toggleFlaggedOnly(true);
    expect(
      controller.members.every(
        (member) => member.riskLevel == MemberRiskLevel.high,
      ),
      isTrue,
    );

    controller.toggleFlaggedOnly(false);
    controller.updateQuery('Seda');
    expect(controller.members, hasLength(1));
    expect(controller.selectedMember?.name, 'Seda Yılmaz');

    controller.addManagerNote('Bugün teslim öncesi revizyon kuyruğunu kapat.');
    expect(
      controller.selectedMember?.lastManagerNote,
      'Bugün teslim öncesi revizyon kuyruğunu kapat.',
    );

    controller.toggleManagerMode(false);
    expect(controller.managerMode, isFalse);
    expect(controller.alerts.length, lessThanOrEqualTo(2));
  });
}
