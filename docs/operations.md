# Operations — pokecoach2-conception

## Cold start

1. Copier `deployment/local/.env.example` → `.env` et définir `POSTGRES_PASSWORD`, `API_DB_PASSWORD`, `WORKER_DB_PASSWORD`.
2. `./scripts/compose.sh up -d --build`
3. `./scripts/check-stack.sh`

## Évolution SQL

1. Arrêter les consommateurs : `./scripts/compose.sh stop postgraphile`
2. Reconstruire Flyway : `./scripts/compose.sh build flyway`
3. `./scripts/migrate-local.sh` (vérifie le code de sortie)
4. `./scripts/compose.sh up -d postgraphile`

Pas de `repair`, `clean`, ni `down -v` automatique.

## Sauvegarde

`devbox run dump-schema` → `dumps/core-schema-YYYYMMDD.sql`

## Python

Extension documentée dans `deployment/local/compose.python.yml`. Test d’intégration réel : **non exécuté — application Python à créer**.

Quand une image existe : health `/health`, rôle `pokecoach_worker`, refus DDL.

## Versions vérifiées (à mettre à jour après smoke test)

| Composant | Référence |
| --- | --- |
| PostgreSQL | `postgres:17.4-bookworm` |
| Flyway | `flyway/flyway:11.11.2` |
| PostGraphile | image build `pokecoach2-postgraphile/` (`postgraphile@4.14.1`) |
| Node (images) | `22.23.3-bookworm` |
