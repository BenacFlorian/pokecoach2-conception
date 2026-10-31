-- Demo seed — aligné sur les fixtures Angular (ex-localStorage pokecoach.demo.v1).
-- UUID : docs/data-contract.md
-- Données INSERT : demo.generated.sql (npm run generate:demo-seed dans pokecoach-angular)

BEGIN;

CREATE TEMP TABLE IF NOT EXISTS seed_expected (id uuid PRIMARY KEY) ON COMMIT DROP;

INSERT INTO seed_expected (id) VALUES
  ('a1111111-1111-4111-8111-111111111101'::uuid),
  ('a1111111-1111-4111-8111-111111111102'::uuid),
  ('b2222222-2222-4222-8222-222222222201'::uuid),
  ('c3333333-3333-4333-8333-333333333301'::uuid);

DO $$
DECLARE
  existing uuid;
BEGIN
  SELECT t.id INTO existing
  FROM core.teams t
  INNER JOIN seed_expected s ON s.id = t.id
  WHERE t.name LIKE 'SEED-MISMATCH%';
  IF existing IS NOT NULL THEN
    RAISE EXCEPTION 'seed id conflict with unexpected row %', existing;
  END IF;
END
$$;

DELETE FROM core.matchup_runs
WHERE matchup_id = 'c3333333-3333-4333-8333-333333333301'::uuid;

DELETE FROM core.matchups
WHERE id = 'c3333333-3333-4333-8333-333333333301'::uuid;

DELETE FROM core.teams
WHERE id IN (SELECT id FROM seed_expected);

\ir demo.generated.sql

COMMIT;
