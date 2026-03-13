import 'package:servis_kontrol/features/auth/domain/user_role.dart';

enum NotificationChannel { system, email, slack }

extension NotificationChannelX on NotificationChannel {
  String get label => switch (this) {
    NotificationChannel.system => 'Uygulama içi',
    NotificationChannel.email => 'E-posta',
    NotificationChannel.slack => 'Slack',
  };

  String get apiValue => switch (this) {
    NotificationChannel.system => 'system',
    NotificationChannel.email => 'email',
    NotificationChannel.slack => 'slack',
  };
}

NotificationChannel notificationChannelFromApi(String? value) => switch (value) {
  'email' => NotificationChannel.email,
  'slack' => NotificationChannel.slack,
  _ => NotificationChannel.system,
};

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

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'department': department,
      'job_title': jobTitle,
      'work_preference': workPreference,
      'notification_channels': notificationChannels
          .map((channel) => channel.apiValue)
          .toList(growable: false),
      'wants_quick_tour': wantsQuickTour,
    };
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
    this.id,
    this.userCode,
    this.companyId,
    this.companyCode,
    this.positionName,
    this.teamName,
    this.permissions = const <String>{},
  });

  final String? id;
  final String? userCode;
  final String? companyId;
  final String? companyCode;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String jobTitle;
  final String workPreference;
  final Set<NotificationChannel> notificationChannels;
  final bool isFirstLogin;
  final bool wantsQuickTour;
  final String? positionName;
  final String? teamName;
  final Set<String> permissions;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final notificationChannels =
        (json['notification_channels'] as List<dynamic>? ?? const [])
            .map((item) => notificationChannelFromApi(item as String?))
            .toSet();

    final permissions =
        (json['permissions'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toSet();

    return AppUser(
      id: json['id']?.toString(),
      userCode: json['user_code']?.toString(),
      companyId: json['company_id']?.toString(),
      companyCode: json['company_code']?.toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: userRoleFromApi(json['role'] as String?),
      department: json['department'] as String? ?? '',
      jobTitle: json['job_title'] as String? ?? '',
      workPreference: json['work_preference'] as String? ?? '',
      notificationChannels: notificationChannels,
      isFirstLogin: json['is_first_login'] as bool? ?? false,
      wantsQuickTour: json['wants_quick_tour'] as bool? ?? false,
      positionName: json['position_name'] as String?,
      teamName: json['team_name'] as String?,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_code': userCode,
      'company_id': companyId,
      'company_code': companyCode,
      'name': name,
      'email': email,
      'role': userRoleToApi(role),
      'department': department,
      'job_title': jobTitle,
      'work_preference': workPreference,
      'notification_channels': notificationChannels
          .map((channel) => channel.apiValue)
          .toList(growable: false),
      'is_first_login': isFirstLogin,
      'wants_quick_tour': wantsQuickTour,
      'position_name': positionName,
      'team_name': teamName,
      'permissions': permissions.toList(growable: false),
    };
  }

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
    String? id,
    String? userCode,
    String? companyId,
    String? companyCode,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? jobTitle,
    String? workPreference,
    Set<NotificationChannel>? notificationChannels,
    bool? isFirstLogin,
    bool? wantsQuickTour,
    String? positionName,
    String? teamName,
    Set<String>? permissions,
  }) {
    return AppUser(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      companyId: companyId ?? this.companyId,
      companyCode: companyCode ?? this.companyCode,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      jobTitle: jobTitle ?? this.jobTitle,
      workPreference: workPreference ?? this.workPreference,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      wantsQuickTour: wantsQuickTour ?? this.wantsQuickTour,
      positionName: positionName ?? this.positionName,
      teamName: teamName ?? this.teamName,
      permissions: permissions ?? this.permissions,
    );
  }
}
