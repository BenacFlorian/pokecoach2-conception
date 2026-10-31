# Environnement local Docker — pokecoach2

## Démarrage

```bash
cp .env.example .env   # mots de passe locaux obligatoires
../../scripts/compose.sh up -d --build
```

Services par défaut : PostgreSQL (`127.0.0.1:5442`), bootstrap, Flyway, PostGraphile (`127.0.0.1:4042/graphql`) construit depuis le dépôt voisin **`pokecoach2-postgraphile/`** (`POSTGRAPHILE_BUILD_CONTEXT`).

Profil frontend (Angular statique, **données mock / localStorage distinct du ng serve**) :

```bash
../../scripts/compose.sh --profile frontend up -d --build
# http://127.0.0.1:8082
```

## Migrations

Après ajout d’un fichier `V*.sql`, reconstruire Flyway et relancer le job :

```bash
../../scripts/migrate-local.sh
../../scripts/compose.sh up -d postgraphile
```

Ne pas modifier une migration déjà appliquée ; ajouter un nouveau fichier de version.

## Python (extension)

Fichier séparé `compose.python.yml`. Sans image applicative réelle, la stack de base démarre sans Python.

```bash
cp .env.python.example .env.python
../../scripts/compose-python.sh config --quiet   # validation syntaxique avec image de test
```

## Vérifications

```bash
../../scripts/check-stack.sh
../../scripts/seed-demo.sh
devbox run validate
```

Volume persistant : `pokecoach2-local_pokecoach2_pgdata`. `compose down` sans `-v` conserve les données.
