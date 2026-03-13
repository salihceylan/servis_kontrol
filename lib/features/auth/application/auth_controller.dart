import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/data/api_auth_repository.dart';
import 'package:servis_kontrol/features/auth/data/auth_repository.dart';
import 'package:servis_kontrol/features/auth/data/auth_session_storage.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';
import 'package:servis_kontrol/features/auth/domain/auth_session.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient apiClient,
    AuthRepository? repository,
    AuthSessionStorage? sessionStorage,
  })  : _apiClient = apiClient,
        _repository = repository ?? ApiAuthRepository(apiClient),
        _sessionStorage = sessionStorage ?? InMemoryAuthSessionStorage();

  final ApiClient _apiClient;
  final AuthRepository _repository;
  AuthSessionStorage _sessionStorage;
  AppUser? _currentUser;
  AuthStage _stage = AuthStage.login;
  bool _busy = false;

  ApiClient get apiClient => _apiClient;
  AppUser? get currentUser => _currentUser;
  AuthStage get stage => _stage;
  bool get busy => _busy;

  void updateSessionStorage(AuthSessionStorage sessionStorage) {
    _sessionStorage = sessionStorage;
  }

  Future<void> restoreSession() async {
    try {
      final session = await _sessionStorage.read();
      if (session == null || session.token.trim().isEmpty) {
        return;
      }

      _apiClient.updateAccessToken(session.token);
      _currentUser = session.user;
      _stage = session.user.isFirstLogin
          ? AuthStage.onboarding
          : AuthStage.authenticated;
      notifyListeners();
    } catch (_) {
      _apiClient.clearAccessToken();
      _currentUser = null;
      _stage = AuthStage.login;
      await _sessionStorage.clear();
      notifyListeners();
    }
  }

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
      await _sessionStorage.write(session);
      return AuthResult.success('Oturum acildi.');
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Oturum acilamadi. Sunucu cevabi gecersiz.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return AuthResult.failure('Gecerli bir e-posta adresi girin.');
    }

    _busy = true;
    notifyListeners();
    try {
      await _repository.requestPasswordReset(normalized);
      return AuthResult.success(
        'Parola sifirlama baglantisi gonderildi. Gelen kutunuzu kontrol edin.',
      );
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Parola sifirlama istegi gonderilemedi.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> completeOnboarding(OnboardingProfile profile) async {
    if (_currentUser == null) {
      return AuthResult.failure('Aktif kullanici bulunamadi.');
    }

    _busy = true;
    notifyListeners();
    try {
      _currentUser = await _repository.completeOnboarding(profile);
      _stage = AuthStage.authenticated;
      final token = _apiClient.accessToken;
      if (_currentUser != null && token != null && token.isNotEmpty) {
        await _sessionStorage.write(
          AuthSession(token: token, user: _currentUser!),
        );
      }
      return AuthResult.success('Ilk giris kurulumu tamamlandi.');
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
      // Client state is still cleared even if server logout fails.
    }
    _apiClient.clearAccessToken();
    await _sessionStorage.clear();
    _currentUser = null;
    _stage = AuthStage.login;
    _busy = false;
    notifyListeners();
  }
}
