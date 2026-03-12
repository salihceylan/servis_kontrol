import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/config/runtime_config.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/theme/app_theme.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';
import 'package:servis_kontrol/features/auth/presentation/login_page.dart';
import 'package:servis_kontrol/features/auth/presentation/onboarding_page.dart';
import 'package:servis_kontrol/features/shell/presentation/servis_kontrol_shell.dart';

class ServisKontrolApp extends StatefulWidget {
  const ServisKontrolApp({
    super.key,
    this.authController,
    this.apiClient,
  });

  final AuthController? authController;
  final ApiClient? apiClient;

  @override
  State<ServisKontrolApp> createState() => _ServisKontrolAppState();
}

class _ServisKontrolAppState extends State<ServisKontrolApp> {
  late final ApiClient _apiClient;
  late final AuthController _authController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(baseUrl: RuntimeConfig.apiBaseUrl);
    _ownsController = widget.authController == null;
    _authController =
        widget.authController ?? AuthController(apiClient: _apiClient);
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
      home: AnimatedBuilder(
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
      ),
    );
  }
}
