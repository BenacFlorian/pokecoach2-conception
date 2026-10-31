-- Analysis checkpoints and worker paths (plan 03 task 2).

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
  phase_a jsonb;
BEGIN
  phase_a := empty
    || jsonb_build_object(
      'completedPhases', jsonb_build_array('A'),
      'opponentLeads', jsonb_build_object(
        'sampleSize', 10,
        'leads', jsonb_build_array(
          jsonb_build_object(
            'id', 'lead-0-1',
            'slots', jsonb_build_array(0, 1),
            'count', 4,
            'turn1', null
          )
        )
      )
    );

  INSERT INTO core.teams (kind, name, source_kind, source_text, pokemon)
  VALUES (
    'owned',
    'Ck owned',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'C' || gs,
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
    'Ck opp',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'D' || gs,
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

  INSERT INTO core.matchup_runs (
    matchup_id,
    source,
    status,
    report_version,
    target_phase,
    partial_result,
    parameters,
    provenance
  )
  VALUES (
    matchup_id,
    'simulation',
    'running',
    2,
    'A',
    empty,
    '{"profile":"smoke"}'::jsonb,
    '{"origin":"test"}'::jsonb
  )
  RETURNING id INTO run_id;

  UPDATE core.matchup_runs
  SET status = 'running',
      progress = jsonb_build_object('phase', 'A', 'completed', 3, 'total', 10)
  WHERE id = run_id;

  UPDATE core.matchup_runs
  SET partial_result = phase_a,
      result_revision = 1,
      status = 'paused',
      target_phase = 'A',
      process_status = 'PENDING STATS'
  WHERE id = run_id;

  IF EXISTS (SELECT 1 FROM core.matchup_runs WHERE id = run_id AND finished_at IS NOT NULL) THEN
    RAISE EXCEPTION 'pause must keep finished_at null';
  END IF;

  UPDATE core.matchup_runs
  SET status = 'queued',
      target_phase = 'B'
  WHERE id = run_id;

  BEGIN
    UPDATE core.matchup_runs SET parameters = '{"profile":"hacked"}'::jsonb WHERE id = run_id;
    RAISE EXCEPTION 'parameters should stay frozen';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM NOT LIKE '%frozen%' THEN
        RAISE;
      END IF;
  END;

  BEGIN
    UPDATE core.matchup_runs
    SET status = 'succeeded',
        report = phase_a,
        finished_at = now()
    WHERE id = run_id;
    RAISE EXCEPTION 'incomplete simulation cannot succeed';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM NOT LIKE '%complete partial_result%'
        AND SQLERRM NOT LIKE '%report = partial_result%'
        AND SQLERRM NOT LIKE '%succeeded simulation v2%'
        AND SQLERRM NOT LIKE '%invalid transition from queued to succeeded%' THEN
        RAISE;
      END IF;
  END;
END
$$;

CREATE TEMP TABLE IF NOT EXISTS _worker_ctx (matchup_id uuid, owned_id uuid);

TRUNCATE _worker_ctx;

DO $$
DECLARE
  owned_id uuid;
  opp_id uuid;
  matchup_id uuid;
BEGIN
  INSERT INTO core.teams (kind, name, source_kind, source_text, pokemon)
  VALUES (
    'owned',
    'W owned',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'W' || gs,
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
    'W opp',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'X' || gs,
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

  INSERT INTO _worker_ctx VALUES (matchup_id, owned_id);
END
$$;

GRANT SELECT ON TABLE _worker_ctx TO pokecoach_worker;

SET ROLE pokecoach_worker;

DO $$
DECLARE
  ctx record;
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
  SELECT * INTO ctx FROM _worker_ctx LIMIT 1;

  INSERT INTO core.matchup_runs (
    matchup_id,
    source,
    status,
    report_version,
    target_phase,
    partial_result
  )
  VALUES (ctx.matchup_id, 'simulation', 'queued', 2, 'A', empty);

  BEGIN
    UPDATE core.teams SET name = 'evil' WHERE id = ctx.owned_id;
    RAISE EXCEPTION 'worker must not update teams';
  EXCEPTION
    WHEN insufficient_privilege THEN
      NULL;
  END;
END
$$;

RESET ROLE;

DO $$
BEGIN
  PERFORM core.reset_demo_dataset();
END
$$;
