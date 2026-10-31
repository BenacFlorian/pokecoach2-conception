-- Teams validation (negative cases use savepoints).
DO $$
DECLARE
  bad jsonb;
BEGIN
  bad := 'null'::jsonb;
  IF core.is_valid_pokemon_sets(bad) IS NOT FALSE THEN
    RAISE EXCEPTION 'expected null json to be invalid';
  END IF;
END
$$;

DO $$
DECLARE
  sets jsonb;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'slot', gs,
      'species', 'Farigiraf',
      'moves', jsonb_build_array('Protect'),
      'rawBlock', 'block'
    ) ORDER BY gs
  )
  INTO sets
  FROM generate_series(0, 5) AS gs;
  IF core.is_valid_pokemon_sets(sets) IS NOT TRUE THEN
    RAISE EXCEPTION 'expected valid six-slot sets';
  END IF;
END
$$;

BEGIN;
INSERT INTO core.teams (kind, name, source_kind, source_url, source_text, pokemon)
SELECT
  'owned',
  'Test team',
  'url',
  'https://pokepast.es/test',
  'paste body',
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'slot', gs,
        'species', 'Farigiraf',
        'moves', jsonb_build_array('Protect'),
        'rawBlock', 'block'
      ) ORDER BY gs
    )
    FROM generate_series(0, 5) AS gs
  );
ROLLBACK;

BEGIN;
SAVEPOINT reject_five;
DO $$
BEGIN
  INSERT INTO core.teams (kind, name, source_kind, source_text, pokemon)
  VALUES (
    'owned',
    'Bad',
    'text',
    'x',
    '[]'::jsonb
  );
  RAISE EXCEPTION 'five-slot insert should have failed';
EXCEPTION
  WHEN check_violation THEN
    NULL;
END
$$;
ROLLBACK TO SAVEPOINT reject_five;
COMMIT;
