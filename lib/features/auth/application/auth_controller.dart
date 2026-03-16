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
  }) : _apiClient = apiClient,
       _repository = repository ?? ApiAuthRepository(apiClient),
       _sessionStorage = sessionStorage ?? InMemoryAuthSessionStorage();

  final ApiClient _apiClient;
  final AuthRepository _repository;
  AuthSessionStorage _sessionStorage;
  AppUser? _currentUser;
  AuthStage _stage = AuthStage.login;
  bool _busy = false;
  bool _rememberSession = true;

  ApiClient get apiClient => _apiClient;
  AppUser? get currentUser => _currentUser;
  AuthStage get stage => _stage;
  bool get busy => _busy;
  bool get rememberSession => _rememberSession;

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
      _rememberSession = true;
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
    bool rememberSession = true,
  }) async {
    _rememberSession = rememberSession;
    _busy = true;
    notifyListeners();
    try {
      final session = await _repository.signIn(
        email: email,
        password: password,
      );
      _apiClient.updateAccessToken(session.token);
      _currentUser = session.user;
      _stage = session.user.isFirstLogin
          ? AuthStage.onboarding
          : AuthStage.authenticated;
      if (_rememberSession) {
        await _sessionStorage.write(session);
      } else {
        await _sessionStorage.clear();
      }
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
      return AuthResult.failure('Parola sıfırlama istegi gönderilemedi.');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> requestSignUp({
    required String companyName,
    required String fullName,
    required String email,
    String? phone,
  }) async {
    final normalizedCompanyName = companyName.trim();
    final normalizedFullName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone?.trim() ?? '';

    if (normalizedCompanyName.isEmpty) {
      return AuthResult.failure('Şirket adı gerekli.');
    }
    if (normalizedFullName.isEmpty) {
      return AuthResult.failure('Ad soyad gerekli.');
    }
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return AuthResult.failure('Geçerli bir e-posta adresi girin.');
    }

    _busy = true;
    notifyListeners();
    try {
      await _repository.requestSignUp(
        companyName: normalizedCompanyName,
        fullName: normalizedFullName,
        email: normalizedEmail,
        phone: normalizedPhone.isEmpty ? null : normalizedPhone,
      );
      return AuthResult.success(
        'Kayıt talebiniz alındı. Ekibimiz sizinle iletişime geçecek.',
      );
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Kayıt talebi gönderilemedi.');
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
      final token = _apiClient.accessToken;
      if (_currentUser != null && token != null && token.isNotEmpty) {
        if (_rememberSession) {
          await _sessionStorage.write(
            AuthSession(token: token, user: _currentUser!),
          );
        } else {
          await _sessionStorage.clear();
        }
      }
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
