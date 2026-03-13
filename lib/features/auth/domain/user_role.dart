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

  String get apiValue => switch (this) {
    UserRole.employee => 'employee',
    UserRole.teamLead => 'team_lead',
    UserRole.manager => 'manager',
  };
}

UserRole userRoleFromApi(String? value) => switch (value) {
  'employee' => UserRole.employee,
  'team_lead' => UserRole.teamLead,
  'teamLead' => UserRole.teamLead,
  'manager' => UserRole.manager,
  _ => UserRole.employee,
};

String userRoleToApi(UserRole role) => role.apiValue;
