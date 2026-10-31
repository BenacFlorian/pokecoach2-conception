-- Generated from tests/fixtures/demo.manifest.json — regenerate via scripts/generate-demo-reset.mjs
-- manifest sha256: b0cc31ea53ed769a2739193abc7bcbeb39b7ec4378ae268c97ee3994e9e5b5eb

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
  'Chompy — VR Top 4 (Reg MC)',
  'text',
  'https://pokepast.es/9d3c3ee9e145f6b8',
  'Farigiraf @ Sitrus Berry
Ability: Armor Tail
Level: 50
EVs: 29 HP / 22 Def / 15 SpD
Calm Nature
- Protect
- Psychic
- Trick Room
- Helping Hand

Camerupt @ Cameruptite
Ability: Solid Rock
Level: 50
EVs: 32 HP / 2 Def / 32 SpA
Quiet Nature
- Protect
- Heat Wave
- Ancient Power
- Earth Power

Sylveon @ Fairy Feather
Ability: Pixilate
Level: 50
EVs: 31 HP / 13 Def / 21 SpA / 1 SpD
Modest Nature
- Protect
- Moonblast
- Hyper Voice
- Calm Mind

Raichu @ Raichunite Y
Ability: Lightning Rod
Level: 50
EVs: 30 HP / 12 Def / 24 Spe
Timid Nature
- Protect
- Fake Out
- Zap Cannon
- Focus Blast

Incineroar @ Charcoal
Ability: Intimidate
Level: 50
EVs: 32 HP / 32 Atk / 2 SpD
Brave Nature
- Fake Out
- Parting Shot
- Flare Blitz
- Darkest Lariat

Rillaboom @ Life Orb
Ability: Grassy Surge
Level: 50
EVs: 32 HP / 27 Atk / 6 SpD / 1 Spe
Adamant Nature
- Grassy Glide
- Fake Out
- Wood Hammer
- U-turn',
  $pokemon$
