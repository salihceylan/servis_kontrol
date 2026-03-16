BEGIN;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS login_name VARCHAR(80);

CREATE UNIQUE INDEX IF NOT EXISTS users_login_name_unique
  ON users((LOWER(login_name)))
  WHERE login_name IS NOT NULL;

DO $$
DECLARE
  row_record RECORD;
  base_name TEXT;
  candidate TEXT;
  suffix INTEGER;
BEGIN
  FOR row_record IN
    SELECT id, email, user_code
    FROM users
    WHERE login_name IS NULL OR btrim(login_name) = ''
    ORDER BY id
  LOOP
    base_name := regexp_replace(
      lower(split_part(coalesce(row_record.email, ''), '@', 1)),
      '[^a-z0-9._-]',
      '',
      'g'
    );

    IF base_name IS NULL OR base_name = '' THEN
      base_name := 'user' || right(coalesce(btrim(row_record.user_code), '0000'), 4);
    END IF;

    candidate := left(base_name, 80);
    suffix := 0;

    WHILE EXISTS (
      SELECT 1
      FROM users
      WHERE lower(login_name) = lower(candidate)
        AND id <> row_record.id
    ) LOOP
      suffix := suffix + 1;
      candidate := left(base_name, GREATEST(1, 79 - length(suffix::text))) || '_' || suffix::text;
    END LOOP;

    UPDATE users
    SET login_name = candidate
    WHERE id = row_record.id;
  END LOOP;
END
$$;

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS team_id BIGINT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tasks_team_id_fkey'
  ) THEN
    ALTER TABLE tasks
      ADD CONSTRAINT tasks_team_id_fkey
      FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS tasks_team_idx
  ON tasks(team_id);

UPDATE tasks AS t
SET team_id = COALESCE(
  (
    SELECT u.team_id
    FROM users AS u
    WHERE u.id = t.primary_assignee_id
  ),
  (
    SELECT p.team_id
    FROM projects AS p
    WHERE p.id = t.project_id
  )
)
WHERE t.team_id IS NULL;

COMMIT;
