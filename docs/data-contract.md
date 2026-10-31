# Data contract — pokecoach2 core schema

Mapping between Angular models and PostgreSQL for future API wiring.

## Team

| Frontend (`Team`) | SQL (`core.teams`) |
| --- | --- |
| `id` | `id` (UUID string in JSON snapshots) |
| `name` | `name` |
| `source.kind` | `source_kind` |
| `source.rawText` | `source_text` |
| `source.url` | `source_url` |
| `pokemon` | `pokemon` (JSONB array, same property names) |
| `createdAt` | `created_at` (ISO-8601 in snapshots) |
| — | `kind` (`owned` / `opponent`) |

Historical matchup display uses **run snapshots** for both sides, not live team rows.

## PreparedMatchup

| Frontend | SQL |
| --- | --- |
| `id` | latest `core.matchup_runs.id` or matchup id depending on screen |
| `teamId` | `core.matchups.our_team_id` |
| `opponent` | `opponent_team_snapshot` on the successful run |
| `report` | `core.matchup_runs.report` |
| `createdAt` | run `created_at` |
| *(à venir côté UI)* | `process_status` — étapes pipeline : `INITIAL`, `PENDING STATS`, `PENDING GAME SIMULATIONS`, `SUCCESS`, `ERROR` |

PostGraphile expose l’enum GraphQL `MatchupRunProcessStatus` avec des identifiants sans espaces (`PENDING_STATS`, `PENDING_GAME_SIMULATIONS`, etc.) ; en SQL et en JSON PostgreSQL natif, les libellés avec espaces restent tels quels.

Le worker peut faire évoluer `process_status` pendant `status` ∈ `queued` / `running`. Passage à `status = succeeded` force `SUCCESS` ; `failed` / `cancelled` force `ERROR`.

Pour ajouter une étape plus tard : `ALTER TYPE core.matchup_run_process_status ADD VALUE '…';` puis redémarrer PostGraphile.

Use `core.matchups_latest_successful_run(matchup_row)` for the latest succeeded preparation.

## Demo identifier mapping

| Angular demo id | SQL UUID |
| --- | --- |
| `demo-team-matchup` | `a1111111-1111-4111-8111-111111111101` |
| `demo-team-empty` | `a1111111-1111-4111-8111-111111111102` |
| `demo-opponent-nirinbo` | `b2222222-2222-4222-8222-222222222201` |
| `demo-matchup-1` | `c3333333-3333-4333-8333-333333333301` |

Réinstallation atomique (API Python, `ENABLE_DEMO_SEED=true`) : `core.reset_demo_dataset()` — réservée aux UUID ci-dessus, exécutable par `pokecoach_worker` uniquement (`SECURITY DEFINER`, masquée PostGraphile `@omit`). Source JSON : `tests/fixtures/demo.manifest.json`.

## MatchupReport mock v1

Stored in `report` when `source = 'mock'` and `report_version = 1`. Root keys match `MatchupReport` in Angular (`fixtureVersion`, phase sample sizes, `opponentLeads`, `selectionComparisons`, `leadRecommendation`, `gameplan`).

Validation helper: `core.is_valid_mock_report_v1(jsonb)` (structure only, not full VGC strategy).

## Simulation run v2 (progressive)

| SQL (`core.matchup_runs`) | Role |
| --- | --- |
| `status` | `queued`, `running`, `paused`, terminal outcomes |
| `target_phase` | Pause/continue target (`A`…`synthesis`); null for mock |
| `partial_result` | Envelope v2 while in progress; see Python `contracts/examples/` |
| `result_revision` | +1 per published phase checkpoint |
| `progress` | `{ phase, completed, total }` for UI counters |
| `execution_metadata` | Per-phase measurements (parameters/provenance stay frozen) |
| `report` | Final copy at `succeeded` only (equals last `partial_result` for v2) |
| `lease_token`, `lease_expires_at`, `heartbeat_at` | Worker lease (omitted from GraphQL) |

Worker-only tables (GraphQL `@omit`, no `authenticated_user` access): `core.analysis_commands`, `core.matchup_run_battles`.

Validation: `core.is_valid_simulation_result_v2(jsonb, require_complete boolean)`. JSON `null` on optional sections means « not calculated yet ».

At most one active run per matchup (`status IN ('queued','running')` partial unique index).

Mock v1 successful reports remain `source='mock'`, `report_version=1`. Real simulations use `source='simulation'`, `report_version=2`.
