-- Generated from tests/fixtures/demo.manifest.json — regenerate via scripts/generate-demo-reset.mjs
-- manifest sha256: 7f12f727f2558783c90ad24a6027cc20dfb6070c686a493ee969b2eeb6ffec2a

CREATE OR REPLACE FUNCTION core.reset_demo_dataset()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $function$
DECLARE
  v_run_id uuid;
  v_existing uuid;
BEGIN
  IF NOT pg_try_advisory_xact_lock(742031, 1) THEN
    RAISE EXCEPTION 'demo reset already in progress' USING ERRCODE = 'PDC02';
  END IF;

  SELECT t.id INTO v_existing
  FROM core.teams t
  WHERE t.id IN ('a1111111-1111-4111-8111-111111111101'::uuid, 'a1111111-1111-4111-8111-111111111102'::uuid, 'b2222222-2222-4222-8222-222222222201'::uuid)
    AND t.name LIKE 'SEED-MISMATCH%'
  LIMIT 1;
  IF v_existing IS NOT NULL THEN
    RAISE EXCEPTION 'seed id conflict with unexpected row %', v_existing;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM core.matchups m
    WHERE m.id <> 'c3333333-3333-4333-8333-333333333301'::uuid
      AND (
        m.our_team_id IN ('a1111111-1111-4111-8111-111111111101'::uuid, 'a1111111-1111-4111-8111-111111111102'::uuid, 'b2222222-2222-4222-8222-222222222201'::uuid)
        OR m.opponent_team_id IN ('a1111111-1111-4111-8111-111111111101'::uuid, 'a1111111-1111-4111-8111-111111111102'::uuid, 'b2222222-2222-4222-8222-222222222201'::uuid)
      )
  ) THEN
    RAISE EXCEPTION 'demo seed team referenced by another matchup' USING ERRCODE = 'PDC01';
  END IF;

  PERFORM 1
  FROM core.teams t
  WHERE t.id IN ('a1111111-1111-4111-8111-111111111101'::uuid, 'a1111111-1111-4111-8111-111111111102'::uuid, 'b2222222-2222-4222-8222-222222222201'::uuid)
  ORDER BY t.id
  FOR UPDATE;

  PERFORM 1
  FROM core.matchups m
  WHERE m.id = 'c3333333-3333-4333-8333-333333333301'::uuid
  FOR UPDATE;

  DELETE FROM core.matchup_runs
  WHERE matchup_id = 'c3333333-3333-4333-8333-333333333301'::uuid;

  DELETE FROM core.matchups
  WHERE id = 'c3333333-3333-4333-8333-333333333301'::uuid;

  DELETE FROM core.teams
  WHERE id IN ('a1111111-1111-4111-8111-111111111101'::uuid, 'a1111111-1111-4111-8111-111111111102'::uuid, 'b2222222-2222-4222-8222-222222222201'::uuid);

INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
VALUES (
  'a1111111-1111-4111-8111-111111111101'::uuid,
  'owned',
  'jit_vgc — Worlds 2026 (Reg MB)',
  'text',
  'https://pokepast.es/e46c2a79dcd8d00c',
  'Excadrill (F) @ Focus Sash
Ability: Sand Rush
Level: 50
EVs: 2 HP / 32 Atk / 32 Spe
Adamant Nature
- High Horsepower
- Rock Slide
- Iron Head
- Protect

Tyranitar (M) @ Tyranitarite
Ability: Sand Stream
Level: 50
EVs: 16 HP / 18 Atk / 32 Spe
Jolly Nature
- Rock Slide
- Protect
- Knock Off
- Low Kick

Sinistcha @ Colbur Berry
Ability: Hospitality
Level: 50
EVs: 29 HP / 15 Def / 22 SpD
Bold Nature
- Rage Powder
- Trick Room
- Matcha Gotcha
- Protect

Staraptor (M) @ Staraptite
Ability: Intimidate
Level: 50
EVs: 21 HP / 11 Atk / 2 SpD / 32 Spe
Jolly Nature
- Brave Bird
- Tailwind
- Protect
- Close Combat

Milotic (M) @ Sitrus Berry
Ability: Competitive
Level: 50
EVs: 30 HP / 21 Def / 2 SpD / 13 Spe
Bold Nature
- Scald
- Icy Wind
- Ice Beam
- Protect

Gholdengo @ Life Orb
Ability: Good as Gold
Level: 50
EVs: 27 HP / 13 Def / 7 SpA / 10 SpD / 9 Spe
Modest Nature
- Make It Rain
- Shadow Ball
- Nasty Plot
- Protect',
  $pokemon$
[{"slot":0,"species":"Excadrill","gender":"F","item":"Focus Sash","ability":"Sand Rush","level":50,"nature":"Adamant","evs":{"HP":2,"Atk":32,"Spe":32},"moves":["High Horsepower","Rock Slide","Iron Head","Protect"],"rawBlock":"Excadrill (F) @ Focus Sash\nAbility: Sand Rush\nLevel: 50\nEVs: 2 HP / 32 Atk / 32 Spe\nAdamant Nature\n- High Horsepower\n- Rock Slide\n- Iron Head\n- Protect"},{"slot":1,"species":"Tyranitar","gender":"M","item":"Tyranitarite","ability":"Sand Stream","level":50,"nature":"Jolly","evs":{"HP":16,"Atk":18,"Spe":32},"moves":["Rock Slide","Protect","Knock Off","Low Kick"],"rawBlock":"Tyranitar (M) @ Tyranitarite\nAbility: Sand Stream\nLevel: 50\nEVs: 16 HP / 18 Atk / 32 Spe\nJolly Nature\n- Rock Slide\n- Protect\n- Knock Off\n- Low Kick"},{"slot":2,"species":"Sinistcha","item":"Colbur Berry","ability":"Hospitality","level":50,"nature":"Bold","evs":{"HP":29,"Def":15,"SpD":22},"moves":["Rage Powder","Trick Room","Matcha Gotcha","Protect"],"rawBlock":"Sinistcha @ Colbur Berry\nAbility: Hospitality\nLevel: 50\nEVs: 29 HP / 15 Def / 22 SpD\nBold Nature\n- Rage Powder\n- Trick Room\n- Matcha Gotcha\n- Protect"},{"slot":3,"species":"Staraptor","gender":"M","item":"Staraptite","ability":"Intimidate","level":50,"nature":"Jolly","evs":{"HP":21,"Atk":11,"SpD":2,"Spe":32},"moves":["Brave Bird","Tailwind","Protect","Close Combat"],"rawBlock":"Staraptor (M) @ Staraptite\nAbility: Intimidate\nLevel: 50\nEVs: 21 HP / 11 Atk / 2 SpD / 32 Spe\nJolly Nature\n- Brave Bird\n- Tailwind\n- Protect\n- Close Combat"},{"slot":4,"species":"Milotic","gender":"M","item":"Sitrus Berry","ability":"Competitive","level":50,"nature":"Bold","evs":{"HP":30,"Def":21,"SpD":2,"Spe":13},"moves":["Scald","Icy Wind","Ice Beam","Protect"],"rawBlock":"Milotic (M) @ Sitrus Berry\nAbility: Competitive\nLevel: 50\nEVs: 30 HP / 21 Def / 2 SpD / 13 Spe\nBold Nature\n- Scald\n- Icy Wind\n- Ice Beam\n- Protect"},{"slot":5,"species":"Gholdengo","item":"Life Orb","ability":"Good as Gold","level":50,"nature":"Modest","evs":{"HP":27,"Def":13,"SpA":7,"SpD":10,"Spe":9},"moves":["Make It Rain","Shadow Ball","Nasty Plot","Protect"],"rawBlock":"Gholdengo @ Life Orb\nAbility: Good as Gold\nLevel: 50\nEVs: 27 HP / 13 Def / 7 SpA / 10 SpD / 9 Spe\nModest Nature\n- Make It Rain\n- Shadow Ball\n- Nasty Plot\n- Protect"}]$pokemon$::jsonb,
  '2026-10-01T10:00:00.000Z'::timestamptz
);

INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
VALUES (
  'a1111111-1111-4111-8111-111111111102'::uuid,
  'owned',
  'Nirinbo — Battle Cruise Top 8',
  'text',
  'https://pokepast.es/a3405a6e98d765aa',
  'Salamence @ Salamencite
Ability: Intimidate
Level: 50
EVs: 2 HP / 32 SpA / 32 Spe
Timid Nature
- Hyper Voice
- Draco Meteor
- Tailwind
- Protect

Kingambit @ Life Orb
Ability: Defiant
Level: 50
EVs: 32 HP / 32 Atk / 2 Spe
Adamant Nature
- Kowtow Cleave
- Sucker Punch
- Swords Dance
- Protect

Glimmora @ Glimmoranite
Ability: Toxic Debris
Level: 50
EVs: 32 SpA / 2 SpD / 32 Spe
Modest Nature
- Power Gem
- Sludge Bomb
- Earth Power
- Spiky Shield

Rillaboom @ Miracle Seed
Ability: Grassy Surge
Level: 50
EVs: 32 HP / 30 Atk / 4 Spe
Adamant Nature
- Superpower
- Grassy Glide
- Wood Hammer
- Fake Out

Volcarona @ Charti Berry
Ability: Flame Body
Level: 50
EVs: 32 HP / 20 Def / 14 Spe
Bold Nature
- Overheat
- Struggle Bug
- Rage Powder
- Protect

Garchomp @ Choice Scarf
Ability: Rough Skin
Level: 50
EVs: 14 HP / 20 Atk / 32 Spe
Adamant Nature
- Earthquake
- Rock Slide
- Stomping Tantrum
- Dragon Claw',
  $pokemon$
[{"slot":0,"species":"Salamence","item":"Salamencite","ability":"Intimidate","level":50,"nature":"Timid","evs":{"HP":2,"SpA":32,"Spe":32},"moves":["Hyper Voice","Draco Meteor","Tailwind","Protect"],"rawBlock":"Salamence @ Salamencite\nAbility: Intimidate\nLevel: 50\nEVs: 2 HP / 32 SpA / 32 Spe\nTimid Nature\n- Hyper Voice\n- Draco Meteor\n- Tailwind\n- Protect"},{"slot":1,"species":"Kingambit","item":"Life Orb","ability":"Defiant","level":50,"nature":"Adamant","evs":{"HP":32,"Atk":32,"Spe":2},"moves":["Kowtow Cleave","Sucker Punch","Swords Dance","Protect"],"rawBlock":"Kingambit @ Life Orb\nAbility: Defiant\nLevel: 50\nEVs: 32 HP / 32 Atk / 2 Spe\nAdamant Nature\n- Kowtow Cleave\n- Sucker Punch\n- Swords Dance\n- Protect"},{"slot":2,"species":"Glimmora","item":"Glimmoranite","ability":"Toxic Debris","level":50,"nature":"Modest","evs":{"SpA":32,"SpD":2,"Spe":32},"moves":["Power Gem","Sludge Bomb","Earth Power","Spiky Shield"],"rawBlock":"Glimmora @ Glimmoranite\nAbility: Toxic Debris\nLevel: 50\nEVs: 32 SpA / 2 SpD / 32 Spe\nModest Nature\n- Power Gem\n- Sludge Bomb\n- Earth Power\n- Spiky Shield"},{"slot":3,"species":"Rillaboom","item":"Miracle Seed","ability":"Grassy Surge","level":50,"nature":"Adamant","evs":{"HP":32,"Atk":30,"Spe":4},"moves":["Superpower","Grassy Glide","Wood Hammer","Fake Out"],"rawBlock":"Rillaboom @ Miracle Seed\nAbility: Grassy Surge\nLevel: 50\nEVs: 32 HP / 30 Atk / 4 Spe\nAdamant Nature\n- Superpower\n- Grassy Glide\n- Wood Hammer\n- Fake Out"},{"slot":4,"species":"Volcarona","item":"Charti Berry","ability":"Flame Body","level":50,"nature":"Bold","evs":{"HP":32,"Def":20,"Spe":14},"moves":["Overheat","Struggle Bug","Rage Powder","Protect"],"rawBlock":"Volcarona @ Charti Berry\nAbility: Flame Body\nLevel: 50\nEVs: 32 HP / 20 Def / 14 Spe\nBold Nature\n- Overheat\n- Struggle Bug\n- Rage Powder\n- Protect"},{"slot":5,"species":"Garchomp","item":"Choice Scarf","ability":"Rough Skin","level":50,"nature":"Adamant","evs":{"HP":14,"Atk":20,"Spe":32},"moves":["Earthquake","Rock Slide","Stomping Tantrum","Dragon Claw"],"rawBlock":"Garchomp @ Choice Scarf\nAbility: Rough Skin\nLevel: 50\nEVs: 14 HP / 20 Atk / 32 Spe\nAdamant Nature\n- Earthquake\n- Rock Slide\n- Stomping Tantrum\n- Dragon Claw"}]$pokemon$::jsonb,
  '2026-10-01T11:00:00.000Z'::timestamptz
);

INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
VALUES (
  'b2222222-2222-4222-8222-222222222201'::uuid,
  'opponent',
  'Nirinbo — Battle Cruise Top 8',
  'text',
  'https://pokepast.es/a3405a6e98d765aa',
  'Salamence @ Salamencite
Ability: Intimidate
Level: 50
EVs: 2 HP / 32 SpA / 32 Spe
Timid Nature
- Hyper Voice
- Draco Meteor
- Tailwind
- Protect

Kingambit @ Life Orb
Ability: Defiant
Level: 50
EVs: 32 HP / 32 Atk / 2 Spe
Adamant Nature
- Kowtow Cleave
- Sucker Punch
- Swords Dance
- Protect

Glimmora @ Glimmoranite
Ability: Toxic Debris
Level: 50
EVs: 32 SpA / 2 SpD / 32 Spe
Modest Nature
- Power Gem
- Sludge Bomb
- Earth Power
- Spiky Shield

Rillaboom @ Miracle Seed
Ability: Grassy Surge
Level: 50
EVs: 32 HP / 30 Atk / 4 Spe
Adamant Nature
- Superpower
- Grassy Glide
- Wood Hammer
- Fake Out

Volcarona @ Charti Berry
Ability: Flame Body
Level: 50
EVs: 32 HP / 20 Def / 14 Spe
Bold Nature
- Overheat
- Struggle Bug
- Rage Powder
- Protect

Garchomp @ Choice Scarf
Ability: Rough Skin
Level: 50
EVs: 14 HP / 20 Atk / 32 Spe
Adamant Nature
- Earthquake
- Rock Slide
- Stomping Tantrum
- Dragon Claw',
  $pokemon$
[{"slot":0,"species":"Salamence","item":"Salamencite","ability":"Intimidate","level":50,"nature":"Timid","evs":{"HP":2,"SpA":32,"Spe":32},"moves":["Hyper Voice","Draco Meteor","Tailwind","Protect"],"rawBlock":"Salamence @ Salamencite\nAbility: Intimidate\nLevel: 50\nEVs: 2 HP / 32 SpA / 32 Spe\nTimid Nature\n- Hyper Voice\n- Draco Meteor\n- Tailwind\n- Protect"},{"slot":1,"species":"Kingambit","item":"Life Orb","ability":"Defiant","level":50,"nature":"Adamant","evs":{"HP":32,"Atk":32,"Spe":2},"moves":["Kowtow Cleave","Sucker Punch","Swords Dance","Protect"],"rawBlock":"Kingambit @ Life Orb\nAbility: Defiant\nLevel: 50\nEVs: 32 HP / 32 Atk / 2 Spe\nAdamant Nature\n- Kowtow Cleave\n- Sucker Punch\n- Swords Dance\n- Protect"},{"slot":2,"species":"Glimmora","item":"Glimmoranite","ability":"Toxic Debris","level":50,"nature":"Modest","evs":{"SpA":32,"SpD":2,"Spe":32},"moves":["Power Gem","Sludge Bomb","Earth Power","Spiky Shield"],"rawBlock":"Glimmora @ Glimmoranite\nAbility: Toxic Debris\nLevel: 50\nEVs: 32 SpA / 2 SpD / 32 Spe\nModest Nature\n- Power Gem\n- Sludge Bomb\n- Earth Power\n- Spiky Shield"},{"slot":3,"species":"Rillaboom","item":"Miracle Seed","ability":"Grassy Surge","level":50,"nature":"Adamant","evs":{"HP":32,"Atk":30,"Spe":4},"moves":["Superpower","Grassy Glide","Wood Hammer","Fake Out"],"rawBlock":"Rillaboom @ Miracle Seed\nAbility: Grassy Surge\nLevel: 50\nEVs: 32 HP / 30 Atk / 4 Spe\nAdamant Nature\n- Superpower\n- Grassy Glide\n- Wood Hammer\n- Fake Out"},{"slot":4,"species":"Volcarona","item":"Charti Berry","ability":"Flame Body","level":50,"nature":"Bold","evs":{"HP":32,"Def":20,"Spe":14},"moves":["Overheat","Struggle Bug","Rage Powder","Protect"],"rawBlock":"Volcarona @ Charti Berry\nAbility: Flame Body\nLevel: 50\nEVs: 32 HP / 20 Def / 14 Spe\nBold Nature\n- Overheat\n- Struggle Bug\n- Rage Powder\n- Protect"},{"slot":5,"species":"Garchomp","item":"Choice Scarf","ability":"Rough Skin","level":50,"nature":"Adamant","evs":{"HP":14,"Atk":20,"Spe":32},"moves":["Earthquake","Rock Slide","Stomping Tantrum","Dragon Claw"],"rawBlock":"Garchomp @ Choice Scarf\nAbility: Rough Skin\nLevel: 50\nEVs: 14 HP / 20 Atk / 32 Spe\nAdamant Nature\n- Earthquake\n- Rock Slide\n- Stomping Tantrum\n- Dragon Claw"}]$pokemon$::jsonb,
  '2026-10-01T10:05:00.000Z'::timestamptz
);

