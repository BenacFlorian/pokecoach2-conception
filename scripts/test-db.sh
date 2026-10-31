#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${COMPOSE_ENV_FILE:-${ROOT}/deployment/local/.env}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

: "${POSTGRES_HOST:=127.0.0.1}"
: "${POSTGRES_PORT:=5442}"
: "${POSTGRES_USER:=pokecoach_admin}"
POSTGRES_DB="${POSTGRES_TEST_DB:-pokecoach2_test}"
: "${POSTGRES_PASSWORD:?Missing POSTGRES_PASSWORD}"

export PGPASSWORD="${POSTGRES_PASSWORD}"
PSQL=(psql -v ON_ERROR_STOP=1 -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}")

createdb_args=(-h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}")
if ! psql "${createdb_args[@]}" -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'" | grep -q 1; then
  createdb "${createdb_args[@]}" "${POSTGRES_DB}"
fi

export FLYWAY_URL="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
export FLYWAY_USER="${POSTGRES_USER}"
export FLYWAY_PASSWORD="${POSTGRES_PASSWORD}"

"${ROOT}/scripts/run-flyway.sh" migrate

for sql_file in "${ROOT}"/tests/sql/*.sql; do
  echo "Running ${sql_file}" >&2
  "${PSQL[@]}" -d "${POSTGRES_DB}" -f "${sql_file}"
done

echo "Database tests passed on ${POSTGRES_DB}." >&2
