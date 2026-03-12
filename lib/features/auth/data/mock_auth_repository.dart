import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';

class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.user,
    required this.description,
  });

  final String email;
  final String password;
  final AppUser user;
  final String description;
}

class MockAuthRepository {
  MockAuthRepository()
    : _accounts = {
        'yonetici@workflow.local': DemoAccount(
          email: 'yonetici@workflow.local',
          password: 'Workflow2026!',
          description: 'Yönetici paneline doğrudan giriş yapar.',
          user: const AppUser(
            name: 'Merve Aydın',
            email: 'yonetici@workflow.local',
            role: UserRole.manager,
            department: 'Operasyon',
            jobTitle: 'Operasyon Yöneticisi',
            workPreference: 'Karma operasyon',
            notificationChannels: {
              NotificationChannel.system,
              NotificationChannel.email,
            },
            isFirstLogin: false,
            wantsQuickTour: false,
          ),
        ),
        'lider@workflow.local': DemoAccount(
          email: 'lider@workflow.local',
          password: 'Workflow2026!',
          description: 'İlk girişte onboarding ve revizyon yönetimi görünür.',
          user: const AppUser(
            name: 'Seda Yılmaz',
            email: 'lider@workflow.local',
            role: UserRole.teamLead,
            department: 'Saha Operasyon',
            jobTitle: 'Ekip Lideri',
            workPreference: 'Saha + ofis hibrit',
            notificationChannels: {
              NotificationChannel.system,
              NotificationChannel.email,
              NotificationChannel.slack,
            },
            isFirstLogin: true,
            wantsQuickTour: true,
          ),
        ),
        'teknisyen@workflow.local': DemoAccount(
          email: 'teknisyen@workflow.local',
          password: 'Workflow2026!',
          description:
              'Çalışan akışında ilk giriş profil tamamlama ile açılır.',
          user: const AppUser(
            name: 'Onur Kaya',
            email: 'teknisyen@workflow.local',
            role: UserRole.employee,
            department: 'Teknik Servis',
            jobTitle: 'Saha Teknisyeni',
            workPreference: 'Saha odaklı',
            notificationChannels: {NotificationChannel.system},
            isFirstLogin: true,
            wantsQuickTour: true,
          ),
        ),
      };

  final Map<String, DemoAccount> _accounts;

  List<DemoAccount> get demoAccounts => _accounts.values.toList(growable: false);

  Future<AppUser?> authenticate(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      return null;
    }
    return account.user;
  }

  Future<bool> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _accounts.containsKey(email.trim().toLowerCase());
  }

  AppUser saveOnboarding(String email, OnboardingProfile profile) {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = _accounts[normalizedEmail];
    if (existing == null) {
      throw StateError('Kullanıcı bulunamadı: $email');
    }

    final updatedUser = existing.user.copyWith(
      name: profile.fullName,
      department: profile.department,
      jobTitle: profile.jobTitle,
      workPreference: profile.workPreference,
      notificationChannels: profile.notificationChannels,
      wantsQuickTour: profile.wantsQuickTour,
      isFirstLogin: false,
    );

    _accounts[normalizedEmail] = DemoAccount(
      email: existing.email,
      password: existing.password,
      user: updatedUser,
      description: existing.description,
    );

    return updatedUser;
  }
}
