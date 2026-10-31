#!/usr/bin/env node
/**
 * Génère le corps de core.reset_demo_dataset() à partir de demo.manifest.json.
 * Usage: node scripts/generate-demo-reset.mjs <manifest.json> <output.sql>
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';

function usage() {
  console.error('Usage: generate-demo-reset.mjs <manifest.json> <output.sql>');
  process.exit(2);
}

const manifestPath = process.argv[2];
const outputPath = process.argv[3];
if (!manifestPath || !outputPath) {
  usage();
}
if (existsSync(outputPath)) {
  console.error(`Refusing to overwrite existing file: ${outputPath}`);
  process.exit(1);
}

function sqlString(value) {
  return `'${String(value).replace(/'/g, "''")}'`;
}

function dollarTag(content, prefix) {
  let tag = prefix;
  let suffix = 0;
  while (content.includes(`$${tag}$`)) {
    suffix += 1;
    tag = `${prefix}_${suffix}`;
  }
  return `$${tag}$\n${content}$${tag}$`;
}

function teamInsert(team) {
  const pokemonJson = JSON.stringify(team.pokemon);
  return `
INSERT INTO core.teams (id, kind, name, source_kind, source_url, source_text, pokemon, created_at)
VALUES (
  '${team.id}'::uuid,
  '${team.kind}',
  ${sqlString(team.name)},
  '${team.sourceKind}',
  ${team.sourceUrl ? sqlString(team.sourceUrl) : 'NULL'},
  ${sqlString(team.sourceText)},
  ${dollarTag(pokemonJson, 'pokemon')}::jsonb,
  ${sqlString(team.createdAt)}::timestamptz
);`;
}

const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const teamIds = manifest.teams.map((t) => t.id);
const ownedIds = manifest.teams.filter((t) => t.kind === 'owned').map((t) => t.id);
const teamIdList = teamIds.map((id) => `'${id}'::uuid`).join(', ');
const reportJson = JSON.stringify(manifest.run.report);
const provenanceJson = JSON.stringify(manifest.run.provenance);

const body = `
DECLARE
  v_run_id uuid;
  v_existing uuid;
BEGIN
  IF NOT pg_try_advisory_xact_lock(742031, 1) THEN
    RAISE EXCEPTION 'demo reset already in progress' USING ERRCODE = 'PDC02';
  END IF;

  SELECT t.id INTO v_existing
  FROM core.teams t
  WHERE t.id IN (${teamIdList})
    AND t.name LIKE 'SEED-MISMATCH%'
  LIMIT 1;
  IF v_existing IS NOT NULL THEN
    RAISE EXCEPTION 'seed id conflict with unexpected row %', v_existing;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM core.matchups m
    WHERE m.id <> '${manifest.matchup.id}'::uuid
      AND (
        m.our_team_id IN (${teamIdList})
        OR m.opponent_team_id IN (${teamIdList})
      )
  ) THEN
    RAISE EXCEPTION 'demo seed team referenced by another matchup' USING ERRCODE = 'PDC01';
  END IF;

  PERFORM 1
  FROM core.teams t
  WHERE t.id IN (${teamIdList})
  ORDER BY t.id
  FOR UPDATE;

  PERFORM 1
  FROM core.matchups m
  WHERE m.id = '${manifest.matchup.id}'::uuid
  FOR UPDATE;

  DELETE FROM core.matchup_runs
  WHERE matchup_id = '${manifest.matchup.id}'::uuid;

  DELETE FROM core.matchups
  WHERE id = '${manifest.matchup.id}'::uuid;

  DELETE FROM core.teams
  WHERE id IN (${teamIdList});
${manifest.teams.map((team) => teamInsert(team)).join('\n')}

INSERT INTO core.matchups (id, our_team_id, opponent_team_id)
VALUES (
  '${manifest.matchup.id}'::uuid,
  '${manifest.matchup.ourTeamId}'::uuid,
  '${manifest.matchup.opponentTeamId}'::uuid
);

INSERT INTO core.matchup_runs (matchup_id, source, status, report, finished_at, provenance)
VALUES (
  '${manifest.matchup.id}'::uuid,
  '${manifest.run.source}',
  '${manifest.run.status}',
  ${dollarTag(reportJson, 'report')}::jsonb,
  '${manifest.run.finishedAt}'::timestamptz,
  ${dollarTag(provenanceJson, 'provenance')}::jsonb
)
RETURNING id INTO v_run_id;

RETURN jsonb_build_object(
  'source', '${manifest.run.source}',
  'fixtureVersion', ${manifest.fixtureVersion},
  'ownedTeamIds', jsonb_build_array(${ownedIds.map((id) => `'${id}'`).join(', ')}),
  'opponentTeamId', '${manifest.teams.find((t) => t.kind === 'opponent').id}',
  'matchupId', '${manifest.matchup.id}',
  'runId', v_run_id::text,
  'counts', jsonb_build_object('teams', ${manifest.teams.length}, 'matchups', 1, 'runs', 1)
);
END;
`.trim();

const migration = `-- Generated from tests/fixtures/demo.manifest.json — regenerate via scripts/generate-demo-reset.mjs
-- manifest sha256: ${createHash('sha256').update(readFileSync(manifestPath)).digest('hex')}

CREATE OR REPLACE FUNCTION core.reset_demo_dataset()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $function$
${body}
$function$;

ALTER FUNCTION core.reset_demo_dataset() OWNER TO pokecoach_admin;

REVOKE ALL ON FUNCTION core.reset_demo_dataset() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION core.reset_demo_dataset() TO pokecoach_worker;

COMMENT ON FUNCTION core.reset_demo_dataset() IS E'@omit';
`;

function escapeFlywayDollarBraces(sql) {
  return sql.replace(/\$\{/g, '$${');
}

writeFileSync(outputPath, escapeFlywayDollarBraces(migration), 'utf8');
console.log(`Wrote ${outputPath}`);
