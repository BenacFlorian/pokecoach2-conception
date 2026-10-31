import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const manifestPath = resolve(root, 'tests/fixtures/demo.manifest.json');
const generatedSqlPath = resolve(root, 'tests/fixtures/demo.generated.sql');
const angularDir = resolve(root, '../pokecoach2-angular/pokecoach-angular');

test('demo manifest has reserved UUIDs and structure', () => {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  assert.equal(manifest.fixtureVersion, 1);
  assert.equal(manifest.teams.length, 3);
  assert.equal(manifest.teams.filter((t) => t.kind === 'owned').length, 2);
  assert.equal(manifest.teams.filter((t) => t.kind === 'opponent').length, 1);
  for (const team of manifest.teams) {
    assert.equal(team.pokemon.length, 6);
  }
  assert.equal(manifest.matchup.id, 'c3333333-3333-4333-8333-333333333301');
  assert.equal(manifest.run.source, 'mock');
  assert.ok(manifest.run.report);
});

test('generate:demo-seed:check passes', () => {
  const result = spawnSync('npm', ['run', 'generate:demo-seed:check'], {
    cwd: angularDir,
    encoding: 'utf8',
  });
  assert.equal(
    result.status,
    0,
    result.stderr || result.stdout || 'generate:demo-seed:check failed',
  );
  assert.ok(readFileSync(generatedSqlPath, 'utf8').includes('core.teams'));
});
