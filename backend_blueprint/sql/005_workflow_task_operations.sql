BEGIN;

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS planned_start_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS service_location VARCHAR(255),
  ADD COLUMN IF NOT EXISTS contact_name VARCHAR(160),
  ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(32),
  ADD COLUMN IF NOT EXISTS access_notes TEXT,
  ADD COLUMN IF NOT EXISTS expected_outcome TEXT,
  ADD COLUMN IF NOT EXISTS manager_brief TEXT,
  ADD COLUMN IF NOT EXISTS lead_brief TEXT,
  ADD COLUMN IF NOT EXISTS field_notes TEXT,
  ADD COLUMN IF NOT EXISTS completion_summary TEXT,
  ADD COLUMN IF NOT EXISTS blocker_notes TEXT;

CREATE INDEX IF NOT EXISTS tasks_planned_start_idx
  ON tasks(company_id, planned_start_at);

COMMIT;
