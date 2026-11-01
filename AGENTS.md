# AGENTS.md — pokecoach2-conception

Instructions for AI agents working on **SQL migrations and local database tooling** for pokecoach2. This is not an application repository: no Angular, Python API, or frontend here.

## Permanent rules

- Git commits on this repo: use **`benacFlorian <florianbenac46@gmail.com>`** only. Never `florian.benac@webinage.fr` (see workspace rule `.cursor/rules/git-commit-author.mdc`).
- SQL comments and repoindex profiles in **English**. Plans and user-facing README in **French** where documented.
- Document only what the `.sql` files contain.
- Applied migrations are **immutable**. Never hand-edit `flyway_schema_history`.
- Never run Flyway `clean`, automatic `repair`, or automatic `baseline` in normal workflows.
- Module root: `modules/`. PostgreSQL schema = part after the last `-` in the module folder (`1.0-core` → `core`).
- Versioned migrations: `V{x.y.z}__description.sql`. Repeatables: `R__description.sql` (idempotent; replayed when checksum changes).
- `afterMigrate.sql` runs once after a successful **`migrate`** command for the module, not after each version file.
- Subfolders under `sql/` (e.g. `core/`, `trigger_functions/`) group migrations; Flyway discovers them under `filesystem:./sql`.

## Local environment

- Compose project: `pokecoach2-local`, files under `deployment/local/`.
- Host PostgreSQL: `127.0.0.1:${POSTGRES_PORT}` (default **5442**). Inside Compose: `postgres:5432`.
- Database: `pokecoach2`, migration user: `pokecoach_admin`, GraphQL SQL role: `pokecoach_api` → `authenticated_user`.

## Commands

| Command | Usage |
| --- | --- |
| `./scripts/compose.sh up -d` | Start PostgreSQL, bootstrap, Flyway (and PostGraphile when configured) |
| `devbox run migrate` | Flyway migrate against host DB (requires `.env`) |
| `devbox run validate` | Flyway validate |
| `devbox run info` | Flyway info |
| `devbox run dump-schema` | Structural dump of `core` |
| `./scripts/test-db.sh` | SQL tests on disposable DB |
| `./tests/runner.sh` | Shell tests for Flyway runner |

## Documentation index

| Document | Path |
| --- | --- |
| Overview | `repoindex/overview.md` |
| Architecture | `repoindex/architecture.md` |
| Module profile | `modules/1.0-core/1.0-core_repoindex.md` |
| Migration profile | next to each `V*__*.sql` as `*_repoindex.md` |
