#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="${SCRIPT_DIR}/../deployment/local"
ENV_FILE="${COMPOSE_ENV_FILE:-${COMPOSE_DIR}/.env}"
PYTHON_ENV="${COMPOSE_PYTHON_ENV_FILE:-${COMPOSE_DIR}/.env.python}"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-pokecoach2-local}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  exit 1
fi

if [[ ! -f "${PYTHON_ENV}" ]]; then
  echo "Image Python pokecoach2 non configurée: créer ${PYTHON_ENV} (voir .env.python.example)." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${PYTHON_ENV}"
set +a

if [[ -z "${POKECOACH_PYTHON_IMAGE:-}" ]]; then
  echo "Image Python pokecoach2 non configurée (POKECOACH_PYTHON_IMAGE vide)." >&2
  exit 1
fi

exec docker compose \
  --project-name "${PROJECT_NAME}" \
  --project-directory "${COMPOSE_DIR}" \
  --env-file "${ENV_FILE}" \
  -f "${COMPOSE_DIR}/docker-compose.yml" \
  -f "${COMPOSE_DIR}/compose.python.yml" \
  "$@"
