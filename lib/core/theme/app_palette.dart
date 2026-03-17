import 'package:flutter/material.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';

class AppPalette {
  static const background = Color(0xFFF5F7FB);
  static const surfaceMuted = Color(0xFFF8FAFD);
  static const card = Colors.white;
  static const sidebar = Color(0xFF06172F);
  static const sidebarSoft = Color(0xFF10284C);
  static const primary = Color(0xFF2558D8);
  static const primarySoft = Color(0xFFDDE8FF);
  static const text = Color(0xFF0C1F3D);
  static const muted = Color(0xFF667894);
  static const border = Color(0xFFD8E2F0);
  static const success = Color(0xFF2FA76B);
  static const warning = Color(0xFFE29D3A);
  static const danger = Color(0xFFD95C5C);
  static const shadow = Color(0x140A1E40);
}

@immutable
class AppRolePalette extends ThemeExtension<AppRolePalette> {
  const AppRolePalette({
    required this.background,
    required this.surfaceMuted,
    required this.sidebar,
    required this.sidebarSoft,
    required this.primary,
    required this.primarySoft,
    required this.text,
    required this.muted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color background;
  final Color surfaceMuted;
  final Color sidebar;
  final Color sidebarSoft;
  final Color primary;
  final Color primarySoft;
  final Color text;
  final Color muted;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;

  static const superAdmin = AppRolePalette(
    background: AppPalette.background,
    surfaceMuted: AppPalette.surfaceMuted,
    sidebar: AppPalette.sidebar,
    sidebarSoft: AppPalette.sidebarSoft,
    primary: AppPalette.primary,
    primarySoft: AppPalette.primarySoft,
    text: AppPalette.text,
    muted: AppPalette.muted,
    border: AppPalette.border,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    shadow: AppPalette.shadow,
  );

  static const manager = AppRolePalette(
    background: AppPalette.background,
    surfaceMuted: AppPalette.surfaceMuted,
    sidebar: Color(0xFF1F3044),
    sidebarSoft: Color(0xFF2E4A65),
    primary: Color(0xFFD97A1A),
    primarySoft: Color(0xFFFFF0DC),
    text: AppPalette.text,
    muted: AppPalette.muted,
    border: AppPalette.border,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    shadow: AppPalette.shadow,
  );

  static const teamLead = AppRolePalette(
    background: AppPalette.background,
    surfaceMuted: AppPalette.surfaceMuted,
    sidebar: Color(0xFF123B2A),
    sidebarSoft: Color(0xFF1D5E3E),
    primary: Color(0xFF2F8F5B),
    primarySoft: Color(0xFFDDF3E5),
    text: AppPalette.text,
    muted: AppPalette.muted,
    border: AppPalette.border,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    shadow: AppPalette.shadow,
  );

  static const employee = AppRolePalette(
    background: AppPalette.background,
    surfaceMuted: AppPalette.surfaceMuted,
    sidebar: Color(0xFF2B1D4E),
    sidebarSoft: Color(0xFF47308A),
    primary: Color(0xFF7B4FD6),
    primarySoft: Color(0xFFEDE6FC),
    text: AppPalette.text,
    muted: AppPalette.muted,
    border: AppPalette.border,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    shadow: AppPalette.shadow,
  );

  static AppRolePalette forRole(UserRole? role) => switch (role) {
    UserRole.manager => manager,
    UserRole.teamLead => teamLead,
    UserRole.employee => employee,
    _ => superAdmin,
  };

  @override
  AppRolePalette copyWith({
    Color? background,
    Color? surfaceMuted,
    Color? sidebar,
    Color? sidebarSoft,
    Color? primary,
    Color? primarySoft,
    Color? text,
    Color? muted,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
    Color? shadow,
  }) {
    return AppRolePalette(
      background: background ?? this.background,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      sidebar: sidebar ?? this.sidebar,
      sidebarSoft: sidebarSoft ?? this.sidebarSoft,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppRolePalette lerp(ThemeExtension<AppRolePalette>? other, double t) {
    if (other is! AppRolePalette) {
      return this;
    }

    return AppRolePalette(
      background: Color.lerp(background, other.background, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarSoft: Color.lerp(sidebarSoft, other.sidebarSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppRolePaletteContext on BuildContext {
  AppRolePalette get rolePalette =>
      Theme.of(this).extension<AppRolePalette>() ?? AppRolePalette.superAdmin;
}
