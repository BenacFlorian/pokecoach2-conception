-- JSON null and absent both mean "not calculated" for simulation v2 envelopes.

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

COMMENT ON FUNCTION core.jsonb_contract_field_present IS E'@omit';
