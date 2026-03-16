#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

echo "Applying workflow task operations patch to container=${CONTAINER_NAME} db=${DB_NAME} user=${DB_USER}"

docker exec -i "${CONTAINER_NAME}" psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/005_workflow_task_operations.sql"

echo "Verifying task operation columns"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'tasks'
  AND column_name IN (
    'planned_start_at',
    'service_location',
    'contact_name',
    'contact_phone',
    'access_notes',
    'expected_outcome',
    'manager_brief',
    'lead_brief',
    'field_notes',
    'completion_summary',
    'blocker_notes'
  )
ORDER BY column_name;
"

echo "Workflow task operations patch applied successfully."
