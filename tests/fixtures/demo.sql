-- Demo seed — idempotent, does not overwrite differing rows.
-- Demo id mapping: docs/data-contract.md

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

WITH slots AS (
  SELECT jsonb_agg(
    jsonb_build_object(
      'slot', gs,
      'species',
      CASE gs
        WHEN 0 THEN 'Farigiraf'
        WHEN 1 THEN 'Camerupt'
        WHEN 2 THEN 'Sylveon'
        WHEN 3 THEN 'Raichu'
        WHEN 4 THEN 'Incineroar'
        ELSE 'Rillaboom'
      END,
      'nickname', NULL,
      'item', 'Sitrus Berry',
      'ability', 'Armor Tail',
      'level', 50,
      'moves', jsonb_build_array('Protect', 'Psychic'),
      'rawBlock', 'demo block'
    ) ORDER BY gs
  ) AS pokemon
  FROM generate_series(0, 5) AS gs
)
INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
SELECT
  'a1111111-1111-4111-8111-111111111101'::uuid,
  'owned',
  'Chompy — VR Top 4 (Reg MC)',
  'url',
  'https://pokepast.es/9d3c3ee9e145f6b8',
  'demo our paste',
  slots.pokemon,
  '2026-10-01T10:00:00Z'::timestamptz
FROM slots
ON CONFLICT (id) DO NOTHING;

WITH slots AS (
  SELECT jsonb_agg(
    jsonb_build_object(
      'slot', gs,
      'species', 'Salamence',
      'moves', jsonb_build_array('Protect', 'Tailwind'),
      'rawBlock', 'demo opp'
    ) ORDER BY gs
  ) AS pokemon
  FROM generate_series(0, 5) AS gs
)
INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
SELECT
  'a1111111-1111-4111-8111-111111111102'::uuid,
  'owned',
  'Nirinbo — Battle Cruise Top 8',
  'url',
  'https://pokepast.es/a3405a6e98d765aa',
  'demo paste 2',
  slots.pokemon,
  '2026-10-01T11:00:00Z'::timestamptz
FROM slots
ON CONFLICT (id) DO NOTHING;

WITH slots AS (
  SELECT jsonb_agg(
    jsonb_build_object(
      'slot', gs,
      'species', 'Salamence',
      'moves', jsonb_build_array('Protect', 'Tailwind'),
      'rawBlock', 'demo opp'
    ) ORDER BY gs
  ) AS pokemon
  FROM generate_series(0, 5) AS gs
)
INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
SELECT
  'b2222222-2222-4222-8222-222222222201'::uuid,
  'opponent',
  'Nirinbo — Battle Cruise Top 8',
  'url',
  'https://pokepast.es/a3405a6e98d765aa',
  'demo opponent paste',
  slots.pokemon,
  '2026-10-01T10:05:00Z'::timestamptz
FROM slots
ON CONFLICT (id) DO NOTHING;

INSERT INTO core.matchups (id, our_team_id, opponent_team_id)
VALUES (
  'c3333333-3333-4333-8333-333333333301'::uuid,
  'a1111111-1111-4111-8111-111111111101'::uuid,
  'b2222222-2222-4222-8222-222222222201'::uuid
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO core.matchup_runs (matchup_id, source, status, report, finished_at, provenance)
SELECT
  'c3333333-3333-4333-8333-333333333301'::uuid,
  'mock',
  'succeeded',
  '{"source":"mock","fixtureVersion":1,"phaseASampleSize":1000,"phaseBSampleSize":50,"phaseCSampleSize":50,"phaseDSampleSize":10,"opponentLeads":[],"selectionComparisons":[],"leadRecommendation":{"ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"justification":"demo","selectionResults":[],"studiedLeads":[]},"gameplan":{"opening":"o","midgame":"m","endgame":"e","threats":[],"preserve":[],"eliminate":[],"adaptations":[],"winCondition":"win","refinementSequences":[],"sampleLimitation":"mock"}}'::jsonb,
  now(),
  '{"fixtureVersion":1}'::jsonb
WHERE NOT EXISTS (
  SELECT 1
  FROM core.matchup_runs r
  WHERE r.matchup_id = 'c3333333-3333-4333-8333-333333333301'::uuid
    AND r.status = 'succeeded'
);

COMMIT;
