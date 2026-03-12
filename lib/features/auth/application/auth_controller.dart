import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/data/api_auth_repository.dart';
import 'package:servis_kontrol/features/auth/data/auth_repository.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient apiClient,
    AuthRepository? repository,
  })  : _apiClient = apiClient,
        _repository = repository ?? ApiAuthRepository(apiClient);

  final ApiClient _apiClient;
  final AuthRepository _repository;
  AppUser? _currentUser;
  AuthStage _stage = AuthStage.login;
  bool _busy = false;

  ApiClient get apiClient => _apiClient;
  AppUser? get currentUser => _currentUser;
  AuthStage get stage => _stage;
  bool get busy => _busy;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final session = await _repository.signIn(email: email, password: password);
      _apiClient.updateAccessToken(session.token);
      _currentUser = session.user;
      _stage = session.user.isFirstLogin
          ? AuthStage.onboarding
          : AuthStage.authenticated;
      return AuthResult.success('Oturum açıldı.');
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Oturum açılamadı. Sunucu cevabı geçersiz.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return AuthResult.failure('Geçerli bir e-posta adresi girin.');
    }

    _busy = true;
    notifyListeners();
    try {
      await _repository.requestPasswordReset(normalized);
      return AuthResult.success(
        'Parola sıfırlama bağlantısı gönderildi. Gelen kutunuzu kontrol edin.',
      );
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Parola sıfırlama isteği gönderilemedi.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> completeOnboarding(OnboardingProfile profile) async {
    if (_currentUser == null) {
      return AuthResult.failure('Aktif kullanıcı bulunamadı.');
    }

    _busy = true;
    notifyListeners();
    try {
      _currentUser = await _repository.completeOnboarding(profile);
      _stage = AuthStage.authenticated;
      return AuthResult.success('İlk giriş kurulumu tamamlandı.');
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Kurulum kaydedilemedi.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Oturum sunucuda kapanmasa bile istemci tarafını temizle.
    }
    _apiClient.clearAccessToken();
    _currentUser = null;
    _stage = AuthStage.login;
    _busy = false;
    notifyListeners();
  }
}
