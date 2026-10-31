#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") migrate|validate|info" >&2
  exit 2
}

CMD="${1:-}"
case "${CMD}" in
  migrate | validate | info) ;;
  *) usage ;;
esac

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

require_var FLYWAY_URL
require_var FLYWAY_USER
require_var FLYWAY_PASSWORD

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONCEPTION_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_ROOT="${FLYWAY_MODULES_ROOT:-${CONCEPTION_ROOT}/modules}"
FLYWAY_BIN="${FLYWAY_BIN:-flyway}"

if [[ ! -d "${MODULES_ROOT}" ]]; then
  echo "Modules root not found: ${MODULES_ROOT}" >&2
  exit 1
fi

mapfile -t MODULE_DIRS < <(find "${MODULES_ROOT}" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
if [[ "${#MODULE_DIRS[@]}" -eq 0 ]]; then
  echo "No modules under ${MODULES_ROOT}" >&2
  exit 1
fi

flyway_common=(
  "-user=${FLYWAY_USER}"
  "-password=${FLYWAY_PASSWORD}"
  "-url=${FLYWAY_URL}"
  "-cleanDisabled=true"
  "-baselineOnMigrate=false"
  "-validateMigrationNaming=true"
  "-color=always"
)

overall_status=0

for module_dir in "${MODULE_DIRS[@]}"; do
  module_name="$(basename "${module_dir}")"
  schema="${module_name##*-}"
  sql_root="${module_dir}/sql"

  if [[ ! -d "${sql_root}" ]]; then
    continue
  fi

  if ! find "${sql_root}" -type f -name 'V*.sql' -print -quit | grep -q .; then
    echo "Skipping module ${module_name}: no versioned migrations under sql/" >&2
    continue
  fi

  if find "${sql_root}" -mindepth 3 -type f -name 'V*.sql' -print -quit | grep -q .; then
    echo "Module ${module_name}: deeply nested versioned migrations detected under ${sql_root}" >&2
  fi

  echo "==> Flyway ${CMD} schema=${schema} module=${module_name}" >&2

  (
    cd "${module_dir}" || exit 1
    "${FLYWAY_BIN}" "${flyway_common[@]}" \
      "-locations=filesystem:./sql" \
      "-schemas=${schema}" \
      "${CMD}"
  ) || overall_status=$?
done

exit "${overall_status}"
