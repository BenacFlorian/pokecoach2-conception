-- Purge progressive analysis data while keeping teams and matchups.
-- Run before switching to a new simulation result contract (openings, global refinement D, etc.).
-- Execute in a single transaction (psql -1 -v ON_ERROR_STOP=1 -f ...).
-- Uses session_replication_role=replica to bypass immutable battle/run triggers (maintenance only).

BEGIN;

SET LOCAL session_replication_role = replica;

DELETE FROM core.matchup_run_battles;
DELETE FROM core.analysis_commands;
DELETE FROM core.matchup_runs;

SET LOCAL session_replication_role = DEFAULT;

COMMIT;
