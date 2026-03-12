import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/auth/data/auth_repository.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_session.dart';

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final payload = await _client.postMap(
      'auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthSession.fromJson(payload);
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return _client.postVoid(
      'auth/forgot-password',
      body: {'email': email.trim()},
    );
  }

  @override
  Future<AppUser> completeOnboarding(OnboardingProfile profile) async {
    final payload = await _client.putMap(
      'auth/onboarding',
      body: profile.toJson(),
    );
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>? ?? payload);
  }

  @override
  Future<void> logout() {
    return _client.postVoid('auth/logout');
  }
}
