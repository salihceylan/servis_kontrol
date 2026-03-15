import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';
import 'package:servis_kontrol/features/auth/data/auth_repository.dart';
import 'package:servis_kontrol/features/auth/data/auth_session_storage.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';
import 'package:servis_kontrol/features/auth/domain/auth_session.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';

import '../../../support/test_support.dart';

void main() {
  test('restores a persisted authenticated session', () async {
    final storage = InMemoryAuthSessionStorage();
    const user = AppUser(
      id: '12',
      userCode: '1234567890',
      companyId: '4',
      companyCode: '65432',
      name: 'Merve Aydin',
      email: 'yonetici@workflow.local',
      role: UserRole.manager,
      department: 'Operasyon',
      jobTitle: 'Operasyon Yonetici',
      workPreference: 'Hibrit',
      notificationChannels: {NotificationChannel.system},
      isFirstLogin: false,
      wantsQuickTour: false,
      permissions: {'dashboard.view'},
    );
    await storage.write(const AuthSession(token: 'token-123', user: user));

    final controller = AuthController(
      apiClient: createTestApiClient(),
      repository: _FakeAuthRepository(user),
      sessionStorage: storage,
    );

    await controller.restoreSession();

    expect(controller.currentUser?.email, user.email);
    expect(controller.stage, AuthStage.authenticated);
    expect(controller.apiClient.accessToken, 'token-123');
  });

  test('persists token and clears it on logout', () async {
    final storage = InMemoryAuthSessionStorage();
    const user = AppUser(
      id: '22',
      userCode: '1098765432',
      companyId: '8',
      companyCode: '10293',
      name: 'Selin Yilmaz',
      email: 'lider@workflow.local',
      role: UserRole.teamLead,
      department: 'Urun',
      jobTitle: 'Takim Lideri',
      workPreference: 'Ofis',
      notificationChannels: {NotificationChannel.system},
      isFirstLogin: true,
      wantsQuickTour: true,
    );
    final controller = AuthController(
      apiClient: createTestApiClient(),
      repository: _FakeAuthRepository(user),
      sessionStorage: storage,
    );

    await controller.signIn(email: user.email, password: 'secret');

    final storedAfterLogin = await storage.read();
    expect(storedAfterLogin?.token, 'token-abc');
    expect(controller.stage, AuthStage.onboarding);

    await controller.logout();

    expect(await storage.read(), isNull);
    expect(controller.apiClient.accessToken, isNull);
    expect(controller.stage, AuthStage.login);
  });

  test('does not persist session when remember me is disabled', () async {
    final storage = InMemoryAuthSessionStorage();
    const user = AppUser(
      id: '34',
      userCode: '5555555555',
      companyId: '9',
      companyCode: '55599',
      name: 'Ayse Demir',
      email: 'ayse@workflow.local',
      role: UserRole.manager,
      department: 'Operasyon',
      jobTitle: 'Yonetici',
      workPreference: 'Ofis',
      notificationChannels: {NotificationChannel.system},
      isFirstLogin: false,
      wantsQuickTour: false,
    );
    final controller = AuthController(
      apiClient: createTestApiClient(),
      repository: _FakeAuthRepository(user),
      sessionStorage: storage,
    );

    await controller.signIn(
      email: user.email,
      password: 'secret',
      rememberSession: false,
    );

    expect(await storage.read(), isNull);
    expect(controller.stage, AuthStage.authenticated);
    expect(controller.apiClient.accessToken, 'token-abc');
  });
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.user);

  final AppUser user;

  @override
  Future<AppUser> completeOnboarding(OnboardingProfile profile) async {
    return user.copyWith(
      isFirstLogin: false,
      name: profile.fullName,
      department: profile.department,
      jobTitle: profile.jobTitle,
      workPreference: profile.workPreference,
      notificationChannels: profile.notificationChannels,
      wantsQuickTour: profile.wantsQuickTour,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> requestSignUp({
    required String companyName,
    required String fullName,
    required String email,
    String? phone,
  }) async {}

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return AuthSession(token: 'token-abc', user: user);
  }
}
