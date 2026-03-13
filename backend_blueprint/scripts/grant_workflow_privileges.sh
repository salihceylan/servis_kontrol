#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"
APP_DB_USER="${APP_DB_USER:-workflow_app}"

echo "Granting workflow privileges to app_user=${APP_DB_USER} on db=${DB_NAME}"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" <<SQL
DO \$\$
BEGIN
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', '${APP_DB_USER}');
  EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', '${APP_DB_USER}');
  EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO %I', '${APP_DB_USER}');
  EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO %I', '${APP_DB_USER}');
  EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', '${APP_DB_USER}');
  EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I', '${APP_DB_USER}');
  EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO %I', '${APP_DB_USER}');
END
\$\$;
SQL

echo "Workflow DB grants applied successfully."
