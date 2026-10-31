-- Progressive simulation storage (plan 03 task 1).

ALTER TABLE core.matchup_runs
  DROP CONSTRAINT IF EXISTS matchup_runs_status_chk;

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_status_chk
  CHECK (status IN ('queued', 'running', 'paused', 'succeeded', 'failed', 'cancelled'));

ALTER TABLE core.matchup_runs
  ADD COLUMN IF NOT EXISTS target_phase text,
  ADD COLUMN IF NOT EXISTS partial_result jsonb,
  ADD COLUMN IF NOT EXISTS result_revision integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS progress jsonb,
  ADD COLUMN IF NOT EXISTS execution_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS lease_token uuid,
  ADD COLUMN IF NOT EXISTS lease_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS heartbeat_at timestamptz;

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_result_revision_chk CHECK (result_revision >= 0);

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_target_phase_chk CHECK (
    target_phase IS NULL
    OR target_phase IN ('A', 'B', 'C', 'D', 'synthesis')
  );

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_progress_chk CHECK (
    progress IS NULL
    OR (
      jsonb_typeof(progress) = 'object'
      AND (progress ->> 'phase') IN ('A', 'B', 'C', 'D', 'synthesis')
      AND (progress ->> 'completed') ~ '^[0-9]+$'
      AND (progress ->> 'total') ~ '^[0-9]+$'
      AND (progress ->> 'completed')::int >= 0
      AND (progress ->> 'total')::int >= 0
      AND (progress ->> 'completed')::int <= (progress ->> 'total')::int
    )
  );

COMMENT ON COLUMN core.matchup_runs.target_phase IS 'Pause/continue target for simulation v2; null for mock runs.';
COMMENT ON COLUMN core.matchup_runs.partial_result IS 'Progressive simulation envelope (v2); distinct from final report.';
COMMENT ON COLUMN core.matchup_runs.result_revision IS 'Increments once per published phase checkpoint.';
COMMENT ON COLUMN core.matchup_runs.progress IS 'In-flight counter {phase, completed, total} for UI.';
COMMENT ON COLUMN core.matchup_runs.execution_metadata IS 'Per-phase execution measurements; parameters/provenance stay frozen.';
COMMENT ON COLUMN core.matchup_runs.lease_token IS E'@omit';
COMMENT ON COLUMN core.matchup_runs.lease_expires_at IS E'@omit';
COMMENT ON COLUMN core.matchup_runs.heartbeat_at IS E'@omit';

CREATE TABLE core.analysis_commands (
  idempotency_key uuid PRIMARY KEY,
  operation text NOT NULL,
  request_hash text NOT NULL,
  run_id uuid REFERENCES core.matchup_runs (id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT analysis_commands_operation_chk CHECK (operation IN ('start', 'continue', 'cancel'))
);

COMMENT ON TABLE core.analysis_commands IS E'@omit';

CREATE TABLE core.matchup_run_battles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES core.matchup_runs (id) ON DELETE RESTRICT,
  phase text NOT NULL,
  sample_key text NOT NULL,
  format_version integer NOT NULL,
  outcome text NOT NULL,
  payload jsonb NOT NULL,
  sha256 text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT matchup_run_battles_phase_chk CHECK (phase IN ('C', 'D')),
  CONSTRAINT matchup_run_battles_outcome_chk CHECK (outcome IN ('win', 'loss', 'draw')),
  CONSTRAINT matchup_run_battles_run_phase_sample_uniq UNIQUE (run_id, phase, sample_key)
);

CREATE INDEX matchup_run_battles_run_phase_idx ON core.matchup_run_battles (run_id, phase);

COMMENT ON TABLE core.matchup_run_battles IS E'@omit';

DO $$
DECLARE
  dup record;
BEGIN
  FOR dup IN
    SELECT matchup_id, count(*) AS c
    FROM core.matchup_runs
    WHERE status IN ('queued', 'running')
    GROUP BY matchup_id
    HAVING count(*) > 1
  LOOP
    RAISE EXCEPTION 'cannot add active-run unique index: matchup % has % active runs',
      dup.matchup_id, dup.c;
  END LOOP;
END
$$;

CREATE UNIQUE INDEX matchup_runs_one_active_per_matchup_idx
  ON core.matchup_runs (matchup_id)
  WHERE status IN ('queued', 'running');

CREATE INDEX matchup_runs_queued_acquisition_idx
  ON core.matchup_runs (created_at, id)
  WHERE status = 'queued';
