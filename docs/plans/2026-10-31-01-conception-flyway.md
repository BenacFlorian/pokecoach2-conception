# Plan 1 — Socle pokecoach2-conception et migrations Flyway

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Créer un dépôt de conception capable d’initialiser et faire évoluer PostgreSQL comme PerfAO.

**Architecture:** Un module correspond à un schéma PostgreSQL ; Flyway conserve son historique dans ce schéma. Un runner commun alimente l’image de migration et les scripts locaux. Un Compose minimal PostgreSQL + bootstrap des rôles + Flyway permet de vérifier ce jalon indépendamment des applications.

**Tech Stack:** PostgreSQL 17, Flyway 11.11.2, Bash, Docker Compose v2, Devbox.

**Spec:** [Cadrage et audit](./README.md), [règles du workspace](../../../agent.md). La demande actuelle autorise le chantier BDD, malgré l’ancien report du backend dans `agent.md`.

## Contraintes globales

- Tous les fichiers de ce plan sont dans `pokecoach2-conception/` ; les chemins suivants sont relatifs à ce dossier.
- Base `pokecoach2`, module `modules/1.0-core`, schéma `core`.
- Garder `V{x.y.z}__description.sql`, `R__description.sql`, `afterMigrate.sql`, profils repoindex et image Flyway.
- Aucune migration métier PerfAO ni aucun secret de référence copié.
- Pas de MinIO, Collabora, Carbone, serveur de production ou déploiement SSH.
- La configuration Docker utilise `postgres:5432` ; le client hôte utilise `127.0.0.1:5442` par défaut. Le port publié est configurable, sa disponibilité devra être vérifiée.
- Commentaires SQL et profils repoindex en anglais pour reprendre la convention PerfAO ; plans et documentation d’utilisation en français.

## Points de revue

| Risque | Contrôle propriétaire |
| --- | --- |
| Base/port différents entre scripts | Tâche 2 : une configuration, test via Docker et Devbox |
| Module avec uniquement des migrations en sous-dossiers ignoré | Tâche 3 : test du runner sur arbre temporaire |
| Historique Flyway incohérent | Tâche 4 : deuxième migrate et validate ; échec checksum en base de test |
| Compte API trop privilégié | Tâche 4 : assertions de rôles et refus des opérations DDL |
| Arrêt de la stack effaçant les données | Tâche 4 : down/up puis lecture d’une sentinelle |

## Arborescence cible

```text
AGENTS.md
README.md
.gitignore
.dockerignore
devbox.json
devbox.lock
Dockerfile
docker_entrypoint.sh
modules/1.0-core/
  1.0-core_repoindex.md
  sql/V1.0.1__init_schema.sql
  sql/afterMigrate.sql
repoindex/overview.md
repoindex/architecture.md
deployment/local/
  docker-compose.yml
  .env.example
  README.md
scripts/
  compose.sh
  bootstrap-roles.sh
  run-flyway.sh
  launch-flyway-on-existing-db.sh
  dump-only-ms-db-schema.sh
tests/
  runner.sh
  sql/001_bootstrap.sql
```

Les profils des migrations sont co-localisés (`V1.0.1__init_schema_repoindex.md`). Le plan 2 complète `modules/1.0-core/sql/` ; le plan 3 enrichit le même Compose.

## Tâche 1 — Conventions, environnement et image de migration

**Fichiers :** `AGENTS.md`, fichiers Devbox, ignores, `Dockerfile`, `README.md`.

**Interfaces :** `devbox run migrate`, `devbox run validate`, `devbox run info`, `devbox run dump-schema` délèguent aux scripts documentés ; aucun lancement automatique de migration à l’ouverture du shell.

- [ ] Créer `AGENTS.md` adapté : source de vérité SQL, migration appliquée immuable, pas de modification manuelle de `flyway_schema_history`, pas de `clean`, `repair` ou baseline automatique. Ne pas recopier les règles spécifiques à `core/kb/docx` de PerfAO.
- [ ] Fournir Flyway 11.11.2, client PostgreSQL 17, Bash et ShellCheck via Devbox avec versions verrouillées. Si cette version Flyway n’est pas disponible dans Devbox, utiliser l’image verrouillée via les scripts ; garder un seul moteur de migration de référence.
- [ ] Définir l’image Flyway depuis une distribution publique compatible, avec version puis digest résolus lors de l’exécution. Vérifier le binaire et PostgreSQL 17 par un smoke test avant de finaliser le verrouillage. L’image PerfAO privée n’est pas un prérequis.
- [ ] Exclure `.env`, dumps, logs, `.devbox/`, fichiers temporaires et données locales du suivi et du contexte Docker ; conserver `.env.example`, SQL, docs et lockfiles.
- [ ] Documenter les prérequis Docker/Compose et les commandes sans installer de composants système hors du périmètre autorisé.

## Tâche 2 — PostgreSQL local et rôles explicites

**Fichiers :** `deployment/local/docker-compose.yml`, `.env.example`, `scripts/compose.sh`, `scripts/bootstrap-roles.sh`.

**Interfaces et configuration :**