[{"slot":0,"species":"Farigiraf","item":"Sitrus Berry","ability":"Armor Tail","level":50,"nature":"Calm","evs":{"HP":29,"Def":22,"SpD":15},"moves":["Protect","Psychic","Trick Room","Helping Hand"],"rawBlock":"Farigiraf @ Sitrus Berry\nAbility: Armor Tail\nLevel: 50\nEVs: 29 HP / 22 Def / 15 SpD\nCalm Nature\n- Protect\n- Psychic\n- Trick Room\n- Helping Hand"},{"slot":1,"species":"Camerupt","item":"Cameruptite","ability":"Solid Rock","level":50,"nature":"Quiet","evs":{"HP":32,"Def":2,"SpA":32},"moves":["Protect","Heat Wave","Ancient Power","Earth Power"],"rawBlock":"Camerupt @ Cameruptite\nAbility: Solid Rock\nLevel: 50\nEVs: 32 HP / 2 Def / 32 SpA\nQuiet Nature\n- Protect\n- Heat Wave\n- Ancient Power\n- Earth Power"},{"slot":2,"species":"Sylveon","item":"Fairy Feather","ability":"Pixilate","level":50,"nature":"Modest","evs":{"HP":31,"Def":13,"SpA":21,"SpD":1},"moves":["Protect","Moonblast","Hyper Voice","Calm Mind"],"rawBlock":"Sylveon @ Fairy Feather\nAbility: Pixilate\nLevel: 50\nEVs: 31 HP / 13 Def / 21 SpA / 1 SpD\nModest Nature\n- Protect\n- Moonblast\n- Hyper Voice\n- Calm Mind"},{"slot":3,"species":"Raichu","item":"Raichunite Y","ability":"Lightning Rod","level":50,"nature":"Timid","evs":{"HP":30,"Def":12,"Spe":24},"moves":["Protect","Fake Out","Zap Cannon","Focus Blast"],"rawBlock":"Raichu @ Raichunite Y\nAbility: Lightning Rod\nLevel: 50\nEVs: 30 HP / 12 Def / 24 Spe\nTimid Nature\n- Protect\n- Fake Out\n- Zap Cannon\n- Focus Blast"},{"slot":4,"species":"Incineroar","item":"Charcoal","ability":"Intimidate","level":50,"nature":"Brave","evs":{"HP":32,"Atk":32,"SpD":2},"moves":["Fake Out","Parting Shot","Flare Blitz","Darkest Lariat"],"rawBlock":"Incineroar @ Charcoal\nAbility: Intimidate\nLevel: 50\nEVs: 32 HP / 32 Atk / 2 SpD\nBrave Nature\n- Fake Out\n- Parting Shot\n- Flare Blitz\n- Darkest Lariat"},{"slot":5,"species":"Rillaboom","item":"Life Orb","ability":"Grassy Surge","level":50,"nature":"Adamant","evs":{"HP":32,"Atk":27,"SpD":6,"Spe":1},"moves":["Grassy Glide","Fake Out","Wood Hammer","U-turn"],"rawBlock":"Rillaboom @ Life Orb\nAbility: Grassy Surge\nLevel: 50\nEVs: 32 HP / 27 Atk / 6 SpD / 1 Spe\nAdamant Nature\n- Grassy Glide\n- Fake Out\n- Wood Hammer\n- U-turn"}]$pokemon$::jsonb,
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
{"source":"mock","fixtureVersion":1,"phaseASampleSize":1000,"phaseBSampleSize":50,"phaseCSampleSize":50,"phaseDSampleSize":10,"opponentLeads":[{"id":"lead-salamence-kingambit","leadSlots":[0,1],"phaseASampleSize":1000,"phaseACount":420,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Kowtow Cleave","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":0},"switchTo":{"side":"opponent","slot":2}},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Kowtow Cleave","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Draco Meteor","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":1},"move":"Sucker Punch","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":1},"switchTo":{"side":"opponent","slot":3}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[2,3],"count":11,"sampleSize":50},{"value":[2,4],"count":9,"sampleSize":50},{"value":[2,5],"count":8,"sampleSize":50},{"value":[3,4],"count":6,"sampleSize":50},{"value":[3,5],"count":5,"sampleSize":50},{"value":[4,5],"count":11,"sampleSize":50}],"backSlotMarginals":[{"value":2,"count":32,"sampleSize":50},{"value":3,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Salamence après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-salamence-glimmora","leadSlots":[0,2],"phaseASampleSize":1000,"phaseACount":270,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":0},"switchTo":{"side":"opponent","slot":1}},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Draco Meteor","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Sludge Bomb","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":0},"move":"Hyper Voice","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":2},"switchTo":{"side":"opponent","slot":3}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[1,3],"count":10,"sampleSize":50},{"value":[1,4],"count":8,"sampleSize":50},{"value":[1,5],"count":6,"sampleSize":50},{"value":[3,4],"count":5,"sampleSize":50},{"value":[3,5],"count":11,"sampleSize":50},{"value":[4,5],"count":10,"sampleSize":50}],"backSlotMarginals":[{"value":1,"count":32,"sampleSize":50},{"value":3,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Salamence après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-glimmora-rillaboom","leadSlots":[2,3],"phaseASampleSize":1000,"phaseACount":180,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Superpower","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":2},"switchTo":{"side":"opponent","slot":0}},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Superpower","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Sludge Bomb","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":3},"move":"Grassy Glide","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":2},"move":"Power Gem","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":3},"switchTo":{"side":"opponent","slot":1}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[0,1],"count":8,"sampleSize":50},{"value":[0,4],"count":7,"sampleSize":50},{"value":[0,5],"count":5,"sampleSize":50},{"value":[1,4],"count":12,"sampleSize":50},{"value":[1,5],"count":10,"sampleSize":50},{"value":[4,5],"count":8,"sampleSize":50}],"backSlotMarginals":[{"value":0,"count":32,"sampleSize":50},{"value":1,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Glimmora après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]},{"id":"lead-volcarona-garchomp","leadSlots":[4,5],"phaseASampleSize":1000,"phaseACount":130,"jointTurn1Actions":[{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Overheat","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Earthquake","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":2}}]}],"count":22,"sampleSize":50},{"value":[{"kind":"switch","actor":{"side":"opponent","slot":4},"switchTo":{"side":"opponent","slot":0}},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Earthquake","targets":[{"kind":"zone","zone":"all-opponents"}]}],"count":14,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Struggle Bug","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":1}}]},{"kind":"move","actor":{"side":"opponent","slot":5},"move":"Rock Slide","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":3}}]}],"count":9,"sampleSize":50},{"value":[{"kind":"move","actor":{"side":"opponent","slot":4},"move":"Overheat","targets":[{"kind":"pokemon","ref":{"side":"ours","slot":0}}]},{"kind":"switch","actor":{"side":"opponent","slot":5},"switchTo":{"side":"opponent","slot":1}}],"count":5,"sampleSize":50}],"backPairs":[{"value":[0,1],"count":7,"sampleSize":50},{"value":[0,2],"count":5,"sampleSize":50},{"value":[0,3],"count":12,"sampleSize":50},{"value":[1,2],"count":10,"sampleSize":50},{"value":[1,3],"count":9,"sampleSize":50},{"value":[2,3],"count":7,"sampleSize":50}],"backSlotMarginals":[{"value":0,"count":32,"sampleSize":50},{"value":1,"count":30,"sampleSize":50}],"turn1EndObservations":["Pression sur Volcarona après le tour 1 (fixture).","Répartition des backs conditionnelle à ce lead (données fictives)."]}],"selectionComparisons":[{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50}],"leadRecommendation":{"ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"justification":"Lead Farigiraf/Sylveon recommandé sur l’échantillon fictif (56 % de victoires).","selectionResults":[{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-kingambit","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-salamence-glimmora","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,2,3,5],"ourLeadSlots":[0,2],"wins":28,"losses":18,"draws":4,"sampleSize":50},{"opponentLeadId":"lead-glimmora-rillaboom","ourFourSlots":[0,1,4,5],"ourLeadSlots":[0,1],"wins":22,"losses":24,"draws":4,"sampleSize":50}],"studiedLeads":[{"opponentLeadId":"lead-salamence-kingambit","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":0}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":1}}]}],"alternatives":["Pivoter Farigiraf après Hyper Voice adverse.","Conserver Sylveon si Kowtow Cleave vise un allié."],"adaptations":["Anticiper Hyper Voice + Kowtow Cleave avec spread depuis Raichu."]},{"opponentLeadId":"lead-salamence-glimmora","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":0}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":2}}]}],"alternatives":["Pivoter Farigiraf après Hyper Voice adverse.","Conserver Sylveon si Power Gem vise un allié."],"adaptations":["Anticiper Hyper Voice + Power Gem avec spread depuis Raichu."]},{"opponentLeadId":"lead-glimmora-rillaboom","primaryActions":[{"kind":"move","actor":{"side":"ours","slot":0},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":2}}]},{"kind":"move","actor":{"side":"ours","slot":2},"move":"Protect","targets":[{"kind":"pokemon","ref":{"side":"opponent","slot":3}}]}],"alternatives":["Pivoter Farigiraf après Power Gem adverse.","Conserver Sylveon si Superpower vise un allié."],"adaptations":["Anticiper Power Gem + Superpower avec spread depuis Raichu."]}]},"gameplan":{"opening":"Ouvrir avec Farigiraf et Sylveon pour absorber la pression de Salamence.","midgame":"Utiliser Raichu pour contrôler le tempo une fois les leads adverses identifiés.","endgame":"Clôturer avec Rillaboom si Volcarona est encore en jeu.","threats":[{"label":"Kingambit","detail":"Menace principale si libre au tour 2 (données fictives)."},{"label":"Glimmora","detail":"À surveiller après Téracristallisation (fixture)."}],"preserve":["Farigiraf","Raichu"],"eliminate":["Kingambit","Glimmora"],"adaptations":["Basculer Incineroar si Rillaboom impose Tailwind."],"winCondition":"Empêcher Kingambit de sweep après la phase midgame ; conserver Farigiraf pour le clutch.","refinementSequences":[{"label":"Séquence D-1","detail":"Sylveon reste en lead si Salamence part en back (10 parties fictives)."},{"label":"Séquence D-2","detail":"Tera Farigiraf utilisé contre Glimmora dans 6/10 affinages simulés."}],"sampleLimitation":"Échantillon de démonstration : les fréquences illustrent un futur modèle, pas le meta réel."}}$report$::jsonb,
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
