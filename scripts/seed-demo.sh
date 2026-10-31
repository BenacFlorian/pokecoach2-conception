#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${COMPOSE_ENV_FILE:-${ROOT}/deployment/local/.env}"
FIXTURE="${ROOT}/tests/fixtures/demo.sql"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

: "${POSTGRES_HOST:=127.0.0.1}"
: "${POSTGRES_PORT:=5442}"
: "${POSTGRES_USER:=pokecoach_admin}"
: "${POSTGRES_DB:=pokecoach2}"
: "${POSTGRES_PASSWORD:?Missing POSTGRES_PASSWORD}"

export PGPASSWORD="${POSTGRES_PASSWORD}"
exec psql -v ON_ERROR_STOP=1 -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f "${FIXTURE}"
