BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

CREATE OR REPLACE FUNCTION wf_generate_company_code(excluded_company_id bigint DEFAULT NULL)
RETURNS CHAR(5)
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(5);
BEGIN
  LOOP
    candidate := wf_random_digits(5)::CHAR(5);
    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM companies
      WHERE company_code = candidate
        AND (excluded_company_id IS NULL OR id <> excluded_company_id)
    );
  END LOOP;

  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION wf_generate_user_code(excluded_user_id bigint DEFAULT NULL)
RETURNS CHAR(10)
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(10);
BEGIN
  LOOP
    candidate := wf_random_digits(10)::CHAR(10);
    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM users
      WHERE user_code = candidate
        AND (excluded_user_id IS NULL OR id <> excluded_user_id)
    );
  END LOOP;

  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION wf_generate_task_code(excluded_task_id bigint DEFAULT NULL)
RETURNS VARCHAR(10)
LANGUAGE plpgsql
AS $$
DECLARE
  candidate VARCHAR(10);
BEGIN
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
        AND (excluded_task_id IS NULL OR id <> excluded_task_id)
    );
  END LOOP;

  RETURN candidate;
END;
$$;

DO $$
DECLARE
  company_record RECORD;
  user_record RECORD;
  task_record RECORD;
BEGIN
  FOR company_record IN SELECT id FROM companies ORDER BY id LOOP
    UPDATE companies
    SET company_code = wf_generate_company_code(company_record.id),
        updated_at = NOW()
    WHERE id = company_record.id;
  END LOOP;

  FOR user_record IN SELECT id FROM users ORDER BY id LOOP
    UPDATE users
    SET user_code = wf_generate_user_code(user_record.id),
        updated_at = NOW()
    WHERE id = user_record.id;
  END LOOP;

  FOR task_record IN SELECT id FROM tasks ORDER BY id LOOP
    UPDATE tasks
    SET task_no = wf_generate_task_code(task_record.id),
        updated_at = NOW()
    WHERE id = task_record.id;
  END LOOP;
END;
$$;

ALTER TABLE companies
  ALTER COLUMN company_code TYPE CHAR(5)
  USING NULLIF(left(btrim(company_code), 5), '')::CHAR(5);

ALTER TABLE users
  ALTER COLUMN user_code TYPE CHAR(10)
  USING NULLIF(left(btrim(user_code), 10), '')::CHAR(10);

CREATE UNIQUE INDEX IF NOT EXISTS tasks_task_no_unique
  ON tasks(task_no);

CREATE OR REPLACE FUNCTION wf_assign_company_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.company_code IS NULL OR btrim(NEW.company_code) = '' THEN
    NEW.company_code := wf_generate_company_code();
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION wf_assign_user_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.user_code IS NULL OR btrim(NEW.user_code) = '' THEN
    NEW.user_code := wf_generate_user_code();
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION wf_assign_task_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.task_no IS NULL OR btrim(NEW.task_no) = '' THEN
    NEW.task_no := wf_generate_task_code();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_companies_assign_code ON companies;
CREATE TRIGGER trg_companies_assign_code
BEFORE INSERT ON companies
FOR EACH ROW
EXECUTE FUNCTION wf_assign_company_code();

DROP TRIGGER IF EXISTS trg_users_assign_code ON users;
CREATE TRIGGER trg_users_assign_code
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION wf_assign_user_code();

DROP TRIGGER IF EXISTS trg_tasks_assign_code ON tasks;
CREATE TRIGGER trg_tasks_assign_code
BEFORE INSERT ON tasks
FOR EACH ROW
EXECUTE FUNCTION wf_assign_task_code();

COMMIT;
