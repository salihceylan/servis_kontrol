import 'package:servis_kontrol/features/auth/domain/user_role.dart';

enum NotificationChannel { system, email, slack }

extension NotificationChannelX on NotificationChannel {
  String get label => switch (this) {
    NotificationChannel.system => 'Uygulama içi',
    NotificationChannel.email => 'E-posta',
    NotificationChannel.slack => 'Slack',
  };
}

class OnboardingProfile {
  const OnboardingProfile({
    required this.fullName,
    required this.department,
    required this.jobTitle,
    required this.workPreference,
    required this.notificationChannels,
    required this.wantsQuickTour,
  });

  final String fullName;
  final String department;
  final String jobTitle;
  final String workPreference;
  final Set<NotificationChannel> notificationChannels;
  final bool wantsQuickTour;

  factory OnboardingProfile.fromUser(AppUser user) {
    return OnboardingProfile(
      fullName: user.name,
      department: user.department,
      jobTitle: user.jobTitle,
      workPreference: user.workPreference,
      notificationChannels: user.notificationChannels,
      wantsQuickTour: user.wantsQuickTour,
    );
  }
}

class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.jobTitle,
    required this.workPreference,
    required this.notificationChannels,
    required this.isFirstLogin,
    required this.wantsQuickTour,
  });

  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String jobTitle;
  final String workPreference;
  final Set<NotificationChannel> notificationChannels;
  final bool isFirstLogin;
  final bool wantsQuickTour;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? jobTitle,
    String? workPreference,
    Set<NotificationChannel>? notificationChannels,
    bool? isFirstLogin,
    bool? wantsQuickTour,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      workPreference: workPreference ?? this.workPreference,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      wantsQuickTour: wantsQuickTour ?? this.wantsQuickTour,
    );
  }
}
