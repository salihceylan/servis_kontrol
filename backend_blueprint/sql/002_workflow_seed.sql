BEGIN;

INSERT INTO permissions (module, action, code)
VALUES
  ('dashboard', 'view', 'dashboard.view'),
  ('tasks', 'view', 'tasks.view'),
  ('tasks', 'assign', 'tasks.assign'),
  ('tasks', 'comment', 'tasks.comment'),
  ('tasks', 'submit', 'tasks.submit'),
  ('revisions', 'view', 'revisions.view'),
  ('revisions', 'approve', 'revisions.approve'),
  ('revisions', 'request', 'revisions.request'),
  ('team', 'view', 'team.view'),
  ('team', 'manage', 'team.manage'),
  ('team', 'note', 'team.note'),
  ('performance', 'view', 'performance.view'),
  ('reports', 'view', 'reports.view'),
  ('reports', 'create', 'reports.create'),
  ('settings', 'view', 'settings.view'),
  ('settings', 'update', 'settings.update'),
  ('help', 'view', 'help.view')
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION wf_seed_company_defaults(target_company_id BIGINT)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO company_settings (
    company_id,
    workday_start,
    workday_end,
    default_report_format,
    default_notification_channel,
    revision_warning_threshold,
    task_due_warning_hours,
    allow_email_reports,
    allow_slack_reports
  )
  VALUES (
    target_company_id,
    '08:30',
    '18:00',
    'pdf',
    'system',
    3,
    24,
    TRUE,
    FALSE
  )
  ON CONFLICT (company_id) DO NOTHING;

  INSERT INTO departments (company_id, name, code)
  VALUES
    (target_company_id, 'Operasyon', 'operasyon'),
    (target_company_id, 'Saha Operasyon', 'saha_operasyon'),
    (target_company_id, 'Teknik Servis', 'teknik_servis'),
    (target_company_id, 'Yonetim', 'yonetim')
  ON CONFLICT (company_id, code) DO NOTHING;

  INSERT INTO positions (company_id, name, code, level)
  VALUES
    (target_company_id, 'Sirket Sahibi', 'company_owner', 5),
    (target_company_id, 'Operasyon Yoneticisi', 'operations_manager', 4),
    (target_company_id, 'Ekip Lideri', 'team_lead', 3),
    (target_company_id, 'Teknik Uzman', 'technical_specialist', 2),
    (target_company_id, 'Saha Teknisyeni', 'field_technician', 1)
  ON CONFLICT (company_id, code) DO NOTHING;

  INSERT INTO roles (company_id, name, code, is_system_role)
  VALUES
    (target_company_id, 'Yonetici', 'manager', TRUE),
    (target_company_id, 'Ekip Lideri', 'team_lead', TRUE),
    (target_company_id, 'Calisan', 'employee', TRUE)
  ON CONFLICT (company_id, code) DO NOTHING;

  INSERT INTO task_statuses (company_id, name, code, sort_order, is_closed)
  VALUES
    (target_company_id, 'Beklemede', 'pending', 1, FALSE),
    (target_company_id, 'Devam Ediyor', 'in_progress', 2, FALSE),
    (target_company_id, 'Incelemede', 'in_review', 3, FALSE),
    (target_company_id, 'Revizyonda', 'revision', 4, FALSE),
    (target_company_id, 'Teslim Edildi', 'delivered', 5, TRUE)
  ON CONFLICT (company_id, code) DO NOTHING;

  INSERT INTO system_settings (company_id, setting_key, setting_value)
  VALUES
    (target_company_id, 'default_language', 'tr'),
    (target_company_id, 'timezone', 'Europe/Istanbul'),
    (target_company_id, 'week_starts_on', 'monday'),
    (target_company_id, 'date_format', 'dd.MM.yyyy')
  ON CONFLICT (company_id, setting_key) DO NOTHING;

  INSERT INTO help_articles (company_id, title, slug, category, body, summary, status)
  VALUES
    (
      target_company_id,
      'Gorev nasil olusturulur?',
      'gorev-nasil-olusturulur',
      'Gorevler',
      'Gorev olusturma akisinda proje, atanan kisi, oncelik ve teslim tarihi belirlenir.',
      'Gorev kaydi olusturma ozeti',
      'published'
    ),
    (
      target_company_id,
      'Revizyon sureci nasil isler?',
      'revizyon-sureci-nasil-isler',
      'Revizyon',
      'Revizyon talebi, neden, tarihce ve onay karari ile birlikte takip edilir.',
      'Revizyon akis ozeti',
      'published'
    )
  ON CONFLICT (company_id, slug) DO NOTHING;

  INSERT INTO role_permissions (role_id, permission_id)
  SELECT r.id, p.id
  FROM roles r
  JOIN permissions p ON (
    (r.code = 'manager') OR
    (r.code = 'team_lead' AND p.code <> 'settings.update') OR
    (r.code = 'employee' AND p.code IN (
      'dashboard.view',
      'tasks.view',
      'tasks.comment',
      'tasks.submit',
      'revisions.view',
      'performance.view',
      'help.view'
    ))
  )
  WHERE r.company_id = target_company_id
  ON CONFLICT (role_id, permission_id) DO NOTHING;
END;
$$;

COMMIT;
