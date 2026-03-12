import 'package:flutter/material.dart';

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
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;
}

class DashboardNotification {
  const DashboardNotification({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;
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
}
