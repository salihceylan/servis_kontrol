import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/reports/application/report_controller.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

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

  test('rapor oluşturma akışı hazır kayda döner', () async {
    final controller = ReportController(user: manager);

    expect(controller.runs, isNotEmpty);
    controller.updateTypeFilter(ReportType.performance);
    controller.updateTeamFilter('Saha Ekibi');

    await controller.createReport(
      scope: 'Saha Ekibi',
      format: ReportFormat.pdf,
    );

    expect(controller.creating, isFalse);
    expect(controller.runs.first.title, 'Performans Raporu');
    expect(controller.runs.first.status, ReportRunStatus.ready);
  });
}
