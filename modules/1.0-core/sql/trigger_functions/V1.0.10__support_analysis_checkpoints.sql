-- Analysis checkpoints, simulation v2 validation, worker snapshot fix (plan 03 task 2).

CREATE OR REPLACE FUNCTION core.jsonb_contract_field_present(p_obj jsonb, p_key text)
  RETURNS boolean
  LANGUAGE sql
  IMMUTABLE
  AS $$
  SELECT p_obj ? p_key AND jsonb_typeof(p_obj -> p_key) <> 'null';
$$;

CREATE OR REPLACE FUNCTION core.is_valid_simulation_result_v2(
  p_payload jsonb,
  p_require_complete boolean DEFAULT false
)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
DECLARE
  phases jsonb;
  phase text;
  expected text[] := ARRAY['A', 'B', 'C', 'D', 'synthesis'];
  i int;
  n int;
BEGIN
  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN
    RETURN false;
  END IF;
  IF (p_payload ->> 'schemaVersion')::int IS DISTINCT FROM 2 THEN
    RETURN false;
  END IF;
  IF p_payload ->> 'source' <> 'simulation' THEN
    RETURN false;
  END IF;
  IF NOT (p_payload ? 'completedPhases')
    OR jsonb_typeof(p_payload -> 'completedPhases') <> 'array' THEN
    RETURN false;
  END IF;
  phases := p_payload -> 'completedPhases';
  n := jsonb_array_length(phases);
  IF n > array_length(expected, 1) THEN
    RETURN false;
  END IF;
  FOR i IN 0..(n - 1) LOOP
    phase := phases ->> i;
    IF phase IS DISTINCT FROM expected[i + 1] THEN
      RETURN false;
    END IF;
  END LOOP;
  IF n >= 1 AND NOT core.jsonb_contract_field_present(p_payload, 'opponentLeads') THEN
    RETURN false;
  END IF;
  IF n < 1 AND core.jsonb_contract_field_present(p_payload, 'opponentLeads') THEN
    RETURN false;
  END IF;
  IF n >= 3 AND NOT core.jsonb_contract_field_present(p_payload, 'leadPick') THEN
    RETURN false;
  END IF;
  IF n < 3 AND core.jsonb_contract_field_present(p_payload, 'leadPick') THEN
    RETURN false;
  END IF;
  IF n >= 4 AND NOT core.jsonb_contract_field_present(p_payload, 'refinement') THEN
    RETURN false;
  END IF;
  IF n < 4 AND core.jsonb_contract_field_present(p_payload, 'refinement') THEN
    RETURN false;
  END IF;
  IF p_require_complete OR n = 5 THEN
    IF n <> 5 THEN
      RETURN false;
    END IF;
    IF NOT core.jsonb_contract_field_present(p_payload, 'gameplan')
      OR NOT core.jsonb_contract_field_present(p_payload, 'winCondition') THEN
      RETURN false;
    END IF;
  ELSE
    IF core.jsonb_contract_field_present(p_payload, 'gameplan')
      OR core.jsonb_contract_field_present(p_payload, 'winCondition') THEN
      RETURN false;
    END IF;
  END IF;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION core.is_valid_simulation_result_v2 IS E'@omit';
COMMENT ON FUNCTION core.jsonb_contract_field_present IS E'@omit';

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_sim_v2_shape_chk CHECK (
    NOT (source = 'simulation' AND report_version = 2)
    OR (
      target_phase IS NOT NULL
      AND partial_result IS NOT NULL
      AND core.is_valid_simulation_result_v2(partial_result, false)
    )
  );

