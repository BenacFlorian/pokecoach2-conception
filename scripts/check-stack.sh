#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${COMPOSE_ENV_FILE:-${SCRIPT_DIR}/../deployment/local/.env}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

GQL_PORT="${POSTGRAPHILE_PORT:-4042}"
ANG_PORT="${ANGULAR_PORT:-8082}"

"${SCRIPT_DIR}/compose.sh" up -d --build

"${SCRIPT_DIR}/compose.sh" ps

if ! curl -sf "http://127.0.0.1:${GQL_PORT}/graphql" \
  -H 'Content-Type: application/json' \
  --data '{"query":"{ teams(first:1){ nodes { id } } }"}' \
  | grep -q '"data"'; then
  echo "PostGraphile health query failed" >&2
  exit 1
fi

echo "Stack checks passed (PostGraphile GraphQL)." >&2
