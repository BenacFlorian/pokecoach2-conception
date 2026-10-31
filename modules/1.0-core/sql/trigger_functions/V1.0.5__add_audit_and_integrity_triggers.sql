-- Session actor for audit columns (set by application server).
CREATE OR REPLACE FUNCTION core.current_actor()
  RETURNS text
  LANGUAGE sql
  STABLE
  AS $$
  SELECT coalesce(nullif(current_setting('pokecoach.actor', true), ''), 'system');
$$;

COMMENT ON FUNCTION core.current_actor IS E'@omit';

CREATE OR REPLACE FUNCTION core.core_set_fields_created_byat_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  NEW.created_by := core.current_actor();
  NEW.created_at := now();
  NEW.updated_by := core.current_actor();
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.core_set_fields_updated_byat_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  NEW.updated_by := core.current_actor();
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION core.core_set_fields_created_byat_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.core_set_fields_updated_byat_tr_fn IS E'@omit';

CREATE OR REPLACE FUNCTION core.team_row_to_snapshot_v1(t core.teams)
  RETURNS jsonb
  LANGUAGE sql
  STABLE
  AS $$
  SELECT jsonb_build_object(
    'id',
    t.id::text,
    'name',
    t.name,
    'source',
    jsonb_strip_nulls(
      jsonb_build_object(
        'kind',
        t.source_kind,
        'rawText',
        t.source_text,
        'url',
        t.source_url
      )
    ),
    'pokemon',
    t.pokemon,
    'createdAt',
    to_char(t.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  );
$$;

COMMENT ON FUNCTION core.team_row_to_snapshot_v1 IS E'@omit';

CREATE OR REPLACE FUNCTION core.teams_kind_immutable_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.kind IS DISTINCT FROM OLD.kind THEN
    RAISE EXCEPTION 'teams.kind is immutable';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchups_validate_teams_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  our_kind text;
  opp_kind text;
BEGIN
  SELECT kind INTO our_kind FROM core.teams WHERE id = NEW.our_team_id;
  SELECT kind INTO opp_kind FROM core.teams WHERE id = NEW.opponent_team_id;
  IF our_kind IS NULL OR opp_kind IS NULL THEN
    RAISE EXCEPTION 'matchup references missing team';
  END IF;
  IF our_kind <> 'owned' OR opp_kind <> 'opponent' THEN
    RAISE EXCEPTION 'matchup team roles must be owned vs opponent';
  END IF;
  IF EXISTS (
    SELECT 1
    FROM core.teams
    WHERE id IN (NEW.our_team_id, NEW.opponent_team_id)
      AND is_deleted
  ) THEN
    RAISE EXCEPTION 'cannot create matchup on archived team';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_fill_snapshots_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  our_row core.teams;
  opp_row core.teams;
  m core.matchups;
BEGIN
  SELECT * INTO m FROM core.matchups WHERE id = NEW.matchup_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'matchup not found';
  END IF;
  IF m.is_deleted THEN
    RAISE EXCEPTION 'matchup is archived';
  END IF;
  SELECT * INTO our_row FROM core.teams WHERE id = m.our_team_id FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'our team missing for matchup snapshot';
  END IF;
  SELECT * INTO opp_row FROM core.teams WHERE id = m.opponent_team_id FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'opponent team missing for matchup snapshot';
  END IF;
  IF our_row.is_deleted OR opp_row.is_deleted THEN
    RAISE EXCEPTION 'cannot run preparation on archived team';
  END IF;
  NEW.our_team_snapshot := core.team_row_to_snapshot_v1(our_row);
  NEW.opponent_team_snapshot := core.team_row_to_snapshot_v1(opp_row);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_immutable_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF OLD.status IN ('succeeded', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'terminal matchup run is immutable';
  END IF;
  IF NEW.matchup_id IS DISTINCT FROM OLD.matchup_id
    OR NEW.our_team_snapshot IS DISTINCT FROM OLD.our_team_snapshot
    OR NEW.opponent_team_snapshot IS DISTINCT FROM OLD.opponent_team_snapshot
    OR NEW.source IS DISTINCT FROM OLD.source
    OR NEW.report_version IS DISTINCT FROM OLD.report_version THEN
    RAISE EXCEPTION 'frozen matchup run fields cannot change after creation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_status_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status NOT IN ('queued', 'running') AND NOT (NEW.source = 'mock' AND NEW.status = 'succeeded') THEN
      RAISE EXCEPTION 'invalid initial status %', NEW.status;
    END IF;
    RETURN NEW;
  END IF;
  IF OLD.status IN ('succeeded', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'terminal status cannot transition';
  END IF;
  IF OLD.status = 'queued' AND NEW.status NOT IN ('running', 'cancelled', 'failed', 'succeeded') THEN
    RAISE EXCEPTION 'invalid transition from queued to %', NEW.status;
  END IF;
  IF OLD.status = 'running' AND NEW.status NOT IN ('succeeded', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'invalid transition from running to %', NEW.status;
  END IF;
  IF NEW.status = 'succeeded' THEN
    IF NEW.report IS NULL OR jsonb_typeof(NEW.report) <> 'object' OR NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'succeeded run requires report and finished_at';
    END IF;
  ELSIF NEW.status = 'failed' THEN
    IF NEW.error_message IS NULL OR btrim(NEW.error_message) = '' OR NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'failed run requires error_message and finished_at';
    END IF;
  ELSIF NEW.status = 'cancelled' THEN
    IF NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'cancelled run requires finished_at';
    END IF;
  END IF;
  IF NEW.status IN ('queued', 'running') AND NEW.report IS NOT NULL THEN
    RAISE EXCEPTION 'non-terminal run cannot store final report';
  END IF;
  IF NEW.started_at IS NOT NULL
    AND NEW.finished_at IS NOT NULL
    AND NEW.finished_at < NEW.started_at THEN
    RAISE EXCEPTION 'finished_at precedes started_at';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_freeze_params_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status <> 'queued' THEN
    IF NEW.parameters IS DISTINCT FROM OLD.parameters OR NEW.provenance IS DISTINCT FROM OLD.provenance THEN
      RAISE EXCEPTION 'parameters and provenance frozen after queued';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER teams_kind_immutable_tr
  BEFORE UPDATE ON core.teams
  FOR EACH ROW
  EXECUTE FUNCTION core.teams_kind_immutable_tr_fn();

CREATE TRIGGER teams_created_audit_tr
  BEFORE INSERT ON core.teams
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_created_byat_tr_fn();

CREATE TRIGGER teams_updated_audit_tr
  BEFORE UPDATE ON core.teams
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_updated_byat_tr_fn();

CREATE TRIGGER matchups_validate_teams_tr
  BEFORE INSERT ON core.matchups
  FOR EACH ROW
  EXECUTE FUNCTION core.matchups_validate_teams_tr_fn();

CREATE TRIGGER matchups_created_audit_tr
  BEFORE INSERT ON core.matchups
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_created_byat_tr_fn();

CREATE TRIGGER matchups_updated_audit_tr
  BEFORE UPDATE ON core.matchups
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_updated_byat_tr_fn();

CREATE TRIGGER matchup_runs_fill_snapshots_tr
  BEFORE INSERT ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_fill_snapshots_tr_fn();

CREATE TRIGGER matchup_runs_status_tr
  BEFORE INSERT OR UPDATE ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_status_tr_fn();

CREATE TRIGGER matchup_runs_immutable_tr
  BEFORE UPDATE ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_immutable_tr_fn();

CREATE TRIGGER matchup_runs_freeze_params_tr
  BEFORE UPDATE ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_freeze_params_tr_fn();

CREATE TRIGGER matchup_runs_created_audit_tr
  BEFORE INSERT ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_created_byat_tr_fn();

CREATE TRIGGER matchup_runs_updated_audit_tr
  BEFORE UPDATE ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.core_set_fields_updated_byat_tr_fn();

COMMENT ON FUNCTION core.teams_kind_immutable_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchups_validate_teams_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_runs_fill_snapshots_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_runs_immutable_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_runs_status_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_runs_freeze_params_tr_fn IS E'@omit';
