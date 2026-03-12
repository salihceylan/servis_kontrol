enum UserRole { employee, teamLead, manager }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.employee => 'Calisan',
    UserRole.teamLead => 'Ekip Lideri',
    UserRole.manager => 'Yonetici',
  };

  String get dashboardSubtitle => switch (this) {
    UserRole.employee =>
      'Bugun uzerinde calistigin gorevler, revizyonlar ve bireysel metrikler burada.',
    UserRole.teamLead =>
      'Ekibinin gorev akisi, revizyon kuyrugu ve operasyon oncelikleri burada.',
    UserRole.manager =>
      'Operasyon, ekip kartlari, KPI ve erken uyari ozetleri burada.',
  };

  String get primaryActionLabel => switch (this) {
    UserRole.employee => 'Teslim Guncelle',
    UserRole.teamLead => 'Revizyonlari Incele',
    UserRole.manager => 'Gorev Ata',
  };
}
