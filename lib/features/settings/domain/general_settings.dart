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

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
