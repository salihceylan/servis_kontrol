import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/data/mock_auth_repository.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';

class AuthController extends ChangeNotifier {
  AuthController({MockAuthRepository? repository})
    : _repository = repository ?? MockAuthRepository();

  final MockAuthRepository _repository;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  AppUser? _currentUser;
  AuthStage _stage = AuthStage.login;

  List<DemoAccount> get demoAccounts => _repository.demoAccounts;
  AppUser? get currentUser => _currentUser;
  AuthStage get stage => _stage;

  bool get isLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  String get lockMessage {
    if (!isLocked || _lockedUntil == null) {
      return '';
    }
    final difference = _lockedUntil!.difference(DateTime.now());
    final minutes = difference.inMinutes.clamp(0, 59);
    final seconds = difference.inSeconds.remainder(60).clamp(0, 59);
    return '5 hatali deneme nedeniyle giris gecici olarak kilitlendi. '
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} sonra tekrar deneyin.';
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (isLocked) {
      return AuthResult.failure(lockMessage);
    }

    final user = await _repository.authenticate(email, password);
    if (user == null) {
      _failedAttempts += 1;
      if (_failedAttempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 15));
        notifyListeners();
        return AuthResult.failure(lockMessage);
      }
      notifyListeners();
      return AuthResult.failure(
        'Kullanici bilgileri hatali. '
        'Kalan deneme: ${5 - _failedAttempts}',
      );
    }

    _failedAttempts = 0;
    _lockedUntil = null;
    _currentUser = user;
    _stage = user.isFirstLogin ? AuthStage.onboarding : AuthStage.authenticated;
    notifyListeners();

    return AuthResult.success(
      'Giris basarili.',
    );
  }

  Future<AuthResult> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return AuthResult.failure('Gecerli bir e-posta adresi girin.');
    }

    final exists = await _repository.requestPasswordReset(normalized);
    if (exists) {
      return AuthResult.success(
        'Sifre sifirlama baglantisi $normalized adresine gonderildi.',
      );
    }

    return AuthResult.success(
      'Bu adres sistemde kayitliysa sifirlama baglantisi gonderilecektir.',
    );
  }

  void completeOnboarding(OnboardingProfile profile) {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    _currentUser = _repository.saveOnboarding(user.email, profile);
    _stage = AuthStage.authenticated;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _stage = AuthStage.login;
    notifyListeners();
  }
}
