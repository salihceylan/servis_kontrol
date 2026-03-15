#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

echo "Applying workflow identifier code patch to container=${CONTAINER_NAME} db=${DB_NAME} user=${DB_USER}"

docker exec -i "${CONTAINER_NAME}" psql -v ON_ERROR_STOP=1 -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/003_workflow_identifier_codes.sql"

echo "Verifying identifier code formats"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT 'companies' AS scope, COUNT(*) AS invalid_count
FROM companies
WHERE btrim(company_code) !~ '^[0-9]{5}$'
UNION ALL
SELECT 'users' AS scope, COUNT(*) AS invalid_count
FROM users
WHERE btrim(user_code) !~ '^[0-9]{10}$'
UNION ALL
SELECT 'tasks' AS scope, COUNT(*) AS invalid_count
FROM tasks
WHERE task_no !~ '^[A-Z][0-9]{5}[a-z]{2}[0-9]{2}$';
"

echo "Workflow identifier code patch applied successfully."
