import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_theme.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';
import 'package:servis_kontrol/features/auth/domain/auth_result.dart';
import 'package:servis_kontrol/features/auth/presentation/login_page.dart';
import 'package:servis_kontrol/features/auth/presentation/onboarding_page.dart';
import 'package:servis_kontrol/features/shell/presentation/servis_kontrol_shell.dart';

class ServisKontrolApp extends StatefulWidget {
  const ServisKontrolApp({super.key, this.authController});

  final AuthController? authController;

  @override
  State<ServisKontrolApp> createState() => _ServisKontrolAppState();
}

class _ServisKontrolAppState extends State<ServisKontrolApp> {
  late final AuthController _authController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
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
                onComplete: _authController.completeOnboarding,
                onLogout: _authController.logout,
              );
            case AuthStage.authenticated:
              return ServisKontrolShell(
                user: _authController.currentUser!,
                onLogout: _authController.logout,
              );
          }
        },
      ),
    );
  }
}
