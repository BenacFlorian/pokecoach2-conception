#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_HOST:?Missing POSTGRES_HOST}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_DB:?Missing POSTGRES_DB}"
: "${POSTGRES_USER:?Missing POSTGRES_USER}"
: "${POSTGRES_PASSWORD:?Missing POSTGRES_PASSWORD}"

export FLYWAY_URL="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
export FLYWAY_USER="${POSTGRES_USER}"
export FLYWAY_PASSWORD="${POSTGRES_PASSWORD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLYWAY_MODULES_ROOT="${SCRIPT_DIR}/modules"

"${SCRIPT_DIR}/scripts/run-flyway.sh" migrate
"${SCRIPT_DIR}/scripts/run-flyway.sh" info
