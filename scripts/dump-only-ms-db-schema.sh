#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONCEPTION_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${COMPOSE_ENV_FILE:-${CONCEPTION_ROOT}/deployment/local/.env}"
OUT_DIR="${CONCEPTION_ROOT}/dumps"
OUT_FILE="${OUT_DIR}/core-schema-$(date +%Y%m%d).sql"

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

if [[ -z "${POSTGRES_PASSWORD:-}" ]]; then
  echo "Missing required environment variable: POSTGRES_PASSWORD" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
export PGPASSWORD="${POSTGRES_PASSWORD}"

pg_dump \
  -h "${POSTGRES_HOST}" \
  -p "${POSTGRES_PORT}" \
  -d "${POSTGRES_DB}" \
  -U "${POSTGRES_USER}" \
  --schema-only \
  --schema=core \
  --no-owner \
  --no-privileges \
  -f "${OUT_FILE}"

echo "Wrote ${OUT_FILE}" >&2
