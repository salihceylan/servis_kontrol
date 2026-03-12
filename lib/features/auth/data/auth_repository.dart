import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<AppUser> completeOnboarding(OnboardingProfile profile);

  Future<void> logout();
}
