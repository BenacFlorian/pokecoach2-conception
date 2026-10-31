-- Grants and PostGraphile hints after migrate.
DO $$
DECLARE
  tbl record;
  col_name text;
  audit_cols text[] := ARRAY['created_by', 'created_at', 'updated_by', 'updated_at'];
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'core' AND table_name = 'flyway_schema_history'
  ) THEN
    EXECUTE $cmd$COMMENT ON TABLE core.flyway_schema_history IS E'@omit\n@name flyway_core'$cmd$;
    REVOKE ALL ON TABLE core.flyway_schema_history FROM PUBLIC;
    REVOKE ALL ON TABLE core.flyway_schema_history FROM authenticated_user;
  END IF;
END
$$;

GRANT USAGE ON SCHEMA core TO authenticated_user;
GRANT USAGE ON SCHEMA core TO pokecoach_worker;

CREATE TABLE IF NOT EXISTS core.stack_sentinel (
  id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE core.stack_sentinel IS E'@omit';

INSERT INTO core.stack_sentinel (id)
VALUES ('pokecoach2-local')
ON CONFLICT (id) DO NOTHING;

GRANT SELECT ON core.teams, core.matchups, core.matchup_runs TO authenticated_user;
GRANT INSERT ON core.teams, core.matchups TO authenticated_user;
GRANT UPDATE (name, source_kind, source_url, source_text, pokemon, is_deleted) ON core.teams TO authenticated_user;
GRANT UPDATE (regulation, is_deleted) ON core.matchups TO authenticated_user;

REVOKE DELETE ON core.teams, core.matchups, core.matchup_runs FROM authenticated_user;

GRANT SELECT ON core.teams, core.matchups TO pokecoach_worker;
GRANT UPDATE (regulation) ON core.matchups TO pokecoach_worker;
GRANT SELECT, INSERT, UPDATE ON core.matchup_runs TO pokecoach_worker;
GRANT SELECT, INSERT ON core.analysis_commands TO pokecoach_worker;
GRANT SELECT, INSERT ON core.matchup_run_battles TO pokecoach_worker;

REVOKE ALL ON TABLE core.analysis_commands FROM PUBLIC, authenticated_user;
REVOKE ALL ON TABLE core.matchup_run_battles FROM PUBLIC, authenticated_user;

REVOKE ALL ON TABLE core.stack_sentinel FROM authenticated_user, pokecoach_worker;

GRANT EXECUTE ON FUNCTION core.matchups_latest_successful_run(core.matchups) TO authenticated_user, pokecoach_worker;

REVOKE ALL ON FUNCTION core.is_valid_pokemon_sets(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION core.is_valid_pokemon_slot_entry(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION core.is_valid_mock_report_v1(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION core.is_valid_simulation_result_v2(jsonb, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION core.current_actor() FROM PUBLIC;
REVOKE ALL ON FUNCTION core.team_row_to_snapshot_v1(core.teams) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION core.is_valid_pokemon_sets(jsonb) TO authenticated_user, pokecoach_worker;
GRANT EXECUTE ON FUNCTION core.current_actor() TO authenticated_user, pokecoach_worker;
GRANT EXECUTE ON FUNCTION core.is_valid_pokemon_slot_entry(jsonb) TO authenticated_user, pokecoach_worker;
GRANT EXECUTE ON FUNCTION core.is_valid_simulation_result_v2(jsonb, boolean) TO authenticated_user, pokecoach_worker;
GRANT EXECUTE ON FUNCTION core.team_row_to_snapshot_v1(core.teams) TO pokecoach_worker;

COMMENT ON TABLE core.matchup_runs IS E'@omit create,update,delete';

DO $$
DECLARE
  col record;
  audit_cols text[] := ARRAY['created_by', 'created_at', 'updated_by', 'updated_at'];
BEGIN
  FOR col IN
    SELECT table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'core'
      AND column_name = ANY (audit_cols)
  LOOP
    EXECUTE format(
      'COMMENT ON COLUMN core.%I.%I IS E''@omit create,update''',
      col.table_name,
      col.column_name
    );
  END LOOP;
END
$$;
