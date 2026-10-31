CREATE TABLE core.matchups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  our_team_id uuid NOT NULL REFERENCES core.teams (id) ON DELETE RESTRICT,
  opponent_team_id uuid NOT NULL REFERENCES core.teams (id) ON DELETE RESTRICT,
  regulation text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by text NOT NULL DEFAULT 'system',
  updated_by text NOT NULL DEFAULT 'system',
  is_deleted boolean NOT NULL DEFAULT false,
  CONSTRAINT matchups_distinct_teams_chk CHECK (our_team_id <> opponent_team_id)
);

CREATE INDEX matchups_our_team_idx ON core.matchups (our_team_id, is_deleted, created_at DESC, id);

COMMENT ON TABLE core.matchups IS 'Pairing between one owned team and one opponent team.';
COMMENT ON COLUMN core.matchups.our_team_id IS E'@omit update';
COMMENT ON COLUMN core.matchups.opponent_team_id IS E'@omit update';
