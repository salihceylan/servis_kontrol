#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'companies',
    'company_settings',
    'roles',
    'permissions',
    'teams',
    'projects',
    'tasks',
    'revisions',
    'performance_snapshots',
    'report_runs',
    'help_articles',
    'notifications',
    'alerts',
    'audit_logs'
  )
ORDER BY table_name;
"