ALTER TABLE core.matchup_runs
  ADD CONSTRAINT matchup_runs_sim_v2_lease_when_paused_chk CHECK (
    status <> 'paused'
    OR (lease_token IS NULL AND lease_expires_at IS NULL)
  );

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
  IF OLD.status = 'paused' AND NEW.status = 'queued' THEN
    IF NEW.target_phase IS NULL OR OLD.target_phase IS NULL THEN
      RAISE EXCEPTION 'continue requires target_phase';
    END IF;
    IF NEW.target_phase = OLD.target_phase THEN
      RAISE EXCEPTION 'continue target must exceed paused prefix';
    END IF;
  ELSIF NEW.target_phase IS DISTINCT FROM OLD.target_phase
    AND NOT (OLD.status = 'paused' AND NEW.status = 'queued') THEN
    RAISE EXCEPTION 'target_phase is frozen except paused to queued continue';
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
    IF NEW.source = 'simulation' AND NEW.report_version = 2 THEN
      IF NEW.status NOT IN ('queued', 'running') THEN
        RAISE EXCEPTION 'simulation v2 must start queued or running';
      END IF;
    ELSIF NEW.status NOT IN ('queued', 'running')
      AND NOT (NEW.source = 'mock' AND NEW.status = 'succeeded') THEN
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
  IF OLD.status = 'queued'
    AND NEW.status NOT IN ('queued', 'running', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'invalid transition from queued to %', NEW.status;
  END IF;
  IF OLD.status = 'running'
    AND NEW.status NOT IN ('running', 'paused', 'succeeded', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'invalid transition from running to %', NEW.status;
  END IF;
  IF OLD.status = 'paused'
    AND NEW.status NOT IN ('queued', 'failed', 'cancelled') THEN
    RAISE EXCEPTION 'invalid transition from paused to %', NEW.status;
  END IF;
  IF NEW.status = 'paused' THEN
    IF NEW.report IS NOT NULL OR NEW.finished_at IS NOT NULL THEN
      RAISE EXCEPTION 'paused run cannot store final report';
    END IF;
    IF NEW.lease_token IS NOT NULL OR NEW.lease_expires_at IS NOT NULL THEN
      RAISE EXCEPTION 'paused run must release lease';
    END IF;
  END IF;
  IF NEW.status = 'succeeded' THEN
    NEW.process_status := 'SUCCESS';
    IF NEW.source = 'simulation' AND NEW.report_version = 2 THEN
      IF NOT core.is_valid_simulation_result_v2(NEW.partial_result, true) THEN
        RAISE EXCEPTION 'succeeded simulation v2 requires complete partial_result';
      END IF;
      IF NEW.report IS DISTINCT FROM NEW.partial_result THEN
        RAISE EXCEPTION 'succeeded simulation v2 requires report = partial_result';
      END IF;
    ELSIF NEW.report IS NULL
      OR jsonb_typeof(NEW.report) <> 'object'
      OR NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'succeeded run requires report and finished_at';
    END IF;
    IF NEW.finished_at IS NULL THEN
      RAISE EXCEPTION 'succeeded run requires finished_at';
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
  IF NEW.status IN ('queued', 'running', 'paused') AND NEW.report IS NOT NULL THEN
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
  IF NEW.status IN ('queued', 'running', 'paused')
    AND NEW.process_status IN ('SUCCESS', 'ERROR') THEN
    RAISE EXCEPTION 'terminal process_status incompatible with in-progress run status';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_partial_result_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF NEW.source <> 'simulation' OR NEW.report_version <> 2 THEN
    RETURN NEW;
  END IF;
  IF NEW.partial_result IS NULL THEN
    RAISE EXCEPTION 'simulation v2 requires partial_result';
  END IF;
  IF NOT core.is_valid_simulation_result_v2(NEW.partial_result, false) THEN
    RAISE EXCEPTION 'invalid simulation v2 partial_result envelope';
  END IF;
  IF TG_OP = 'UPDATE'
    AND OLD.partial_result IS NOT NULL
    AND NEW.result_revision IS NOT DISTINCT FROM OLD.result_revision
    AND NEW.partial_result IS DISTINCT FROM OLD.partial_result THEN
    RAISE EXCEPTION 'partial_result content change requires result_revision increment';
  END IF;
  IF TG_OP = 'UPDATE'
    AND NEW.result_revision > OLD.result_revision
    AND NEW.result_revision <> OLD.result_revision + 1 THEN
    RAISE EXCEPTION 'result_revision must increment by one per publication';
  END IF;
  IF TG_OP = 'UPDATE'
    AND NEW.result_revision = OLD.result_revision
    AND NEW.partial_result IS DISTINCT FROM OLD.partial_result THEN
    RAISE EXCEPTION 'partial_result cannot change without revision increment';
  END IF;
  IF TG_OP = 'UPDATE'
    AND OLD.partial_result IS NOT NULL
    AND NEW.result_revision > OLD.result_revision THEN
    IF (OLD.partial_result -> 'leadPick') IS NOT NULL
      AND (NEW.partial_result -> 'leadPick') IS DISTINCT FROM (OLD.partial_result -> 'leadPick') THEN
      RAISE EXCEPTION 'published leadPick section is immutable';
    END IF;
    IF (OLD.partial_result -> 'refinement') IS NOT NULL
      AND (NEW.partial_result -> 'refinement') IS DISTINCT FROM (OLD.partial_result -> 'refinement') THEN
      RAISE EXCEPTION 'published refinement section is immutable';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_runs_fill_snapshots_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = core, pg_temp
  AS $$
DECLARE
  our_id uuid;
  opp_id uuid;
  our_row core.teams;
  opp_row core.teams;
  m core.matchups;
BEGIN
  SELECT * INTO m FROM core.matchups WHERE id = NEW.matchup_id FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'matchup not found';
  END IF;
  IF m.is_deleted THEN
    RAISE EXCEPTION 'matchup is archived';
  END IF;
  our_id := m.our_team_id;
  opp_id := m.opponent_team_id;
  IF our_id < opp_id THEN
    SELECT * INTO our_row FROM core.teams WHERE id = our_id FOR SHARE;
    SELECT * INTO opp_row FROM core.teams WHERE id = opp_id FOR SHARE;
  ELSE
    SELECT * INTO opp_row FROM core.teams WHERE id = opp_id FOR SHARE;
    SELECT * INTO our_row FROM core.teams WHERE id = our_id FOR SHARE;
  END IF;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'team missing for matchup snapshot';
  END IF;
  IF our_row.is_deleted OR opp_row.is_deleted THEN
    RAISE EXCEPTION 'cannot run preparation on archived team';
  END IF;
  NEW.our_team_snapshot := core.team_row_to_snapshot_v1(our_row);
  NEW.opponent_team_snapshot := core.team_row_to_snapshot_v1(opp_row);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_run_battles_immutable_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
BEGIN
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'matchup_run_battles rows are immutable';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.matchup_run_battles_validate_tr_fn()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$
DECLARE
  run_row core.matchup_runs;
  published_phases jsonb;
BEGIN
  SELECT * INTO run_row FROM core.matchup_runs WHERE id = NEW.run_id FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'run not found for battle insert';
  END IF;
  IF run_row.status <> 'running' THEN
    RAISE EXCEPTION 'battles can only be inserted on running runs';
  END IF;
  published_phases := COALESCE(run_row.partial_result -> 'completedPhases', '[]'::jsonb);
  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(published_phases) AS p(phase)
    WHERE p.phase = NEW.phase
  ) THEN
    RAISE EXCEPTION 'cannot add battles after phase % is published', NEW.phase;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS matchup_runs_partial_result_tr ON core.matchup_runs;
CREATE TRIGGER matchup_runs_partial_result_tr
  BEFORE INSERT OR UPDATE OF partial_result, result_revision ON core.matchup_runs
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_runs_partial_result_tr_fn();

DROP TRIGGER IF EXISTS matchup_run_battles_immutable_tr ON core.matchup_run_battles;
CREATE TRIGGER matchup_run_battles_immutable_tr
  BEFORE UPDATE OR DELETE ON core.matchup_run_battles
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_run_battles_immutable_tr_fn();

DROP TRIGGER IF EXISTS matchup_run_battles_validate_tr ON core.matchup_run_battles;
CREATE TRIGGER matchup_run_battles_validate_tr
  BEFORE INSERT ON core.matchup_run_battles
  FOR EACH ROW
  EXECUTE FUNCTION core.matchup_run_battles_validate_tr_fn();

COMMENT ON FUNCTION core.matchup_runs_partial_result_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_run_battles_immutable_tr_fn IS E'@omit';
COMMENT ON FUNCTION core.matchup_run_battles_validate_tr_fn IS E'@omit';
