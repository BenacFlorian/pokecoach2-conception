#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONCEPTION_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${COMPOSE_ENV_FILE:-${CONCEPTION_ROOT}/deployment/local/.env}"

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

export FLYWAY_URL="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
export FLYWAY_USER="${POSTGRES_USER}"
export FLYWAY_PASSWORD="${POSTGRES_PASSWORD}"

exec "${SCRIPT_DIR}/run-flyway.sh" "${1:-migrate}"
