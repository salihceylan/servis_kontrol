#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-site_kapi_kontrol_postgres}"
DB_NAME="${DB_NAME:-workflow}"
DB_USER="${DB_USER:-postgres}"

echo "Applying workflow schema to container=${CONTAINER_NAME} db=${DB_NAME} user=${DB_USER}"

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/001_workflow_core.sql"
docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "${ROOT_DIR}/sql/002_workflow_seed.sql"

echo "Workflow schema and seed applied successfully."
