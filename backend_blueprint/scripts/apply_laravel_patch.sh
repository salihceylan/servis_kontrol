#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_DIR="${ROOT_DIR}/laravel_patch"
LARAVEL_APP_DIR="${LARAVEL_APP_DIR:-/var/www/workflow/api}"

echo "Applying workflow Laravel patch to ${LARAVEL_APP_DIR}"

mkdir -p "${LARAVEL_APP_DIR}/app/Console/Commands"
mkdir -p "${LARAVEL_APP_DIR}/app/Http/Controllers/Api/Workflow"
mkdir -p "${LARAVEL_APP_DIR}/app/Services/Workflow"
mkdir -p "${LARAVEL_APP_DIR}/config"

cp "${PATCH_DIR}/app/Console/Commands/WorkflowBootstrapCompany.php" \
  "${LARAVEL_APP_DIR}/app/Console/Commands/"
cp "${PATCH_DIR}/app/Http/Controllers/Api/Workflow/"*.php \
  "${LARAVEL_APP_DIR}/app/Http/Controllers/Api/Workflow/"
cp "${PATCH_DIR}/app/Services/Workflow/"*.php \
  "${LARAVEL_APP_DIR}/app/Services/Workflow/"
cp "${PATCH_DIR}/routes/api.workflow.php" \
  "${LARAVEL_APP_DIR}/routes/api.workflow.php"
cp "${PATCH_DIR}/config/cors.php" \
  "${LARAVEL_APP_DIR}/config/cors.php"

API_ROUTE_FILE="${LARAVEL_APP_DIR}/routes/api.php"
ROUTE_INCLUDE="require __DIR__.'/api.workflow.php';"
if ! grep -Fq "${ROUTE_INCLUDE}" "${API_ROUTE_FILE}"; then
  printf "\n%s\n" "${ROUTE_INCLUDE}" >> "${API_ROUTE_FILE}"
fi

cd "${LARAVEL_APP_DIR}"
php artisan optimize:clear
php artisan route:list | grep 'auth/login\|help-center' || true

echo "Workflow Laravel patch applied successfully."
