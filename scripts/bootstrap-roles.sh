#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../deployment/local/.env.example
ENV_FILE="${COMPOSE_ENV_FILE:-${SCRIPT_DIR}/../deployment/local/.env}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

: "${POSTGRES_HOST:=127.0.0.1}"
: "${POSTGRES_PORT:=5442}"
: "${POSTGRES_DB:=pokecoach2}"
: "${POSTGRES_USER:=pokecoach_admin}"

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

require_var POSTGRES_PASSWORD
require_var API_DB_PASSWORD
require_var WORKER_DB_PASSWORD

export PGPASSWORD="${POSTGRES_PASSWORD}"
PSQL=(psql -v ON_ERROR_STOP=1 -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}")

psql_apply() {
  "${PSQL[@]}" "$@"
}

psql_apply \
  -v api_password="${API_DB_PASSWORD}" \
  -v worker_password="${WORKER_DB_PASSWORD}" <<'SQL'
SELECT format('Bootstrap roles on database %I', current_database());

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated_user') THEN
    CREATE ROLE authenticated_user NOLOGIN;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pokecoach_api') THEN
    CREATE ROLE pokecoach_api LOGIN NOINHERIT;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pokecoach_worker') THEN
    CREATE ROLE pokecoach_worker LOGIN;
  END IF;
END
$$;

GRANT authenticated_user TO pokecoach_api;

ALTER ROLE pokecoach_api PASSWORD :'api_password';
ALTER ROLE pokecoach_worker PASSWORD :'worker_password';

ALTER ROLE pokecoach_api
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

ALTER ROLE pokecoach_worker
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

ALTER ROLE authenticated_user
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
SQL

echo "Role bootstrap completed." >&2
