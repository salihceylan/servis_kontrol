enum UserRole { employee, teamLead, manager }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.employee => 'Çalışan',
    UserRole.teamLead => 'Ekip Lideri',
    UserRole.manager => 'Yönetici',
  };

  String get dashboardSubtitle => switch (this) {
    UserRole.employee =>
      'Bugün üzerinde çalıştığın görevler, revizyonlar ve bireysel metrikler burada.',
    UserRole.teamLead =>
      'Ekibinin görev akışı, revizyon kuyruğu ve operasyon öncelikleri burada.',
    UserRole.manager =>
      'Operasyon, ekip kartları, KPI ve erken uyarı özetleri burada.',
  };

  String get primaryActionLabel => switch (this) {
    UserRole.employee => 'Teslim Güncelle',
    UserRole.teamLead => 'Revizyonları İncele',
    UserRole.manager => 'Görev Ata',
  };
}
