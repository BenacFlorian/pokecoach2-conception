# pokecoach2-conception

Dépôt SQL et environnement local PostgreSQL / Flyway / PostGraphile pour pokecoach2.

## Prérequis

- Docker Engine et Compose v2
- [Devbox](https://www.jetify.com/devbox) (Flyway 11.11.2, client PostgreSQL 17, ShellCheck)

## Configuration locale

```bash
cp deployment/local/.env.example deployment/local/.env
# Renseigner POSTGRES_PASSWORD, API_DB_PASSWORD, WORKER_DB_PASSWORD
```

**Important :** les variables `POSTGRES_*` ne s’appliquent qu’à la **première** initialisation du volume PostgreSQL. Changer `.env` ne renomme pas la base ni ne réinitialise le mot de passe sur un volume existant. Pour une rotation, utiliser `ALTER ROLE` ou recréer le volume explicitement (`docker compose down` puis suppression du volume nommé).

## Commandes

```bash
chmod +x scripts/*.sh tests/runner.sh

# Stack minimale (PostgreSQL + bootstrap + Flyway)
./scripts/compose.sh up -d --build

# Migrations depuis l’hôte (PostgreSQL déjà démarré)
devbox run migrate
devbox run validate

# Tests SQL (base pokecoach2_test)
POSTGRES_DB=pokecoach2_test ./scripts/test-db.sh

# Données démo (idempotent)
./scripts/seed-demo.sh

# Tests du runner Flyway
./tests/runner.sh
```

Host PostgreSQL : `127.0.0.1:5442`, base `pokecoach2`.

**Flyway :** l’image Docker (`flyway/flyway:11.11.2`) est le moteur de référence pour les migrations en CI/local Compose. Devbox installe une version Nix plus récente pour `psql`/scripts hôte ; en cas d’écart, utiliser `./scripts/migrate-local.sh`.

Voir `deployment/local/README.md` pour PostGraphile et le profil Angular.
