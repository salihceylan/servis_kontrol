#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

echo "Applying workflow manager workspace patch to container=${CONTAINER_NAME} db=${DB_NAME} user=${DB_USER}"

docker exec -i "${CONTAINER_NAME}" psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/004_workflow_manager_workspace.sql"

echo "Verifying manager workspace columns"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT 'users.login_name' AS scope, COUNT(*) AS invalid_count
FROM users
WHERE login_name IS NULL OR btrim(login_name) = ''
UNION ALL
SELECT 'tasks.team_id_null' AS scope, COUNT(*) AS invalid_count
FROM tasks
WHERE project_id IS NOT NULL
  AND primary_assignee_id IS NOT NULL
  AND team_id IS NULL;
"

echo "Workflow manager workspace patch applied successfully."
