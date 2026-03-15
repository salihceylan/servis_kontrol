import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';

class OwnerDashboardSnapshot {
  const OwnerDashboardSnapshot({
    required this.title,
    required this.subtitle,
    required this.summaryCards,
    required this.planBreakdown,
    required this.recentRequests,
    required this.companyWatchlist,
  });

  final String title;
  final String subtitle;
  final List<OwnerMetric> summaryCards;
  final List<OwnerPlanBreakdown> planBreakdown;
  final List<OwnerRequestItem> recentRequests;
  final List<OwnerCompanyItem> companyWatchlist;

  factory OwnerDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardSnapshot(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      summaryCards: _readList(json['summary_cards'], OwnerMetric.fromJson),
      planBreakdown: _readList(
        json['plan_breakdown'],
        OwnerPlanBreakdown.fromJson,
      ),
      recentRequests: _readList(
        json['recent_requests'],
        OwnerRequestItem.fromJson,
      ),
      companyWatchlist: _readList(
        json['company_watchlist'],
        OwnerCompanyItem.fromJson,
      ),
    );
  }
}

class OwnerMetric {
  const OwnerMetric({
    required this.label,
    required this.value,
    required this.caption,
    required this.accentKey,
    required this.iconKey,
  });

  final String label;
  final String value;
  final String caption;
  final String accentKey;
  final String iconKey;

  factory OwnerMetric.fromJson(Map<String, dynamic> json) {
    return OwnerMetric(
      label: json['label'] as String? ?? '',
      value: '${json['value'] ?? ''}',
      caption: json['caption'] as String? ?? '',
      accentKey: json['accent'] as String? ?? 'primary',
      iconKey: json['icon'] as String? ?? 'grid',
    );
  }

  Color get color => switch (accentKey) {
    'success' => AppPalette.success,
    'warning' => AppPalette.warning,
    'danger' => AppPalette.danger,
    'violet' => const Color(0xFF7C5CE6),
    _ => AppPalette.primary,
  };

  IconData get icon => switch (iconKey) {
    'business' => Icons.apartment_rounded,
    'users' => Icons.groups_2_rounded,
    'task' => Icons.task_alt_rounded,
    'support' => Icons.support_agent_rounded,
    _ => Icons.grid_view_rounded,
  };
}

class OwnerPlanBreakdown {
  const OwnerPlanBreakdown({
    required this.planName,
    required this.companyCount,
  });

  final String planName;
  final int companyCount;

  factory OwnerPlanBreakdown.fromJson(Map<String, dynamic> json) {
    return OwnerPlanBreakdown(
      planName: json['plan_name'] as String? ?? '',
      companyCount: json['company_count'] as int? ?? 0,
    );
  }
}

class OwnerCompanyItem {
  const OwnerCompanyItem({
    required this.id,
    required this.companyCode,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.ownerEmail,
    required this.timezone,
    required this.locale,
    required this.createdAt,
    required this.subscription,
    required this.stats,
  });

  final String id;
  final String companyCode;
  final String name;
  final String status;
  final String ownerName;
  final String ownerEmail;
  final String timezone;
  final String locale;
  final DateTime? createdAt;
  final OwnerCompanySubscription subscription;
  final OwnerCompanyStats stats;

