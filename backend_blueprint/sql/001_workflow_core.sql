BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION wf_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION wf_random_digits(target_len integer)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  result text := '';
BEGIN
  WHILE length(result) < target_len LOOP
    result := result || floor(random() * 10)::int::text;
  END LOOP;
  RETURN left(result, target_len);
END;
$$;

CREATE OR REPLACE FUNCTION wf_random_chars(target_len integer, alphabet text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  result text := '';
  alphabet_len integer := length(alphabet);
  candidate_idx integer;
BEGIN
  IF target_len <= 0 OR alphabet_len <= 0 THEN
    RETURN '';
  END IF;

  WHILE length(result) < target_len LOOP
    candidate_idx := floor(random() * alphabet_len)::integer + 1;
    result := result || substr(alphabet, candidate_idx, 1);
  END LOOP;

  RETURN left(result, target_len);
END;
$$;

CREATE TABLE IF NOT EXISTS companies (
  id BIGSERIAL PRIMARY KEY,
  company_code CHAR(5),
  name VARCHAR(160) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  owner_user_id BIGINT,
  timezone VARCHAR(64) NOT NULL DEFAULT 'Europe/Istanbul',
  locale VARCHAR(12) NOT NULL DEFAULT 'tr',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS companies_company_code_unique
  ON companies(company_code);

CREATE OR REPLACE FUNCTION wf_assign_company_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(5);
BEGIN
  IF NEW.company_code IS NOT NULL AND btrim(NEW.company_code) <> '' THEN
    RETURN NEW;
  END IF;

  LOOP
    candidate := wf_random_digits(5)::CHAR(5);
    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM companies
      WHERE company_code = candidate
    );
  END LOOP;

  NEW.company_code := candidate;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_companies_assign_code ON companies;
CREATE TRIGGER trg_companies_assign_code
BEFORE INSERT ON companies
FOR EACH ROW
EXECUTE FUNCTION wf_assign_company_code();

DROP TRIGGER IF EXISTS trg_companies_touch_updated_at ON companies;
CREATE TRIGGER trg_companies_touch_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS departments (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

DROP TRIGGER IF EXISTS trg_departments_touch_updated_at ON departments;
CREATE TRIGGER trg_departments_touch_updated_at
BEFORE UPDATE ON departments
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS positions (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  level SMALLINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

DROP TRIGGER IF EXISTS trg_positions_touch_updated_at ON positions;
CREATE TRIGGER trg_positions_touch_updated_at
BEFORE UPDATE ON positions
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS roles (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

DROP TRIGGER IF EXISTS trg_roles_touch_updated_at ON roles;
CREATE TRIGGER trg_roles_touch_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS permissions (
  id BIGSERIAL PRIMARY KEY,
  module VARCHAR(60) NOT NULL,
  action VARCHAR(60) NOT NULL,
  code VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS teams (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  manager_user_id BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

DROP TRIGGER IF EXISTS trg_teams_touch_updated_at ON teams;
CREATE TRIGGER trg_teams_touch_updated_at
BEFORE UPDATE ON teams
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS company_id BIGINT,
  ADD COLUMN IF NOT EXISTS user_code CHAR(10),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(32),
  ADD COLUMN IF NOT EXISTS department_id BIGINT,
  ADD COLUMN IF NOT EXISTS position_id BIGINT,
  ADD COLUMN IF NOT EXISTS team_id BIGINT,
  ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS is_first_login BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS work_preference VARCHAR(120),
  ADD COLUMN IF NOT EXISTS wants_quick_tour BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS users_user_code_unique
  ON users(user_code)
  WHERE user_code IS NOT NULL;

CREATE OR REPLACE FUNCTION wf_assign_user_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(10);
BEGIN
  IF NEW.user_code IS NOT NULL AND btrim(NEW.user_code) <> '' THEN
    RETURN NEW;
  END IF;

  LOOP
    candidate := wf_random_digits(10)::CHAR(10);
    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM users
      WHERE user_code = candidate
    );
  END LOOP;

  NEW.user_code := candidate;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_assign_code ON users;
CREATE TRIGGER trg_users_assign_code
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION wf_assign_user_code();

DROP TRIGGER IF EXISTS trg_users_touch_updated_at ON users;
CREATE TRIGGER trg_users_touch_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_company_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_department_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_department_id_fkey
      FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_position_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_position_id_fkey
      FOREIGN KEY (position_id) REFERENCES positions(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_team_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_team_id_fkey
      FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'teams_manager_user_id_fkey'
  ) THEN
    ALTER TABLE teams
      ADD CONSTRAINT teams_manager_user_id_fkey
      FOREIGN KEY (manager_user_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'companies_owner_user_id_fkey'
  ) THEN
    ALTER TABLE companies
      ADD CONSTRAINT companies_owner_user_id_fkey
      FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL;
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS role_permissions (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS user_permission_overrides (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  is_allowed BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, permission_id)
);

DROP TRIGGER IF EXISTS trg_user_permission_overrides_touch_updated_at
  ON user_permission_overrides;
CREATE TRIGGER trg_user_permission_overrides_touch_updated_at
BEFORE UPDATE ON user_permission_overrides
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS user_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  theme_preference VARCHAR(30) NOT NULL DEFAULT 'light',
  language VARCHAR(12) NOT NULL DEFAULT 'tr',
  wants_quick_tour BOOLEAN NOT NULL DEFAULT FALSE,
  default_dashboard_view VARCHAR(40) NOT NULL DEFAULT 'panel',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

DROP TRIGGER IF EXISTS trg_user_settings_touch_updated_at ON user_settings;
CREATE TRIGGER trg_user_settings_touch_updated_at
BEFORE UPDATE ON user_settings
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS notification_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  slack_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  daily_summary_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  report_ready_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  revision_alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

DROP TRIGGER IF EXISTS trg_notification_preferences_touch_updated_at
  ON notification_preferences;
CREATE TRIGGER trg_notification_preferences_touch_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS company_settings (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  workday_start TIME NOT NULL DEFAULT '08:30',
  workday_end TIME NOT NULL DEFAULT '18:00',
  default_report_format VARCHAR(20) NOT NULL DEFAULT 'pdf',
  default_notification_channel VARCHAR(20) NOT NULL DEFAULT 'system',
  revision_warning_threshold SMALLINT NOT NULL DEFAULT 3,
  task_due_warning_hours SMALLINT NOT NULL DEFAULT 24,
  allow_email_reports BOOLEAN NOT NULL DEFAULT TRUE,
  allow_slack_reports BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id)
);

DROP TRIGGER IF EXISTS trg_company_settings_touch_updated_at ON company_settings;
CREATE TRIGGER trg_company_settings_touch_updated_at
BEFORE UPDATE ON company_settings
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS projects (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  team_id BIGINT REFERENCES teams(id) ON DELETE SET NULL,
  code VARCHAR(40) NOT NULL,
  name VARCHAR(160) NOT NULL,
  client_name VARCHAR(160),
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  start_date DATE,
  due_date DATE,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

DROP TRIGGER IF EXISTS trg_projects_touch_updated_at ON projects;
CREATE TRIGGER trg_projects_touch_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS project_members (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(40) NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (project_id, user_id)
);

CREATE TABLE IF NOT EXISTS task_statuses (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  sort_order SMALLINT NOT NULL DEFAULT 1,
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, code)
);

CREATE TABLE IF NOT EXISTS tasks (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  parent_task_id BIGINT REFERENCES tasks(id) ON DELETE SET NULL,
  task_no VARCHAR(40) NOT NULL,
  title VARCHAR(180) NOT NULL,
  description TEXT,
  status_id BIGINT REFERENCES task_statuses(id) ON DELETE SET NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  primary_assignee_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  due_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  estimated_minutes INTEGER,
  actual_minutes INTEGER,
  quality_score SMALLINT,
  revision_count INTEGER NOT NULL DEFAULT 0,
  is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  flag_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, task_no)
);

CREATE UNIQUE INDEX IF NOT EXISTS tasks_task_no_unique
  ON tasks(task_no);

CREATE OR REPLACE FUNCTION wf_assign_task_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  candidate VARCHAR(10);
BEGIN
  IF NEW.task_no IS NOT NULL AND btrim(NEW.task_no) <> '' THEN
    RETURN NEW;
  END IF;

  LOOP
    candidate :=
      wf_random_chars(1, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') ||
      wf_random_digits(5) ||
      wf_random_chars(2, 'abcdefghijklmnopqrstuvwxyz') ||
      wf_random_digits(2);

    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM tasks
      WHERE task_no = candidate
    );
  END LOOP;

  NEW.task_no := candidate;
  RETURN NEW;
END;
$$;

CREATE INDEX IF NOT EXISTS tasks_company_due_idx
  ON tasks(company_id, due_at);
CREATE INDEX IF NOT EXISTS tasks_status_idx
  ON tasks(status_id);
CREATE INDEX IF NOT EXISTS tasks_primary_assignee_idx
  ON tasks(primary_assignee_id);

DROP TRIGGER IF EXISTS trg_tasks_assign_code ON tasks;
CREATE TRIGGER trg_tasks_assign_code
BEFORE INSERT ON tasks
FOR EACH ROW
EXECUTE FUNCTION wf_assign_task_code();

DROP TRIGGER IF EXISTS trg_tasks_touch_updated_at ON tasks;
CREATE TRIGGER trg_tasks_touch_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS task_assignments (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assignment_type VARCHAR(30) NOT NULL DEFAULT 'primary',
  assigned_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (task_id, user_id, assignment_type)
);

CREATE TABLE IF NOT EXISTS task_checklists (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  sort_order SMALLINT NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS task_labels (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(80) NOT NULL,
  color VARCHAR(20) NOT NULL DEFAULT '#0F62FE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, name)
);

CREATE TABLE IF NOT EXISTS task_label_links (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  label_id BIGINT NOT NULL REFERENCES task_labels(id) ON DELETE CASCADE,
  UNIQUE (task_id, label_id)
);

CREATE TABLE IF NOT EXISTS task_comments (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  comment_type VARCHAR(30) NOT NULL DEFAULT 'comment',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS task_attachments (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  uploaded_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  file_name VARCHAR(220) NOT NULL,
  file_path VARCHAR(400) NOT NULL,
  mime_type VARCHAR(120),
  file_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS task_status_history (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  from_status_id BIGINT REFERENCES task_statuses(id) ON DELETE SET NULL,
  to_status_id BIGINT REFERENCES task_statuses(id) ON DELETE SET NULL,
  changed_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS task_time_logs (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  source VARCHAR(30) NOT NULL DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS revisions (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  requested_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  assigned_to BIGINT REFERENCES users(id) ON DELETE SET NULL,
  revision_no INTEGER NOT NULL DEFAULT 1,
  reason TEXT NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending_review',
  is_warning_triggered BOOLEAN NOT NULL DEFAULT FALSE,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS revisions_task_idx
  ON revisions(task_id, status);

DROP TRIGGER IF EXISTS trg_revisions_touch_updated_at ON revisions;
CREATE TRIGGER trg_revisions_touch_updated_at
BEFORE UPDATE ON revisions
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS revision_messages (
  id BIGSERIAL PRIMARY KEY,
  revision_id BIGINT NOT NULL REFERENCES revisions(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  message_type VARCHAR(30) NOT NULL DEFAULT 'comment',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS approvals (
  id BIGSERIAL PRIMARY KEY,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  revision_id BIGINT REFERENCES revisions(id) ON DELETE SET NULL,
  approver_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  decision VARCHAR(30) NOT NULL,
  decision_note TEXT,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS performance_snapshots (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  team_id BIGINT REFERENCES teams(id) ON DELETE SET NULL,
  period_type VARCHAR(30) NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  completed_count INTEGER NOT NULL DEFAULT 0,
  late_count INTEGER NOT NULL DEFAULT 0,
  avg_completion_minutes INTEGER,
  avg_revision_count NUMERIC(8,2),
  quality_score NUMERIC(8,2),
  overall_score NUMERIC(8,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS performance_snapshots_scope_idx
  ON performance_snapshots(company_id, period_type, period_start, period_end);

CREATE TABLE IF NOT EXISTS dashboard_widgets (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  widget_type VARCHAR(60) NOT NULL,
  config_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  sort_order SMALLINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_dashboard_widgets_touch_updated_at ON dashboard_widgets;
CREATE TRIGGER trg_dashboard_widgets_touch_updated_at
BEFORE UPDATE ON dashboard_widgets
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS report_templates (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(140) NOT NULL,
  report_type VARCHAR(40) NOT NULL,
  scope_type VARCHAR(40) NOT NULL,
  filters_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  default_format VARCHAR(20) NOT NULL DEFAULT 'pdf',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_report_templates_touch_updated_at ON report_templates;
CREATE TRIGGER trg_report_templates_touch_updated_at
BEFORE UPDATE ON report_templates
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS report_runs (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  template_id BIGINT REFERENCES report_templates(id) ON DELETE SET NULL,
  requested_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  report_type VARCHAR(40) NOT NULL,
  scope_label VARCHAR(160) NOT NULL,
  format VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'preparing',
  file_path VARCHAR(400),
  emailed_to VARCHAR(240),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS report_runs_company_status_idx
  ON report_runs(company_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS notifications (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(180) NOT NULL,
  body TEXT NOT NULL,
  notification_type VARCHAR(40) NOT NULL,
  related_task_id BIGINT REFERENCES tasks(id) ON DELETE SET NULL,
  related_revision_id BIGINT REFERENCES revisions(id) ON DELETE SET NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_read_idx
  ON notifications(user_id, is_read, created_at DESC);

CREATE TABLE IF NOT EXISTS alerts (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id BIGINT REFERENCES tasks(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  alert_type VARCHAR(40) NOT NULL,
  severity VARCHAR(20) NOT NULL,
  message TEXT NOT NULL,
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS alerts_company_open_idx
  ON alerts(company_id, is_resolved, severity, created_at DESC);

CREATE TABLE IF NOT EXISTS help_articles (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
  title VARCHAR(180) NOT NULL,
  slug VARCHAR(180) NOT NULL,
  category VARCHAR(80) NOT NULL DEFAULT 'Genel',
  body TEXT NOT NULL,
  summary TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'published',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, slug)
);

DROP TRIGGER IF EXISTS trg_help_articles_touch_updated_at ON help_articles;
CREATE TRIGGER trg_help_articles_touch_updated_at
BEFORE UPDATE ON help_articles
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS system_settings (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  setting_key VARCHAR(120) NOT NULL,
  setting_value TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, setting_key)
);

DROP TRIGGER IF EXISTS trg_system_settings_touch_updated_at ON system_settings;
CREATE TRIGGER trg_system_settings_touch_updated_at
BEFORE UPDATE ON system_settings
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT REFERENCES companies(id) ON DELETE SET NULL,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  action VARCHAR(80) NOT NULL,
  old_values_json JSONB,
  new_values_json JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS audit_logs_company_entity_idx
  ON audit_logs(company_id, entity_type, entity_id, created_at DESC);

CREATE TABLE IF NOT EXISTS login_attempts (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  ip_address INET,
  is_success BOOLEAN NOT NULL DEFAULT FALSE,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS login_attempts_email_idx
  ON login_attempts(email, attempted_at DESC);

CREATE TABLE IF NOT EXISTS task_dependencies (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  predecessor_task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  successor_task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  dependency_type VARCHAR(30) NOT NULL DEFAULT 'finish_to_start',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (predecessor_task_id, successor_task_id, dependency_type)
);

CREATE INDEX IF NOT EXISTS task_dependencies_company_idx
  ON task_dependencies(company_id, successor_task_id, predecessor_task_id);

CREATE TABLE IF NOT EXISTS activity_events (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  title VARCHAR(180) NOT NULL,
  detail TEXT,
  metadata_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS activity_events_company_idx
  ON activity_events(company_id, entity_type, entity_id, created_at DESC);

CREATE TABLE IF NOT EXISTS request_forms (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  team_id BIGINT REFERENCES teams(id) ON DELETE SET NULL,
  name VARCHAR(160) NOT NULL,
  slug VARCHAR(160) NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, slug)
);

DROP TRIGGER IF EXISTS trg_request_forms_touch_updated_at ON request_forms;
CREATE TRIGGER trg_request_forms_touch_updated_at
BEFORE UPDATE ON request_forms
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS request_form_fields (
  id BIGSERIAL PRIMARY KEY,
  request_form_id BIGINT NOT NULL REFERENCES request_forms(id) ON DELETE CASCADE,
  label VARCHAR(180) NOT NULL,
  field_key VARCHAR(120) NOT NULL,
  field_type VARCHAR(40) NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  options_json JSONB,
  UNIQUE (request_form_id, field_key)
);

CREATE TABLE IF NOT EXISTS request_submissions (
  id BIGSERIAL PRIMARY KEY,
  request_form_id BIGINT NOT NULL REFERENCES request_forms(id) ON DELETE CASCADE,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id BIGINT REFERENCES tasks(id) ON DELETE SET NULL,
  submitted_by_email VARCHAR(255),
  payload_json JSONB NOT NULL DEFAULT '{}'::JSONB,
  status VARCHAR(30) NOT NULL DEFAULT 'new',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS request_submissions_company_idx
  ON request_submissions(company_id, request_form_id, created_at DESC);

CREATE TABLE IF NOT EXISTS automation_rules (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(180) NOT NULL,
  trigger_type VARCHAR(80) NOT NULL,
  scope_type VARCHAR(80) NOT NULL DEFAULT 'company',
  scope_id BIGINT,
  conditions_json JSONB NOT NULL DEFAULT '{}'::JSONB,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_automation_rules_touch_updated_at ON automation_rules;
CREATE TRIGGER trg_automation_rules_touch_updated_at
BEFORE UPDATE ON automation_rules
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS automation_rule_actions (
  id BIGSERIAL PRIMARY KEY,
  automation_rule_id BIGINT NOT NULL REFERENCES automation_rules(id) ON DELETE CASCADE,
  action_type VARCHAR(80) NOT NULL,
  action_config_json JSONB NOT NULL DEFAULT '{}'::JSONB,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS automation_runs (
  id BIGSERIAL PRIMARY KEY,
  automation_rule_id BIGINT NOT NULL REFERENCES automation_rules(id) ON DELETE CASCADE,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  entity_type VARCHAR(80),
  entity_id VARCHAR(80),
  status VARCHAR(30) NOT NULL DEFAULT 'queued',
  result_message TEXT,
  executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS automation_runs_company_idx
  ON automation_runs(company_id, automation_rule_id, executed_at DESC);

CREATE TABLE IF NOT EXISTS integration_connections (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  provider VARCHAR(80) NOT NULL,
  connection_name VARCHAR(160) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'disconnected',
  config_json JSONB NOT NULL DEFAULT '{}'::JSONB,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_integration_connections_touch_updated_at
  ON integration_connections;
CREATE TRIGGER trg_integration_connections_touch_updated_at
BEFORE UPDATE ON integration_connections
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS user_capacity_profiles (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  daily_capacity_minutes INTEGER NOT NULL DEFAULT 480,
  weekly_capacity_minutes INTEGER NOT NULL DEFAULT 2400,
  effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, user_id, effective_from)
);

DROP TRIGGER IF EXISTS trg_user_capacity_profiles_touch_updated_at
  ON user_capacity_profiles;
CREATE TRIGGER trg_user_capacity_profiles_touch_updated_at
BEFORE UPDATE ON user_capacity_profiles
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

COMMIT;
