#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

echo "Applying workflow operation messages patch to container=${CONTAINER_NAME} db=${DB_NAME} user=${DB_USER}"

docker exec -i "${CONTAINER_NAME}" psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/006_workflow_operation_messages.sql"

echo "Verifying operation message tables"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'operation_threads',
    'operation_thread_participants',
    'operation_thread_messages',
    'operation_thread_reads'
  )
ORDER BY table_name;
"

echo "Workflow operation messages patch applied successfully."
