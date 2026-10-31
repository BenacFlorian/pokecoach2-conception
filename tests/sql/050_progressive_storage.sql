-- Progressive storage (plan 03 task 1).

DO $$
DECLARE
  owned_id uuid;
  opp_id uuid;
  matchup_id uuid;
  run_id uuid;
  empty jsonb := '{
    "schemaVersion": 2,
    "source": "simulation",
    "completedPhases": [],
    "opponentLeads": null,
    "leadPick": null,
    "refinement": null,
    "gameplan": null,
    "winCondition": null
  }'::jsonb;
BEGIN
  INSERT INTO core.teams (kind, name, source_kind, source_text, pokemon)
  VALUES (
    'owned',
    'Prog owned',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'A' || gs,
          'moves', jsonb_build_array('Protect'),
          'rawBlock', 'b'
        ) ORDER BY gs
      )
      FROM generate_series(0, 5) gs
    )
  )
  RETURNING id INTO owned_id;

  INSERT INTO core.teams (kind, name, source_kind, source_text, pokemon)
  VALUES (
    'opponent',
    'Prog opp',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'B' || gs,
          'moves', jsonb_build_array('Protect'),
          'rawBlock', 'b'
        ) ORDER BY gs
      )
      FROM generate_series(0, 5) gs
    )
  )
  RETURNING id INTO opp_id;

  INSERT INTO core.matchups (our_team_id, opponent_team_id, regulation)
  VALUES (owned_id, opp_id, 'regf')
  RETURNING id INTO matchup_id;

  INSERT INTO core.matchup_runs (matchup_id, source, status, report, finished_at)
  VALUES (
    matchup_id,
    'mock',
    'succeeded',
    '{"source":"mock","fixtureVersion":1,"phaseASampleSize":1,"phaseBSampleSize":1,"phaseCSampleSize":1,"phaseDSampleSize":1,"opponentLeads":[],"selectionComparisons":[],"leadRecommendation":{"ourFourSlots":[0,1,2,3],"ourLeadSlots":[0,1],"justification":"j","selectionResults":[],"studiedLeads":[]},"gameplan":{"opening":"o","midgame":"m","endgame":"e","threats":[],"preserve":[],"eliminate":[],"adaptations":[],"winCondition":"w","refinementSequences":[],"sampleLimitation":"s"}}'::jsonb,
    now()
  );

  INSERT INTO core.matchup_runs (
    matchup_id,
    source,
    status,
    report_version,
    target_phase,
    partial_result
  )
  VALUES (matchup_id, 'simulation', 'queued', 2, 'A', empty)
  RETURNING id INTO run_id;

  IF NOT core.is_valid_simulation_result_v2(empty, false) THEN
    RAISE EXCEPTION 'empty v2 envelope should validate';
  END IF;

  BEGIN
    INSERT INTO core.matchup_runs (
      matchup_id, source, status, report_version, target_phase, partial_result
    )
    VALUES (matchup_id, 'simulation', 'queued', 2, 'Z', empty);
    RAISE EXCEPTION 'invalid target_phase should fail';
  EXCEPTION
    WHEN check_violation THEN
      NULL;
  END;

  BEGIN
    INSERT INTO core.analysis_commands (idempotency_key, operation, request_hash, run_id)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, 'start', 'h1', run_id);
    INSERT INTO core.analysis_commands (idempotency_key, operation, request_hash, run_id)
    VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid, 'start', 'h1', run_id);
    RAISE EXCEPTION 'duplicate idempotency should fail';
  EXCEPTION
    WHEN unique_violation THEN
      NULL;
  END;

  UPDATE core.matchup_runs SET status = 'running' WHERE id = run_id;

  BEGIN
    INSERT INTO core.matchup_run_battles (
      run_id, phase, sample_key, format_version, outcome, payload, sha256
    )
    VALUES (run_id, 'C', 's1', 1, 'win', '{}'::jsonb, 'abc');
    INSERT INTO core.matchup_run_battles (
      run_id, phase, sample_key, format_version, outcome, payload, sha256
    )
    VALUES (run_id, 'C', 's1', 1, 'loss', '{}'::jsonb, 'def');
    RAISE EXCEPTION 'duplicate battle sample should fail';
  EXCEPTION
    WHEN unique_violation THEN
      NULL;
  END;

  UPDATE core.matchup_runs
  SET status = 'paused',
      target_phase = 'A',
      lease_token = NULL,
      lease_expires_at = NULL
  WHERE id = run_id;

  INSERT INTO core.matchup_runs (
    matchup_id, source, status, report_version, target_phase, partial_result
  )
  VALUES (matchup_id, 'simulation', 'running', 2, 'B', empty);

  BEGIN
    INSERT INTO core.matchup_runs (
      matchup_id, source, status, report_version, target_phase, partial_result
    )
    VALUES (matchup_id, 'simulation', 'queued', 2, 'A', empty);
    RAISE EXCEPTION 'second active run should fail';
  EXCEPTION
    WHEN unique_violation THEN
      NULL;
  END;
END
$$;