- `scripts/compose.sh <arguments...>` invoque Compose avec chemin, projet `pokecoach2-local` et fichier d’environnement explicitement définis ; fonctionne quel que soit le répertoire courant.
- Variables : `POSTGRES_DB=pokecoach2`, `POSTGRES_USER=pokecoach_admin`, `POSTGRES_PASSWORD`, `POSTGRES_PORT=5442`, `API_DB_PASSWORD`, `WORKER_DB_PASSWORD`. Les trois mots de passe sont saisis/générés localement ; pas de valeurs PerfAO ni de valeur utilisable versionnée.
- `postgres` : image PostgreSQL 17 verrouillée, volume nommé, `127.0.0.1:${POSTGRES_PORT}:5432`, healthcheck `pg_isready`.
- `db-bootstrap` : job court utilisant le client PostgreSQL et les credentials admin ; attend PostgreSQL sain, crée/actualise les rôles puis termine. Il peut être rejoué sur un volume existant.
- Rôles : `pokecoach_admin` pour initialisation/migrations ; `authenticated_user NOLOGIN` pour les droits applicatifs ; `pokecoach_api LOGIN NOINHERIT` membre de `authenticated_user` ; `pokecoach_worker LOGIN` aux droits attribués au plan 2. API et worker n’ont ni SUPERUSER, ni CREATEDB, ni CREATEROLE, ni REPLICATION, ni BYPASSRLS.

- [ ] Écrire le Compose minimal avec volume et réseau propres au projet, sans `container_name` fixe et sans référence à un volume PerfAO.
- [ ] Implémenter le bootstrap idempotent via `psql -v ON_ERROR_STOP=1`. Échapper les identifiants/valeurs SQL correctement ; ne pas interpoler les mots de passe comme fragments SQL ni les afficher. Aucun `set -x`.
- [ ] Refuser une configuration obligatoire absente avant de démarrer une migration. Fournir un message nommant la variable manquante sans afficher sa valeur.
- [ ] Ajouter `flyway` construit depuis la racine de conception, dépendant de `db-bootstrap: service_completed_successfully`. Job sans restart automatique ; le mot de passe passe par l’environnement Flyway, jamais par un argument logué.
- [ ] Valider avec `scripts/compose.sh config --quiet`, démarrer PostgreSQL puis le bootstrap, et vérifier l’existence des rôles ainsi que leurs attributs.

**Note :** les variables `POSTGRES_*` de l’image PostgreSQL initialisent une base vide ; modifier un fichier `.env` ne renomme pas une base ni ne change le mot de passe d’un volume existant. Documenter ce comportement et la procédure explicite de rotation, sans réinitialisation implicite. Voir l’[image officielle PostgreSQL](https://hub.docker.com/_/postgres).

## Tâche 3 — Runner Flyway et premier module

**Fichiers :** `docker_entrypoint.sh`, `scripts/run-flyway.sh`, `launch-flyway-on-existing-db.sh`, `modules/1.0-core/sql/V1.0.1__init_schema.sql`, `afterMigrate.sql`, `tests/runner.sh`.

**Interface :** `run-flyway.sh migrate|validate|info` accepte seulement ces commandes. Connexion fournie par `FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD` ; racine des modules déterminée depuis le script, surcharge explicite seulement pour les tests.

- [ ] Écrire les tests shell du runner avec un faux binaire Flyway : tri des dossiers, schéma extrait après le dernier tiret, migration en sous-dossier détectée, propagation d’un code d’échec, arguments contenant espaces conservés, absence de secrets dans les logs.
- [ ] Implémenter `set -euo pipefail`, ordre déterministe des modules et recherche récursive SQL. Ne pas déduire la « dernière version » du mtime ou d’un `ls` : Flyway fait le tri des versions.
- [ ] Configurer une location et un historique par schéma, `cleanDisabled=true`, `baselineOnMigrate=false`, validation des noms et des checksums. Le succès d’un module ne masque jamais l’échec du suivant.
- [ ] Faire déléguer `docker_entrypoint.sh` au runner commun ; commande par défaut `migrate`, puis `info` si la migration réussit. Garder le port dans l’URL JDBC.
- [ ] Créer le schéma `core` sous l’utilisateur de migration. Masquer la table d’historique avec `@omit` quand elle existe. Le callback initial doit fonctionner avec zéro table métier et pouvoir être rejoué.
- [ ] Documenter le rôle de `R__` et de `afterMigrate` correctement : repeatables rejoués sur changement de checksum ; callback à la fin de la commande migrate réussie, pas après chaque fichier. Voir les [événements Flyway](https://documentation.red-gate.com/flyway/reference/callback-events).
- [ ] Exécuter les tests shell, ShellCheck et le premier `migrate` sur la base de développement.

## Tâche 4 — Exploitation et vérifications reproductibles

**Fichiers :** script de dump, `tests/sql/001_bootstrap.sql`, README, repoindex et profils SQL.

- [ ] Fournir le dump structurel : `pg_dump --schema-only --schema=core`, chemin de sortie explicite dans un dossier ignoré, aucun mot de passe en ligne de commande. Une sortie SQL destinée à la documentation n’inclut pas de données utilisateur.
- [ ] Vérifier `migrate` deux fois puis `validate` et `info` : historique stable, aucun objet recréé ni doublon de rôle.
- [ ] Dans une base jetable isolée, provoquer une erreur SQL et un checksum invalide ; vérifier l’échec du runner. Ne jamais modifier une migration appliquée à la base de travail pour ce test.
- [ ] Tester les droits des rôles et le refus du DDL depuis API/worker. Il n’y a encore aucun droit métier à ce jalon.
- [ ] Vérifier `down` sans `-v`, puis `up` et présence d’une sentinelle de test. Toute destruction du volume est une opération distincte, jamais une étape de démarrage ordinaire.
- [ ] Écrire `repoindex/overview.md`, `architecture.md`, le profil du module et de la migration à partir du SQL livré ; expliciter la différence entre l’état réalisé et le modèle à venir du plan 2.
- [ ] Consigner versions et commandes réellement vérifiées. Si aucun dépôt Git n’est initialisé ici, ne pas prétendre avoir commité ; ne pas publier d’image.

**Fin du jalon :** PostgreSQL local persistant, rôles créés, migration `core` vérifiée, image et scripts utilisables. Aucun besoin de Python, Angular ou PostGraphile pour vérifier ce plan.
