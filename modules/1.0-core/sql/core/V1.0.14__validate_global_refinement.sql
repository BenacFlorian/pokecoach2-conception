-- Global refinement contract (phase D weighted A/B sampling).

CREATE OR REPLACE FUNCTION core.is_valid_refinement_section_v2(p_ref jsonb)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
DECLARE
  sample_size int;
  wins int;
  losses int;
  draws int;
  m int;
  row jsonb;
  row_sum int := 0;
  battle_len int;
BEGIN
  IF p_ref IS NULL OR jsonb_typeof(p_ref) <> 'object' THEN
    RETURN false;
  END IF;
  IF p_ref ->> 'samplingPolicy' IS DISTINCT FROM 'weighted-ab' THEN
    RETURN false;
  END IF;
  IF p_ref ->> 'samplingScope' IS DISTINCT FROM 'all-observed-leads' THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'configuration')
    OR jsonb_typeof(p_ref -> 'configuration') <> 'object' THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'sampleSize')
    OR jsonb_typeof(p_ref -> 'sampleSize') <> 'number' THEN
    RETURN false;
  END IF;
  sample_size := (p_ref ->> 'sampleSize')::int;
  IF sample_size <= 0 THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'outcomes')
    OR jsonb_typeof(p_ref -> 'outcomes') <> 'object' THEN
    RETURN false;
  END IF;
  wins := COALESCE((p_ref -> 'outcomes' ->> 'wins')::int, -1);
  losses := COALESCE((p_ref -> 'outcomes' ->> 'losses')::int, -1);
  draws := COALESCE((p_ref -> 'outcomes' ->> 'draws')::int, -1);
  IF wins < 0 OR losses < 0 OR draws < 0 THEN
    RETURN false;
  END IF;
  IF wins + losses + draws <> sample_size THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'scenarioCounts')
    OR jsonb_typeof(p_ref -> 'scenarioCounts') <> 'array' THEN
    RETURN false;
  END IF;
  FOR row IN
  SELECT *
  FROM jsonb_array_elements(p_ref -> 'scenarioCounts')
  LOOP
    IF NOT (row ? 'count') OR (row ->> 'count')::int <= 0 THEN
      RETURN false;
    END IF;
    row_sum := row_sum + (row ->> 'count')::int;
  END LOOP;
  IF row_sum <> sample_size THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'firstTurnSampleSize')
    OR jsonb_typeof(p_ref -> 'firstTurnSampleSize') <> 'number' THEN
    RETURN false;
  END IF;
  m := (p_ref ->> 'firstTurnSampleSize')::int;
  IF m < 0 OR m > sample_size THEN
    RETURN false;
  END IF;
  IF NOT (p_ref ? 'battleIds')
    OR jsonb_typeof(p_ref -> 'battleIds') <> 'array' THEN
    RETURN false;
  END IF;
  battle_len := jsonb_array_length(p_ref -> 'battleIds');
  IF battle_len <> sample_size THEN
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
  ELSE
    IF core.jsonb_contract_field_present(p_payload, 'gameplan')
      OR core.jsonb_contract_field_present(p_payload, 'winCondition') THEN
      RETURN false;
    END IF;
  END IF;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION core.is_valid_refinement_section_v2 IS E'@omit';
