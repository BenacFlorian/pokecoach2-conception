-- Pipeline progress for matchup analysis (frontend polling / UI states).
CREATE TYPE core.matchup_run_process_status AS ENUM (
  'INITIAL',
  'PENDING STATS',
  'PENDING GAME SIMULATIONS',
  'SUCCESS',
  'ERROR'
);

COMMENT ON TYPE core.matchup_run_process_status IS 'Coarse backend pipeline step exposed to the UI; extensible via new enum values.';

ALTER TABLE core.matchup_runs
  ADD COLUMN process_status core.matchup_run_process_status NOT NULL DEFAULT 'INITIAL';

COMMENT ON COLUMN core.matchup_runs.process_status IS 'Analysis pipeline step for UI progress.';

ALTER TABLE core.matchup_runs DISABLE TRIGGER USER;

UPDATE core.matchup_runs
SET process_status = 'SUCCESS'
WHERE status = 'succeeded';

UPDATE core.matchup_runs
SET process_status = 'ERROR'
WHERE status IN ('failed', 'cancelled');

ALTER TABLE core.matchup_runs ENABLE TRIGGER USER;

CREATE OR REPLACE FUNCTION core.matchup_runs_immutable_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF OLD.status IN ('succeeded', 'failed', 'cancelled') THEN
    IF NEW.process_status IS DISTINCT FROM OLD.process_status THEN
      RAISE EXCEPTION 'process_status is immutable on terminal run';
    END IF;
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
    IF NEW.status = 'succeeded' THEN
      NEW.process_status := 'SUCCESS';
    ELSIF NEW.status = 'failed' THEN
      NEW.process_status := 'ERROR';
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
    NEW.process_status := 'SUCCESS';
    IF NEW.report IS NULL OR jsonb_typeof(NEW.report) <> 'object' OR NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'succeeded run requires report and finished_at';
    END IF;
  ELSIF NEW.status = 'failed' THEN
    NEW.process_status := 'ERROR';
    IF NEW.error_message IS NULL OR btrim(NEW.error_message) = '' OR NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'failed run requires error_message and finished_at';
    END IF;
  ELSIF NEW.status = 'cancelled' THEN
    NEW.process_status := 'ERROR';
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

CREATE OR REPLACE FUNCTION core.matchup_runs_process_status_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status IN ('succeeded', 'failed', 'cancelled') THEN
    IF NEW.process_status IS DISTINCT FROM OLD.process_status THEN
      RAISE EXCEPTION 'process_status cannot change after terminal status';
    END IF;
  END IF;
  IF NEW.process_status = 'SUCCESS'
    AND NEW.status NOT IN ('succeeded') THEN
    RAISE EXCEPTION 'SUCCESS process_status requires succeeded run status';
  END IF;
  IF NEW.process_status = 'ERROR'
    AND NEW.status NOT IN ('failed', 'cancelled') THEN
    RAISE EXCEPTION 'ERROR process_status requires failed or cancelled run status';
  END IF;
  IF NEW.status IN ('queued', 'running')
    AND NEW.process_status IN ('SUCCESS', 'ERROR') THEN
    RAISE EXCEPTION 'terminal process_status incompatible with in-progress run status';
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION core.matchup_runs_process_status_tr_fn IS E'@omit';

CREATE TRIGGER matchup_runs_process_status_tr
  BEFORE INSERT OR UPDATE OF process_status, status ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_process_status_tr_fn();
