# SQL architecture

## Module `1.0-core` → schema `core`

| Area | Objects |
| --- | --- |
| Bootstrap | `V1.0.1__init_schema.sql`, `stack_sentinel`, `afterMigrate.sql` |
| Teams | `core.teams`, `core.is_valid_pokemon_sets` |
| Matchups | `core.matchups`, `core.matchup_runs`, enum `matchup_run_process_status` |
| Integrity | `V1.0.5` triggers (audit, snapshots, status, immutability) |
| Read helpers | `R__matchup_read_functions.sql` (`matchups_latest_successful_run`, mock report check) |

## Roles

| Role | Purpose |
| --- | --- |
| `pokecoach_admin` | Migrations (Compose superuser) |
| `authenticated_user` | PostGraphile default SQL privileges |
| `pokecoach_api` | LOGIN, member of `authenticated_user` |
| `pokecoach_worker` | Run lifecycle writes (future Python worker) |

## Flyway layout

Version files live under `modules/1.0-core/sql/` (root and subfolders). Runner: `scripts/run-flyway.sh` (deterministic module order, per-schema history).
