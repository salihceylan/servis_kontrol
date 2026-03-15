enum UserRole { employee, teamLead, manager, superAdmin, sales, support }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.employee => 'Çalışan',
    UserRole.teamLead => 'Ekip Lideri',
    UserRole.manager => 'Yönetici',
    UserRole.superAdmin => 'Super Admin',
    UserRole.sales => 'Satis',
    UserRole.support => 'Destek',
  };

  String get dashboardSubtitle => switch (this) {
    UserRole.employee =>
      'Bugün üzerinde çalıştığın görevler, revizyonlar ve bireysel metrikler burada.',
    UserRole.teamLead =>
      'Ekibinin görev akışı, revizyon kuyruğu ve operasyon öncelikleri burada.',
    UserRole.manager =>
      'Operasyon, ekip kartları, KPI ve erken uyarı özetleri burada.',
    UserRole.superAdmin =>
      'SaaS operasyonu, musteriler ve lisans yonetimi tek panelde.',
    UserRole.sales => 'Demo, teklif ve musteri gecisleri bu panelde yonetilir.',
    UserRole.support =>
      'Destek talepleri, tenant erisim kayitlari ve musteri takibi burada.',
  };

  String get primaryActionLabel => switch (this) {
    UserRole.employee => 'Teslim Güncelle',
    UserRole.teamLead => 'Revizyonları İncele',
    UserRole.manager => 'Görev Ata',
    UserRole.superAdmin => 'Yeni Sirket',
    UserRole.sales => 'Demo Hazirla',
    UserRole.support => 'Destek Kaydi',
  };

  String get apiValue => switch (this) {
    UserRole.employee => 'employee',
    UserRole.teamLead => 'team_lead',
    UserRole.manager => 'manager',
    UserRole.superAdmin => 'super_admin',
    UserRole.sales => 'sales',
    UserRole.support => 'support',
  };

  bool get isOwnerPortalRole => switch (this) {
    UserRole.superAdmin || UserRole.sales || UserRole.support => true,
    _ => false,
  };
}

UserRole userRoleFromApi(String? value) => switch (value) {
  'employee' => UserRole.employee,
  'team_lead' => UserRole.teamLead,
  'teamLead' => UserRole.teamLead,
  'manager' => UserRole.manager,
  'super_admin' => UserRole.superAdmin,
  'superAdmin' => UserRole.superAdmin,
  'sales' => UserRole.sales,
  'support' => UserRole.support,
  _ => UserRole.employee,
};

String userRoleToApi(UserRole role) => role.apiValue;
