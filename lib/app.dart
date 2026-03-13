import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/config/runtime_config.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/theme/app_theme.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';
import 'package:servis_kontrol/features/auth/data/auth_session_storage.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';
import 'package:servis_kontrol/features/auth/presentation/login_page.dart';
import 'package:servis_kontrol/features/auth/presentation/onboarding_page.dart';
import 'package:servis_kontrol/features/shell/presentation/servis_kontrol_shell.dart';

class ServisKontrolApp extends StatefulWidget {
  const ServisKontrolApp({
    super.key,
    this.authController,
    this.apiClient,
    this.sessionStorage,
  });

  final AuthController? authController;
  final ApiClient? apiClient;
  final AuthSessionStorage? sessionStorage;

  @override
  State<ServisKontrolApp> createState() => _ServisKontrolAppState();
}

class _ServisKontrolAppState extends State<ServisKontrolApp> {
  late final ApiClient _apiClient;
  late final AuthController _authController;
  late final bool _ownsController;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(baseUrl: RuntimeConfig.apiBaseUrl);
    _ownsController = widget.authController == null;
    _authController = widget.authController ?? AuthController(apiClient: _apiClient);
    _bootstrapFuture = _bootstrap();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _authController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServisKontrol Pro',
      theme: AppTheme.light(),
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _BootstrapPage();
          }

          return AnimatedBuilder(
            animation: _authController,
            builder: (context, _) {
              switch (_authController.stage) {
                case AuthStage.login:
                  return LoginPage(controller: _authController);
                case AuthStage.onboarding:
                  return OnboardingPage(
                    user: _authController.currentUser!,
                    controller: _authController,
                    onLogout: _authController.logout,
                  );
                case AuthStage.authenticated:
                  return ServisKontrolShell(
                    user: _authController.currentUser!,
                    apiClient: _authController.apiClient,
                    onLogout: _authController.logout,
                  );
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _bootstrap() async {
    if (widget.sessionStorage != null) {
      _authController.updateSessionStorage(widget.sessionStorage!);
      await _authController.restoreSession();
      return;
    }

    if (_ownsController) {
      final sessionStorage = await SharedPrefsAuthSessionStorage.create();
      _authController.updateSessionStorage(sessionStorage);
    }

    await _authController.restoreSession();
  }
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
