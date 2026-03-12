import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.title,
    required this.subtitle,
    required this.heroTitle,
    required this.heroMessage,
    required this.heroHighlight,
    required this.summaryCards,
    required this.kpiCards,
    required this.notifications,
    required this.focusItems,
    required this.projects,
  });

  final String title;
  final String subtitle;
  final String heroTitle;
  final String heroMessage;
  final String heroHighlight;
  final List<DashboardMetric> summaryCards;
  final List<DashboardMetric> kpiCards;
  final List<DashboardNotification> notifications;
  final List<DashboardFocusItem> focusItems;
  final List<DashboardProject> projects;

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(
      String key,
      T Function(Map<String, dynamic> json) parser,
    ) {
      final source = json[key] as List<dynamic>? ?? const [];
      return source
          .map((item) => parser(item as Map<String, dynamic>))
          .toList(growable: false);
    }

    return DashboardSnapshot(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      heroTitle: json['hero_title'] as String? ?? '',
      heroMessage: json['hero_message'] as String? ?? '',
      heroHighlight: json['hero_highlight'] as String? ?? '',
      summaryCards: readList('summary_cards', DashboardMetric.fromJson),
      kpiCards: readList('kpi_cards', DashboardMetric.fromJson),
      notifications: readList('notifications', DashboardNotification.fromJson),
      focusItems: readList('focus_items', DashboardFocusItem.fromJson),
      projects: readList('projects', DashboardProject.fromJson),
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
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

  Color get color => dashboardAccentColor(accentKey);
  IconData get icon => dashboardIcon(iconKey);

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      label: json['label'] as String? ?? '',
      value: '${json['value'] ?? ''}',
      caption: json['caption'] as String? ?? '',
      accentKey: json['accent'] as String? ?? 'primary',
      iconKey: json['icon'] as String? ?? 'chart',
    );
  }
}

class DashboardNotification {
  const DashboardNotification({
    required this.title,
    required this.subtitle,
    required this.accentKey,
  });

  final String title;
  final String subtitle;
  final String accentKey;

  Color get color => dashboardAccentColor(accentKey);

  factory DashboardNotification.fromJson(Map<String, dynamic> json) {
    return DashboardNotification(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      accentKey: json['accent'] as String? ?? 'primary',
    );
  }
}

class DashboardFocusItem {
  const DashboardFocusItem({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  factory DashboardFocusItem.fromJson(Map<String, dynamic> json) {
    return DashboardFocusItem(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
    );
  }
}

class DashboardProject {
  const DashboardProject({
    required this.name,
    required this.type,
    required this.progress,
  });

  final String name;
  final String type;
  final double progress;

  factory DashboardProject.fromJson(Map<String, dynamic> json) {
    return DashboardProject(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}

Color dashboardAccentColor(String key) => switch (key) {
  'success' => AppPalette.success,
  'warning' => AppPalette.warning,
  'danger' => AppPalette.danger,
  'violet' => const Color(0xFF7A7AE6),
  _ => AppPalette.primary,
};

IconData dashboardIcon(String key) => switch (key) {
  'play' => Icons.play_circle_fill_rounded,
  'schedule' => Icons.schedule_rounded,
  'review' => Icons.rate_review_rounded,
  'done' => Icons.done_all_rounded,
  'kpi' => Icons.query_stats_rounded,
  'time' => Icons.timelapse_rounded,
  'smile' => Icons.sentiment_satisfied_alt_rounded,
  'verified' => Icons.verified_rounded,
  'sync' => Icons.sync_alt_rounded,
  'thumb' => Icons.thumb_up_alt_rounded,
  'insights' => Icons.insights_rounded,
  'timer' => Icons.av_timer_rounded,
  _ => Icons.grid_view_rounded,
};
