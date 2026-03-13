#!/usr/bin/env bash
set -euo pipefail

LARAVEL_APP_DIR="${LARAVEL_APP_DIR:-/var/www/workflow/api}"
MAIL_HOST="${MAIL_HOST:-${SMTP_HOST:-}}"
MAIL_PORT="${MAIL_PORT:-${SMTP_PORT:-}}"
MAIL_USERNAME="${MAIL_USERNAME:-${SMTP_USER:-}}"
MAIL_PASSWORD="${MAIL_PASSWORD:-${SMTP_PASSWORD:-}}"
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-${SMTP_FROM:-}}"
MAIL_FROM_NAME="${MAIL_FROM_NAME:-${SMTP_FROM_NAME:-Workflow}}"

if [[ -z "${MAIL_HOST}" || -z "${MAIL_PORT}" || -z "${MAIL_USERNAME}" || -z "${MAIL_PASSWORD}" || -z "${MAIL_FROM_ADDRESS}" ]]; then
  echo "Missing required mail variables."
  echo "Set MAIL_* or SMTP_* variables."
  exit 1
fi

ENV_FILE="${LARAVEL_APP_DIR}/.env"

write_env() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "${ENV_FILE}"; then
    sed -i "s#^${key}=.*#${key}=${value}#" "${ENV_FILE}"
  else
    printf '\n%s=%s\n' "${key}" "${value}" >> "${ENV_FILE}"
  fi
}

write_env "MAIL_MAILER" "smtp"
write_env "MAIL_HOST" "${MAIL_HOST}"
write_env "MAIL_PORT" "${MAIL_PORT}"
write_env "MAIL_USERNAME" "${MAIL_USERNAME}"
write_env "MAIL_PASSWORD" "${MAIL_PASSWORD}"
write_env "MAIL_ENCRYPTION" "tls"
write_env "MAIL_FROM_ADDRESS" "${MAIL_FROM_ADDRESS}"
write_env "MAIL_FROM_NAME" "\"${MAIL_FROM_NAME}\""

cd "${LARAVEL_APP_DIR}"
php artisan optimize:clear

echo "Laravel mail configuration updated."
