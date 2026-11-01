-- Conditioned openings contract: phase order A,C,B,D and openings section.

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
  expected text[] := ARRAY['A', 'C', 'B', 'D', 'synthesis'];
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
  IF n >= 2 AND NOT core.jsonb_contract_field_present(p_payload, 'leadPick') THEN
    RETURN false;
  END IF;
  IF n < 2 AND core.jsonb_contract_field_present(p_payload, 'leadPick') THEN
    RETURN false;
  END IF;
  IF n >= 3 AND NOT core.jsonb_contract_field_present(p_payload, 'openings') THEN
    RETURN false;
  END IF;
  IF n < 3 AND core.jsonb_contract_field_present(p_payload, 'openings') THEN
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
    IF core.jsonb_contract_field_present(OLD.partial_result, 'opponentLeads')
      AND (NEW.partial_result -> 'opponentLeads') IS DISTINCT FROM (OLD.partial_result -> 'opponentLeads') THEN
      RAISE EXCEPTION 'published opponentLeads section is immutable';
    END IF;
    IF core.jsonb_contract_field_present(OLD.partial_result, 'leadPick')
      AND (NEW.partial_result -> 'leadPick') IS DISTINCT FROM (OLD.partial_result -> 'leadPick') THEN
      RAISE EXCEPTION 'published leadPick section is immutable';
    END IF;
    IF core.jsonb_contract_field_present(OLD.partial_result, 'openings')
      AND (NEW.partial_result -> 'openings') IS DISTINCT FROM (OLD.partial_result -> 'openings') THEN
      RAISE EXCEPTION 'published openings section is immutable';
    END IF;
    IF core.jsonb_contract_field_present(OLD.partial_result, 'refinement')
      AND (NEW.partial_result -> 'refinement') IS DISTINCT FROM (OLD.partial_result -> 'refinement') THEN
      RAISE EXCEPTION 'published refinement section is immutable';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
