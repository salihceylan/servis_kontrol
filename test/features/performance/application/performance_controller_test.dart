import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/performance/application/performance_controller.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

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

  test('performans aralığı değişince snapshot yenilenir', () {
    final controller = PerformanceController(user: manager);

    expect(controller.snapshot.metrics, isNotEmpty);
    expect(controller.range, PerformanceRange.last30Days);

    controller.updateRange(PerformanceRange.last6Months);

    expect(controller.range, PerformanceRange.last6Months);
    expect(controller.snapshot.rows, isNotEmpty);
    expect(controller.snapshot.metrics.first.label, 'Genel Skor');
  });
}
