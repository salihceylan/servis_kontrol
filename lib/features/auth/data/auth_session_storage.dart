import 'dart:convert';

import 'package:servis_kontrol/features/auth/domain/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthSessionStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class InMemoryAuthSessionStorage implements AuthSessionStorage {
  AuthSession? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async {
    _session = session;
  }
}

class SharedPrefsAuthSessionStorage implements AuthSessionStorage {
  SharedPrefsAuthSessionStorage._(this._preferences);

  static const _tokenKey = 'workflow.auth.token';
  static const _userKey = 'workflow.auth.user';

  final SharedPreferences _preferences;

  static Future<SharedPrefsAuthSessionStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPrefsAuthSessionStorage._(preferences);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_userKey);
  }

  @override
  Future<AuthSession?> read() async {
    final token = _preferences.getString(_tokenKey);
    final userJson = _preferences.getString(_userKey);
    if (token == null || token.trim().isEmpty || userJson == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return AuthSession.fromJson({
        'token': token,
        'user': decoded,
      });
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    await _preferences.setString(_tokenKey, session.token);
    await _preferences.setString(_userKey, jsonEncode(session.user.toJson()));
  }
}
