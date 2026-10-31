DO $$
DECLARE
  owned_id uuid;
  opp_id uuid;
  bad_match uuid;
BEGIN
  INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon)
  VALUES (
    gen_random_uuid(),
    'owned',
    'Ours',
    'text',
    NULL,
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'A',
          'moves', jsonb_build_array('Protect'),
          'rawBlock', 'b'
        ) ORDER BY gs
      )
      FROM generate_series(0, 5) gs
    )
  )
  RETURNING id INTO owned_id;

  INSERT INTO core.teams (id, kind, name, source_kind, source_text, pokemon)
  VALUES (
    gen_random_uuid(),
    'opponent',
    'Theirs',
    'text',
    'paste',
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'slot', gs,
          'species', 'B',
          'moves', jsonb_build_array('Protect'),
          'rawBlock', 'b'
        ) ORDER BY gs
      )
      FROM generate_series(0, 5) gs
    )
  )
  RETURNING id INTO opp_id;

  INSERT INTO core.matchups (our_team_id, opponent_team_id)
  VALUES (owned_id, opp_id)
  RETURNING id INTO bad_match;

  BEGIN
    INSERT INTO core.matchup_runs (matchup_id, source, status, report, finished_at)
    VALUES (
      bad_match,
      'mock',
      'succeeded',
      '{"source":"mock","fixtureVersion":1,"phaseASampleSize":1,"phaseBSampleSize":1,"phaseCSampleSize":1,"phaseDSampleSize":1,"opponentLeads":[],"selectionComparisons":[],"leadRecommendation":{"ourFourSlots":[0,1,2,3],"ourLeadSlots":[0,1],"justification":"j","selectionResults":[],"studiedLeads":[]},"gameplan":{"opening":"o","midgame":"m","endgame":"e","threats":[],"preserve":[],"eliminate":[],"adaptations":[],"winCondition":"w","refinementSequences":[],"sampleLimitation":"s"}}'::jsonb,
      now()
    );
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'mock succeeded insert failed: %', SQLERRM;
  END;
END
$$;
