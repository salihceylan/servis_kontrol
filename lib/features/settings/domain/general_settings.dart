class GeneralSettings {
  const GeneralSettings({
    required this.companyName,
    required this.companyCode,
    required this.defaultLanguage,
    required this.timezone,
    required this.weekStartsOn,
    required this.dateFormat,
    required this.notificationSummaryEnabled,
    required this.emailNotificationsEnabled,
    required this.slackNotificationsEnabled,
    required this.automationCenterEnabled,
    required this.workFormsEnabled,
    required this.timeTrackingEnabled,
    required this.permissionProfiles,
    required this.integrations,
  });

  final String companyName;
  final String companyCode;
  final String defaultLanguage;
  final String timezone;
  final String weekStartsOn;
  final String dateFormat;
  final bool notificationSummaryEnabled;
  final bool emailNotificationsEnabled;
  final bool slackNotificationsEnabled;
  final bool automationCenterEnabled;
  final bool workFormsEnabled;
  final bool timeTrackingEnabled;
  final List<PermissionProfile> permissionProfiles;
  final List<IntegrationSetting> integrations;

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    final permissionProfiles =
        (json['permission_profiles'] as List<dynamic>? ?? const [])
            .map((item) => PermissionProfile.fromJson(item as Map<String, dynamic>))
            .toList(growable: false);
    final integrations = (json['integrations'] as List<dynamic>? ?? const [])
        .map((item) => IntegrationSetting.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return GeneralSettings(
      companyName: json['company_name'] as String? ?? '',
      companyCode: json['company_code'] as String? ?? '',
      defaultLanguage: json['default_language'] as String? ?? 'tr',
      timezone: json['timezone'] as String? ?? 'Europe/Istanbul',
      weekStartsOn: json['week_starts_on'] as String? ?? 'monday',
      dateFormat: json['date_format'] as String? ?? 'dd.MM.yyyy',
      notificationSummaryEnabled:
          json['notification_summary_enabled'] as bool? ?? false,
      emailNotificationsEnabled:
          json['email_notifications_enabled'] as bool? ?? false,
      slackNotificationsEnabled:
          json['slack_notifications_enabled'] as bool? ?? false,
      automationCenterEnabled:
          json['automation_center_enabled'] as bool? ?? false,
      workFormsEnabled: json['work_forms_enabled'] as bool? ?? false,
      timeTrackingEnabled: json['time_tracking_enabled'] as bool? ?? false,
      permissionProfiles: permissionProfiles,
      integrations: integrations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_code': companyCode,
      'default_language': defaultLanguage,
      'timezone': timezone,
      'week_starts_on': weekStartsOn,
      'date_format': dateFormat,
      'notification_summary_enabled': notificationSummaryEnabled,
      'email_notifications_enabled': emailNotificationsEnabled,
      'slack_notifications_enabled': slackNotificationsEnabled,
      'automation_center_enabled': automationCenterEnabled,
      'work_forms_enabled': workFormsEnabled,
      'time_tracking_enabled': timeTrackingEnabled,
    };
  }

  GeneralSettings copyWith({
    String? companyName,
    String? companyCode,
    String? defaultLanguage,
    String? timezone,
    String? weekStartsOn,
    String? dateFormat,
    bool? notificationSummaryEnabled,
    bool? emailNotificationsEnabled,
    bool? slackNotificationsEnabled,
    bool? automationCenterEnabled,
    bool? workFormsEnabled,
    bool? timeTrackingEnabled,
    List<PermissionProfile>? permissionProfiles,
    List<IntegrationSetting>? integrations,
  }) {
    return GeneralSettings(
      companyName: companyName ?? this.companyName,
      companyCode: companyCode ?? this.companyCode,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      timezone: timezone ?? this.timezone,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      dateFormat: dateFormat ?? this.dateFormat,
      notificationSummaryEnabled:
          notificationSummaryEnabled ?? this.notificationSummaryEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      slackNotificationsEnabled:
          slackNotificationsEnabled ?? this.slackNotificationsEnabled,
      automationCenterEnabled:
          automationCenterEnabled ?? this.automationCenterEnabled,
      workFormsEnabled: workFormsEnabled ?? this.workFormsEnabled,
      timeTrackingEnabled: timeTrackingEnabled ?? this.timeTrackingEnabled,
      permissionProfiles: permissionProfiles ?? this.permissionProfiles,
      integrations: integrations ?? this.integrations,
    );
  }
}

class PermissionProfile {
  const PermissionProfile({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  factory PermissionProfile.fromJson(Map<String, dynamic> json) {
    return PermissionProfile(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class IntegrationSetting {
  const IntegrationSetting({
    required this.name,
    required this.statusLabel,
    required this.connected,
  });

  final String name;
  final String statusLabel;
  final bool connected;

  factory IntegrationSetting.fromJson(Map<String, dynamic> json) {
    return IntegrationSetting(
      name: json['name'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      connected: json['connected'] as bool? ?? false,
    );
  }
}