INSERT INTO core.matchups (id, our_team_id, opponent_team_id)
VALUES (
  'c3333333-3333-4333-8333-333333333301'::uuid,
  'a1111111-1111-4111-8111-111111111101'::uuid,
  'b2222222-2222-4222-8222-222222222201'::uuid
);

INSERT INTO core.matchup_runs (matchup_id, source, status, report, finished_at, provenance)
VALUES (
  'c3333333-3333-4333-8333-333333333301'::uuid,
  'mock',
  'succeeded',
  $report$
{"source":"mock","fixtureVersion":1,"phaseASampleSize":1000,"phaseBSampleSize":50,"phaseCSampleSize":50,"phaseDSampleSize":10,"opponentLeads":[{"id":"lead-salamence-kingambit","leadSlots":[0,1],"phaseASampleSize":1000,"phaseACount":420,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Kowtow Cleave","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":0},"switchTo":{"side":"opponent","slot":2}},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Kowtow Cleave","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Draco Meteor","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Sucker Punch","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":1},"switchTo":{"side":"opponent","slot":3}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[2,3],"count":11,"sampleSize":50},{"value":[2,4],"count":9,"sampleSize":50},{"value":[2,5],"count":8,"sampleSize":50},{"value":[3,4],"count":6,"sampleSize":50},{"value":[3,5],"count":5,"sampleSize":50},{"value":[4,5],"count":11,"sampleSize":50}],"backSlotMarginals":[{"value":2,"count":32,"sampleSize":50},{"value":3,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Salamence après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-salamence-glimmora","leadSlots":[0,2],"phaseASampleSize":1000,"phaseACount":270,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":0},"switchTo":{"side":"opponent","slot":1}},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Draco Meteor","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Sludge Bomb","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":2},"switchTo":{"side":"opponent","slot":3}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[1,3],"count":10,"sampleSize":50},{"value":[1,4],"count":8,"sampleSize":50},{"value":[1,5],"count":6,"sampleSize":50},{"value":[3,4],"count":5,"sampleSize":50},{"value":[3,5],"count":11,"sampleSize":50},{"value":[4,5],"count":10,"sampleSize":50}],"backSlotMarginals":[{"value":1,"count":32,"sampleSize":50},{"value":3,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Salamence après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-glimmora-rillaboom","leadSlots":[2,3],"phaseASampleSize":1000,"phaseACount":180,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Superpower","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":2},"switchTo":{"side":"opponent","slot":0}},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Superpower","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Sludge Bomb","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Grassy Glide","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":3},"switchTo":{"side":"opponent","slot":1}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[0,1],"count":8,"sampleSize":50},{"value":[0,4],"count":7,"sampleSize":50},{"value":[0,5],"count":5,"sampleSize":50},{"value":[1,4],"count":12,"sampleSize":50},{"value":[1,5],"count":10,"sampleSize":50},{"value":[4,5],"count":8,"sampleSize":50}],"backSlotMarginals":[{"value":0,"count":32,"sampleSize":50},{"value":1,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Glimmora après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-volcarona-garchomp","leadSlots":[4,5],"phaseASampleSize":1000,"phaseACount":130,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Overheat","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Earthquake","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":4},"switchTo":{"side":"opponent","slot":0}},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Earthquake","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Struggle Bug","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Rock Slide","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Overheat","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":5},"switchTo":{"side":"opponent","slot":1}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[0,1],"count":7,"sampleSize":50},{"value":[0,2],"count":5,"sampleSize":50},{"value":[0,3],"count":12,"sampleSize":50},{"value":[1,2],"count":10,"sampleSize":50},{"value":[1,3],"count":9,"sampleSize":50},{"value":[2,3],"count":7,"sampleSize":50}],"backSlotMarginals":[{"value":0,"count":32,"sampleSize":50},{"value":1,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Volcarona après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]}],"selectionComparisons":[{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50}],"leadRecommendation":{"ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"justification":"Lead Excadrill/Sinistcha recommandé sur l’échantillon fictif (56 % de victoires).","selectionResults":[{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50}],"studiedLeads":[{"opponentLeadId":"lead-salamence-kingambit","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"High Horsepower","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":0}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Rage Powder","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":1}}]}],"alternatives":["Pivoter Excadrill après Hyper Voice adverse.","Conserver Sinistcha si Kowtow Cleave vise un allié."],"adaptations":["Anticiper Hyper Voice + Kowtow Cleave avec spread depuis Staraptor."]},{"opponentLeadId":"lead-salamence-glimmora","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"High Horsepower","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":0}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Rage Powder","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":2}}]}],"alternatives":["Pivoter Excadrill après Hyper Voice adverse.","Conserver Sinistcha si Power Gem vise un allié."],"adaptations":["Anticiper Hyper Voice + Power Gem avec spread depuis Staraptor."]},{"opponentLeadId":"lead-glimmora-rillaboom","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"High Horsepower","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":2}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Rage Powder","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":3}}]}],"alternatives":["Pivoter Excadrill après Power Gem adverse.","Conserver Sinistcha si Superpower vise un allié."],"adaptations":["Anticiper Power Gem + Superpower avec spread depuis Staraptor."]}]},"gameplan":{"opening":"Ouvrir avec Excadrill et Sinistcha pour absorber la pression de Salamence.","midgame":"Utiliser Staraptor pour contrôler le tempo une fois les leads adverses identifiés.","endgame":"Clôturer avec Gholdengo si Volcarona est encore en jeu.","threats":[{"label":"Kingambit","detail":"Menace principale si libre au tour 2 (données fictives)."},{"label":"Glimmora","detail":"À surveiller après Téracristallisation (fixture)."}],"preserve":["Excadrill","Staraptor"],"eliminate":["Kingambit","Glimmora"],"adaptations":["Basculer Milotic si Rillaboom impose Tailwind."],"winCondition":"Empêcher Kingambit de sweep après la phase midgame ; conserver Excadrill pour le clutch.","refinementSequences":[{"label":"Séquence D-1","detail":"Sinistcha reste en lead si Salamence part en back (10 parties fictives)."},{"label":"Séquence D-2","detail":"Tera Excadrill utilisé contre Glimmora dans 6/10 affinages simulés."}],"sampleLimitation":"Échantillon de démonstration : les fréquences illustrent un futur modèle, pas le meta réel."}}$report$::jsonb,
  '2026-10-01T10:30:00.000Z'::timestamptz,
  $provenance$
{"fixtureVersion":1}$provenance$::jsonb
)
RETURNING id INTO v_run_id;

RETURN jsonb_build_object(
  'source', 'mock',
  'fixtureVersion', 1,
  'ownedTeamIds', jsonb_build_array('a1111111-1111-4111-8111-111111111101', 'a1111111-1111-4111-8111-111111111102'),
  'opponentTeamId', 'b2222222-2222-4222-8222-222222222201',
  'matchupId', 'c3333333-3333-4333-8333-333333333301',
  'runId', v_run_id::text,
  'counts', jsonb_build_object('teams', 3, 'matchups', 1, 'runs', 1)
);
END;
$function$;

ALTER FUNCTION core.reset_demo_dataset() OWNER TO pokecoach_admin;

REVOKE ALL ON FUNCTION core.reset_demo_dataset() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION core.reset_demo_dataset() TO pokecoach_worker;

COMMENT ON FUNCTION core.reset_demo_dataset() IS E'@omit';
