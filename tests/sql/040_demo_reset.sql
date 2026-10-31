SET ROLE pokecoach_worker;

SELECT (core.reset_demo_dataset()->>'matchupId') = 'c3333333-3333-4333-8333-333333333301'::text AS reset_ok;

SELECT COUNT(*) = 3 FROM core.teams
WHERE id IN (
  'a1111111-1111-4111-8111-111111111101'::uuid,
  'a1111111-1111-4111-8111-111111111102'::uuid,
  'b2222222-2222-4222-8222-222222222201'::uuid
);

SELECT (core.reset_demo_dataset()->'counts'->>'teams')::int = 3 AS teams_count;
SELECT (core.reset_demo_dataset()->'counts'->>'matchups')::int = 1 AS matchups_count;

RESET ROLE;

INSERT INTO core.teams (id, kind, name, source_kind, source_text, pokemon)
VALUES (
  'd4444444-4444-4444-8444-444444444401'::uuid,
  'owned',
  'Witness team',
  'text',
  'paste',
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'slot', gs,
        'species', 'Pikachu',
        'moves', jsonb_build_array('Protect'),
        'rawBlock', 'b'
      ) ORDER BY gs
    )
    FROM generate_series(0, 5) gs
  )
);

INSERT INTO core.matchups (id, our_team_id, opponent_team_id)
VALUES (
  'e5555555-5555-4555-8555-555555555501'::uuid,
  'd4444444-4444-4444-8444-444444444401'::uuid,
  'b2222222-2222-4222-8222-222222222201'::uuid
);

SET ROLE pokecoach_worker;

DO $$
BEGIN
  PERFORM core.reset_demo_dataset();
  RAISE EXCEPTION 'expected external reference conflict';
EXCEPTION
  WHEN SQLSTATE 'PDC01' THEN
    NULL;
END
$$;

RESET ROLE;

SELECT COUNT(*) = 1 FROM core.teams WHERE id = 'd4444444-4444-4444-8444-444444444401'::uuid;

DELETE FROM core.matchups WHERE id = 'e5555555-5555-4555-8555-555555555501'::uuid;
DELETE FROM core.teams WHERE id = 'd4444444-4444-4444-8444-444444444401'::uuid;

SET ROLE pokecoach_worker;

SELECT core.reset_demo_dataset() IS NOT NULL AS reset_after_witness_removed;

DO $$
BEGIN
  DELETE FROM core.teams WHERE id = 'a1111111-1111-4111-8111-111111111101'::uuid;
  RAISE EXCEPTION 'worker delete should fail';
EXCEPTION
  WHEN insufficient_privilege THEN
    NULL;
END
$$;

RESET ROLE;
SET ROLE authenticated_user;

DO $$
BEGIN
  PERFORM core.reset_demo_dataset();
  RAISE EXCEPTION 'authenticated_user must not execute reset';
EXCEPTION
  WHEN insufficient_privilege THEN
    NULL;
END
$$;

RESET ROLE;
