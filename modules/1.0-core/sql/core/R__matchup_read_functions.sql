CREATE OR REPLACE FUNCTION core.matchups_latest_successful_run(m core.matchups)
  RETURNS core.matchup_runs
  LANGUAGE sql
  STABLE
  SECURITY INVOKER
  AS $$
  SELECT r.*
  FROM core.matchup_runs AS r
  WHERE r.matchup_id = m.id
    AND r.status = 'succeeded'
  ORDER BY r.created_at DESC, r.id DESC
  LIMIT 1;
$$;

COMMENT ON FUNCTION core.matchups_latest_successful_run IS 'Latest succeeded preparation for a matchup.';

CREATE OR REPLACE FUNCTION core.is_valid_mock_report_v1(p_report jsonb)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
BEGIN
  IF p_report IS NULL OR jsonb_typeof(p_report) <> 'object' THEN
    RETURN false;
  END IF;
  IF p_report ->> 'source' <> 'mock' THEN
    RETURN false;
  END IF;
  IF (p_report ->> 'fixtureVersion')::int IS DISTINCT FROM 1 THEN
    RETURN false;
  END IF;
  IF NOT (p_report ? 'phaseASampleSize')
    OR NOT (p_report ? 'phaseBSampleSize')
    OR NOT (p_report ? 'phaseCSampleSize')
    OR NOT (p_report ? 'phaseDSampleSize')
    OR NOT (p_report ? 'opponentLeads')
    OR NOT (p_report ? 'selectionComparisons')
    OR NOT (p_report ? 'leadRecommendation')
    OR NOT (p_report ? 'gameplan') THEN
    RETURN false;
  END IF;
  IF (p_report ->> 'phaseASampleSize')::int < 0
    OR (p_report ->> 'phaseBSampleSize')::int < 0
    OR (p_report ->> 'phaseCSampleSize')::int < 0
    OR (p_report ->> 'phaseDSampleSize')::int < 0 THEN
    RETURN false;
  END IF;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION core.is_valid_mock_report_v1 IS E'@omit';
