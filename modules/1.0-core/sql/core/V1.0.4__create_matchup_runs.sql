CREATE TABLE core.matchup_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  matchup_id uuid NOT NULL REFERENCES core.matchups (id) ON DELETE RESTRICT,
  source text NOT NULL,
  status text NOT NULL,
  our_team_snapshot jsonb NOT NULL,
  opponent_team_snapshot jsonb NOT NULL,
  parameters jsonb NOT NULL DEFAULT '{}'::jsonb,
  provenance jsonb NOT NULL DEFAULT '{}'::jsonb,
  report_version integer NOT NULL DEFAULT 1,
  report jsonb,
  error_message text,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by text NOT NULL DEFAULT 'system',
  updated_by text NOT NULL DEFAULT 'system',
  CONSTRAINT matchup_runs_source_chk CHECK (source IN ('mock', 'simulation')),
  CONSTRAINT matchup_runs_status_chk CHECK (status IN ('queued', 'running', 'succeeded', 'failed', 'cancelled')),
  CONSTRAINT matchup_runs_report_version_chk CHECK (report_version > 0)
);

CREATE INDEX matchup_runs_matchup_idx ON core.matchup_runs (matchup_id, status, created_at DESC, id);

COMMENT ON TABLE core.matchup_runs IS 'Immutable preparation runs for a matchup.';
COMMENT ON COLUMN core.matchup_runs.our_team_snapshot IS E'@omit create,update';
COMMENT ON COLUMN core.matchup_runs.opponent_team_snapshot IS E'@omit create,update';
COMMENT ON COLUMN core.matchup_runs.matchup_id IS E'@omit update';
COMMENT ON COLUMN core.matchup_runs.source IS E'@omit update';
COMMENT ON COLUMN core.matchup_runs.parameters IS E'@omit update';
COMMENT ON COLUMN core.matchup_runs.provenance IS E'@omit update';
COMMENT ON COLUMN core.matchup_runs.report IS E'@omit create,update';
COMMENT ON COLUMN core.matchup_runs.report_version IS E'@omit create,update';