  factory OwnerCompanyItem.fromJson(Map<String, dynamic> json) {
    return OwnerCompanyItem(
      id: json['id']?.toString() ?? '',
      companyCode: json['company_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      ownerName: json['owner_name'] as String? ?? '',
      ownerEmail: json['owner_email'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      subscription: OwnerCompanySubscription.fromJson(
        json['subscription'] as Map<String, dynamic>? ?? const {},
      ),
      stats: OwnerCompanyStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  String get statusLabel => switch (status) {
    'active' => 'Aktif',
    'paused' => 'Beklemede',
    _ => 'Pasif',
  };

  Color get statusColor => switch (status) {
    'active' => AppPalette.success,
    'paused' => AppPalette.warning,
    _ => AppPalette.muted,
  };
}

class OwnerCompanyDetail {
  const OwnerCompanyDetail({
    required this.id,
    required this.companyCode,
    required this.name,
    required this.status,
    required this.timezone,
    required this.locale,
    required this.createdAt,
    required this.ownerName,
    required this.ownerEmail,
    required this.subscription,
    required this.support,
    required this.stats,
    required this.recentActivity,
    required this.loginActivity,
  });

  final String id;
  final String companyCode;
  final String name;
  final String status;
  final String timezone;
  final String locale;
  final DateTime? createdAt;
  final String ownerName;
  final String ownerEmail;
  final OwnerCompanySubscription subscription;
  final OwnerSupportSettings support;
  final OwnerCompanyStats stats;
  final List<OwnerActivityItem> recentActivity;
  final List<OwnerLoginActivityItem> loginActivity;

  factory OwnerCompanyDetail.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return OwnerCompanyDetail(
      id: json['id']?.toString() ?? '',
      companyCode: json['company_code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      timezone: json['timezone'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      ownerName: owner['name'] as String? ?? '',
      ownerEmail: owner['email'] as String? ?? '',
      subscription: OwnerCompanySubscription.fromJson(
        json['subscription'] as Map<String, dynamic>? ?? const {},
      ),
      support: OwnerSupportSettings.fromJson(
        json['support'] as Map<String, dynamic>? ?? const {},
      ),
      stats: OwnerCompanyStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      recentActivity: _readList(
        json['recent_activity'],
        OwnerActivityItem.fromJson,
      ),
      loginActivity: _readList(
        json['login_activity'],
        OwnerLoginActivityItem.fromJson,
      ),
    );
  }

  String get statusLabel => switch (status) {
    'active' => 'Aktif',
    'paused' => 'Beklemede',
    _ => 'Pasif',
  };
}

class OwnerCompanySubscription {
  const OwnerCompanySubscription({
    required this.planName,
    required this.userLimit,
    required this.storageLimitGb,
    required this.licenseEndsAt,
    required this.modules,
  });

  final String planName;
  final int userLimit;
  final int storageLimitGb;
  final DateTime? licenseEndsAt;
  final OwnerCompanyModules modules;

  factory OwnerCompanySubscription.fromJson(Map<String, dynamic> json) {
    return OwnerCompanySubscription(
      planName: json['plan_name'] as String? ?? 'Scale',
      userLimit: json['user_limit'] as int? ?? 0,
      storageLimitGb: json['storage_limit_gb'] as int? ?? 0,
      licenseEndsAt: _parseDate(json['license_ends_at']),
      modules: OwnerCompanyModules.fromJson(
        json['modules'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class OwnerCompanyModules {
  const OwnerCompanyModules({
    required this.reports,
    required this.revisions,
    required this.automations,
    required this.requestForms,
  });

  final bool reports;
  final bool revisions;
  final bool automations;
  final bool requestForms;

  factory OwnerCompanyModules.fromJson(Map<String, dynamic> json) {
    return OwnerCompanyModules(
      reports: json['reports'] as bool? ?? false,
      revisions: json['revisions'] as bool? ?? false,
      automations: json['automations'] as bool? ?? false,
      requestForms: json['request_forms'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reports': reports,
      'revisions': revisions,
      'automations': automations,
      'request_forms': requestForms,
    };
  }
}

class OwnerCompanyStats {
  const OwnerCompanyStats({
    required this.activeUsers,
    required this.taskCount,
    required this.openTasks,
    required this.openRevisions,
    required this.storageUsedBytes,
    required this.lastLoginAt,
  });

  final int activeUsers;
  final int taskCount;
  final int openTasks;
  final int openRevisions;
  final int storageUsedBytes;
  final DateTime? lastLoginAt;

  factory OwnerCompanyStats.fromJson(Map<String, dynamic> json) {
    return OwnerCompanyStats(
      activeUsers: json['active_users'] as int? ?? 0,
      taskCount: json['task_count'] as int? ?? 0,
      openTasks: json['open_tasks'] as int? ?? 0,
      openRevisions: json['open_revisions'] as int? ?? 0,
      storageUsedBytes: json['storage_used_bytes'] as int? ?? 0,
      lastLoginAt: _parseDate(json['last_login_at']),
    );
  }

  double get storageUsedGb => storageUsedBytes / (1024 * 1024 * 1024);
}

class OwnerSupportSettings {
  const OwnerSupportSettings({
    required this.supportEmail,
    required this.responseSla,
  });

  final String supportEmail;
  final String responseSla;

  factory OwnerSupportSettings.fromJson(Map<String, dynamic> json) {
    return OwnerSupportSettings(
      supportEmail: json['support_email'] as String? ?? '',
      responseSla: json['response_sla'] as String? ?? '',
    );
  }
}

class OwnerActivityItem {
  const OwnerActivityItem({
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  final String title;
  final String detail;
  final DateTime? createdAt;

  factory OwnerActivityItem.fromJson(Map<String, dynamic> json) {
    return OwnerActivityItem(
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class OwnerLoginActivityItem {
  const OwnerLoginActivityItem({
    required this.email,
    required this.isSuccess,
    required this.ipAddress,
    required this.attemptedAt,
  });

  final String email;
  final bool isSuccess;
  final String ipAddress;
  final DateTime? attemptedAt;

  factory OwnerLoginActivityItem.fromJson(Map<String, dynamic> json) {
    return OwnerLoginActivityItem(
      email: json['email'] as String? ?? '',
      isSuccess: json['is_success'] as bool? ?? false,
      ipAddress: json['ip_address'] as String? ?? '',
      attemptedAt: _parseDate(json['attempted_at']),
    );
  }
}

class OwnerSupportSnapshot {
  const OwnerSupportSnapshot({
    required this.companies,
    required this.accessLogs,
  });

  final List<OwnerCompanyItem> companies;
  final List<OwnerSupportAccessLog> accessLogs;

  factory OwnerSupportSnapshot.fromJson(Map<String, dynamic> json) {
    return OwnerSupportSnapshot(
      companies: _readList(json['companies'], OwnerCompanyItem.fromJson),
      accessLogs: _readList(
        json['access_logs'],
        OwnerSupportAccessLog.fromJson,
      ),
    );
  }
}

class OwnerSupportAccessLog {
  const OwnerSupportAccessLog({
    required this.companyId,
    required this.companyName,
    required this.actorName,
    required this.actorEmail,
    required this.createdAt,
  });

  final String companyId;
  final String companyName;
  final String actorName;
  final String actorEmail;
  final DateTime? createdAt;

  factory OwnerSupportAccessLog.fromJson(Map<String, dynamic> json) {
    return OwnerSupportAccessLog(
      companyId: json['company_id']?.toString() ?? '',
      companyName: json['company_name'] as String? ?? '',
      actorName: json['actor_name'] as String? ?? '',
      actorEmail: json['actor_email'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class OwnerRequestsSnapshot {
  const OwnerRequestsSnapshot({required this.items});

  final List<OwnerRequestItem> items;

  factory OwnerRequestsSnapshot.fromJson(Map<String, dynamic> json) {
    return OwnerRequestsSnapshot(
      items: _readList(json['items'], OwnerRequestItem.fromJson),
    );
  }
}

class OwnerRequestItem {
  const OwnerRequestItem({
    required this.type,
    required this.email,
    required this.fullName,
    required this.companyName,
    required this.phone,
    required this.ipAddress,
    required this.createdAt,
  });

  final String type;
  final String email;
  final String fullName;
  final String companyName;
  final String phone;
  final String ipAddress;
  final DateTime? createdAt;

  factory OwnerRequestItem.fromJson(Map<String, dynamic> json) {
    return OwnerRequestItem(
      type: json['type'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get typeLabel => switch (type) {
    'sign_up_requested' => 'Kaydol',
    'forgot_password_requested' => 'Sifre Sifirlama',
    _ => 'Talep',
  };

  Color get typeColor => switch (type) {
    'sign_up_requested' => AppPalette.primary,
    'forgot_password_requested' => AppPalette.warning,
    _ => AppPalette.muted,
  };
}

class OwnerCompanyDraft {
  const OwnerCompanyDraft({
    required this.companyName,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
    required this.departmentName,
    required this.teamName,
    required this.timezone,
    required this.locale,
    required this.planName,
    required this.userLimit,
    required this.storageLimitGb,
    required this.licenseEndsAt,
    required this.supportEmail,
    required this.responseSla,
    required this.modules,
  });

  final String companyName;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final String departmentName;
  final String teamName;
  final String timezone;
  final String locale;
  final String planName;
  final int userLimit;
  final int storageLimitGb;
  final DateTime licenseEndsAt;
  final String supportEmail;
  final String responseSla;
  final OwnerCompanyModules modules;

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_password': adminPassword,
      'department_name': departmentName,
      'team_name': teamName,
      'timezone': timezone,
      'locale': locale,
      'plan_name': planName,
      'user_limit': userLimit,
      'storage_limit_gb': storageLimitGb,
      'license_ends_at': licenseEndsAt.toIso8601String(),
      'support_email': supportEmail,
      'response_sla': responseSla,
      'modules': modules.toJson(),
    };
  }
}

class OwnerCompanyProfileUpdate {
  const OwnerCompanyProfileUpdate({
    required this.companyId,
    required this.companyName,
    required this.status,
    required this.timezone,
    required this.locale,
    required this.supportEmail,
    required this.responseSla,
  });

  final String companyId;
  final String companyName;
  final String status;
  final String timezone;
  final String locale;
  final String supportEmail;
  final String responseSla;

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'status': status,
      'timezone': timezone,
      'locale': locale,
      'support_email': supportEmail,
      'response_sla': responseSla,
    };
  }
}

class OwnerSubscriptionUpdate {
  const OwnerSubscriptionUpdate({
    required this.companyId,
    required this.planName,
    required this.userLimit,
    required this.storageLimitGb,
    required this.licenseEndsAt,
    required this.modules,
  });

  final String companyId;
  final String planName;
  final int userLimit;
  final int storageLimitGb;
  final DateTime licenseEndsAt;
  final OwnerCompanyModules modules;

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'user_limit': userLimit,
      'storage_limit_gb': storageLimitGb,
      'license_ends_at': licenseEndsAt.toIso8601String(),
      'modules': modules.toJson(),
    };
  }
}

List<T> _readList<T>(
  Object? source,
  T Function(Map<String, dynamic> json) parser,
) {
  final list = source as List<dynamic>? ?? const [];
  return list
      .map((item) => parser(item as Map<String, dynamic>))
      .toList(growable: false);
}

DateTime? _parseDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}
