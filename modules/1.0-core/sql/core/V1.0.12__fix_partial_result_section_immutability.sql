-- JSON null optional fields are not "published sections" (see jsonb_contract_field_present).

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
    IF core.jsonb_contract_field_present(OLD.partial_result, 'leadPick')
      AND (NEW.partial_result -> 'leadPick') IS DISTINCT FROM (OLD.partial_result -> 'leadPick') THEN
      RAISE EXCEPTION 'published leadPick section is immutable';
    END IF;
    IF core.jsonb_contract_field_present(OLD.partial_result, 'refinement')
      AND (NEW.partial_result -> 'refinement') IS DISTINCT FROM (OLD.partial_result -> 'refinement') THEN
      RAISE EXCEPTION 'published refinement section is immutable';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
