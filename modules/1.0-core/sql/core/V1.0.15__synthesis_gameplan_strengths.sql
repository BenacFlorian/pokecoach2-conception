-- Phase E: gameplan strengths/threats contract and complete result validation.

CREATE OR REPLACE FUNCTION core.is_valid_gameplan_section_v2(p_gameplan jsonb)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
DECLARE
  item jsonb;
  strengths_len int;
  threats_len int;
BEGIN
  IF p_gameplan IS NULL OR jsonb_typeof(p_gameplan) <> 'object' THEN
    RETURN false;
  END IF;
  FOR item IN
  SELECT unnest(ARRAY['opening', 'midgame', 'endgame'])
  LOOP
    IF NOT (p_gameplan ? item)
      OR jsonb_typeof(p_gameplan -> item) <> 'string'
      OR length(trim(p_gameplan ->> item)) = 0 THEN
      RETURN false;
    END IF;
  END LOOP;
  IF NOT (p_gameplan ? 'strengths')
    OR jsonb_typeof(p_gameplan -> 'strengths') <> 'array' THEN
    RETURN false;
  END IF;
  IF NOT (p_gameplan ? 'threats')
    OR jsonb_typeof(p_gameplan -> 'threats') <> 'array' THEN
    RETURN false;
  END IF;
  strengths_len := jsonb_array_length(p_gameplan -> 'strengths');
  threats_len := jsonb_array_length(p_gameplan -> 'threats');
  IF strengths_len < 1 OR strengths_len > 2 OR threats_len < 1 OR threats_len > 2 THEN
    RETURN false;
  END IF;
  IF p_gameplan ? 'preserve'
    OR p_gameplan ? 'eliminate'
    OR p_gameplan ? 'adaptations' THEN
    RETURN false;
  END IF;
  RETURN true;
END;
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
  IF n >= 4 THEN
    IF NOT core.is_valid_refinement_section_v2(p_payload -> 'refinement') THEN
      RETURN false;
    END IF;
  END IF;
  IF p_require_complete OR n = 5 THEN
    IF n <> 5 THEN
      RETURN false;
    END IF;
    IF NOT core.jsonb_contract_field_present(p_payload, 'gameplan')
      OR NOT core.jsonb_contract_field_present(p_payload, 'winCondition') THEN
      RETURN false;
    END IF;
    IF NOT core.is_valid_gameplan_section_v2(p_payload -> 'gameplan') THEN
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

COMMENT ON FUNCTION core.is_valid_gameplan_section_v2 IS E'@omit';
