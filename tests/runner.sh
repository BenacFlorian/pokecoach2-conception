#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FLYWAY_MODULES_ROOT="${ROOT}/tests/fixtures/modules-runner"
TMP_BIN="$(mktemp -d)"
export PATH="${TMP_BIN}:${PATH}"
export FLYWAY_URL="jdbc:postgresql://127.0.0.1:5442/pokecoach2"
export FLYWAY_USER="pokecoach_admin"
export FLYWAY_PASSWORD="test"
export FAKE_FLYWAY_LOG="$(mktemp)"

mkdir -p "${FLYWAY_MODULES_ROOT}/1.0-core/sql"
echo '-- root migration' > "${FLYWAY_MODULES_ROOT}/1.0-core/sql/V1.0.1__init.sql"

write_fake_flyway() {
  cat > "${TMP_BIN}/flyway" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
log="${FAKE_FLYWAY_LOG:-/tmp/fake-flyway.log}"
printf '%s\n' "$*" >> "$log"
for arg in "$@"; do
  case "$arg" in
    -schemas=*) SCHEMA="${arg#-schemas=}" ;;
    migrate|validate|info) CMD="$arg" ;;
  esac
done
if [[ "${FAKE_FLYWAY_FAIL:-}" == "1" && "${CMD:-}" == "migrate" ]]; then
  exit 9
fi
exit 0
FAKE
  chmod +x "${TMP_BIN}/flyway"
}

failures=0
assert() {
  if "$@"; then
    echo "OK: $*" >&2
  else
    echo "FAIL: $*" >&2
    failures=$((failures + 1))
  fi
}

write_fake_flyway
: > "${FAKE_FLYWAY_LOG}"

"${ROOT}/scripts/run-flyway.sh" migrate
assert grep -q -- '-schemas=core' "${FAKE_FLYWAY_LOG}"

mkdir -p "${FLYWAY_MODULES_ROOT}/1.0-core/sql/nested/deep"
echo '-- nested' > "${FLYWAY_MODULES_ROOT}/1.0-core/sql/nested/deep/V9.9.9__nested.sql"
: > "${FAKE_FLYWAY_LOG}"
"${ROOT}/scripts/run-flyway.sh" migrate 2> /tmp/runner-nested.log || true
assert grep -qi 'nested versioned migrations' /tmp/runner-nested.log

export FAKE_FLYWAY_FAIL=1
set +e
"${ROOT}/scripts/run-flyway.sh" migrate
status=$?
set -e
assert test "${status}" -eq 9

rm -rf "${TMP_BIN}" "${FAKE_FLYWAY_LOG}" "${FLYWAY_MODULES_ROOT}" /tmp/runner-nested.log

if [[ "${failures}" -gt 0 ]]; then
  echo "${failures} runner test(s) failed" >&2
  exit 1
fi
echo "All runner tests passed." >&2
