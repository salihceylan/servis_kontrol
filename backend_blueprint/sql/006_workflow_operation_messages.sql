BEGIN;

CREATE TABLE IF NOT EXISTS operation_threads (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  task_id BIGINT REFERENCES tasks(id) ON DELETE SET NULL,
  thread_type VARCHAR(30) NOT NULL DEFAULT 'direct',
  conversation_key VARCHAR(160) NOT NULL,
  title VARCHAR(180) NOT NULL,
  created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, conversation_key)
);

CREATE INDEX IF NOT EXISTS operation_threads_company_last_message_idx
  ON operation_threads(company_id, last_message_at DESC, updated_at DESC);

DROP TRIGGER IF EXISTS trg_operation_threads_touch_updated_at ON operation_threads;
CREATE TRIGGER trg_operation_threads_touch_updated_at
BEFORE UPDATE ON operation_threads
FOR EACH ROW
EXECUTE FUNCTION wf_touch_updated_at();

CREATE TABLE IF NOT EXISTS operation_thread_participants (
  thread_id BIGINT NOT NULL REFERENCES operation_threads(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (thread_id, user_id)
);

CREATE INDEX IF NOT EXISTS operation_thread_participants_user_idx
  ON operation_thread_participants(user_id, thread_id);

CREATE TABLE IF NOT EXISTS operation_thread_messages (
  id BIGSERIAL PRIMARY KEY,
  thread_id BIGINT NOT NULL REFERENCES operation_threads(id) ON DELETE CASCADE,
  sender_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS operation_thread_messages_thread_idx
  ON operation_thread_messages(thread_id, created_at DESC);

CREATE TABLE IF NOT EXISTS operation_thread_reads (
  thread_id BIGINT NOT NULL REFERENCES operation_threads(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_read_message_id BIGINT REFERENCES operation_thread_messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ,
  PRIMARY KEY (thread_id, user_id)
);

CREATE INDEX IF NOT EXISTS operation_thread_reads_user_idx
  ON operation_thread_reads(user_id, thread_id);

COMMIT;
