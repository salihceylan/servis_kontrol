import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';

ApiClient createTestApiClient() =>
    ApiClient(baseUrl: 'https://example.com/api');

const managerUser = AppUser(
  name: 'Merve Aydin',
  email: 'yonetici@workflow.local',
  role: UserRole.manager,
  department: 'Operasyon',
  jobTitle: 'Operasyon Yoneticisi',
  workPreference: 'Karma operasyon',
  notificationChannels: {NotificationChannel.system},
  isFirstLogin: false,
  wantsQuickTour: false,
);
