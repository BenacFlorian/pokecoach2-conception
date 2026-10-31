#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONCEPTION_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_DIR="${CONCEPTION_ROOT}/deployment/local"
ENV_FILE="${COMPOSE_ENV_FILE:-${COMPOSE_DIR}/.env}"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-pokecoach2-local}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing environment file: ${ENV_FILE}" >&2
  echo "Copy ${COMPOSE_DIR}/.env.example to ${ENV_FILE} and set passwords locally." >&2
  exit 1
fi

exec docker compose \
  --project-name "${PROJECT_NAME}" \
  --project-directory "${COMPOSE_DIR}" \
  --env-file "${ENV_FILE}" \
  "$@"
