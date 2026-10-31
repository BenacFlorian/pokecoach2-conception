# Plans — Base de données et environnement local pokecoach2

Plans rédigés le 31 octobre 2026 après lecture des dépôts PerfAO et du frontend réellement implémenté. Aucun SQL, conteneur ou service n’est créé à ce stade.

## Ordre d’exécution

1. [Socle conception et migrations Flyway](./2026-10-31-01-conception-flyway.md) : structure du dépôt, PostgreSQL local, rôles, migrations, scripts et documentation.
2. [Modèle de données pokecoach2](./2026-10-31-02-modele-donnees.md) : équipes, matchups et historique des préparations, compatibles avec les données de l’interface.
3. [Docker Compose applicatif](./2026-10-31-03-docker-compose.md) : compléter le Compose avec PostGraphile et Angular, préparer le raccordement ultérieur de Python.

Chaque plan produit un jalon vérifiable. Le plan 1 fournit le Compose minimal nécessaire aux tests du plan 2 ; le plan 3 enrichit ce même fichier, sans deuxième stack PostgreSQL.

## Périmètre validé

- Reprendre l’organisation de `perfao-conception` et les principes de `perfao-deployment`.
- Placer les migrations **et** le Docker Compose dans `pokecoach2-conception`.
- Composants retenus : PostgreSQL, Flyway, PostGraphile, Angular, Python.
- **MinIO retiré à la demande de l’utilisateur. Collabora et Carbone exclus.** Aucun bucket, identifiant S3 ou service de remplacement.
- Pas de développement du moteur Python, VGC-Bench, entraînement ou LLM dans ces plans.
- Pas de modification de l’interface validée ni de remplacement immédiat de son `localStorage`. Le branchement Angular → GraphQL sera un chantier distinct après validation du contrat SQL/API.
- Les dossiers `pokecoach2-postgraphile/` et `pokecoach2-python/` sont vides lors de l’audit. Un Compose ne suffit pas à fournir leurs applications : PostGraphile peut fonctionner avec son CLI générique ; Python est un raccordement conditionné à une future image réelle.

## Ce qui a été inspecté

Racine des références locales : `/home/webinage/Documents/RD/PerfAO/workspace/`.

| Source | Constat tiré du code | Adaptation prévue |
| --- | --- | --- |
| `perfao-conception/Dockerfile`, `docker_entrypoint.sh` | Image Flyway 11.11.2, parcours des modules, schéma déduit du dossier | Garder le mécanisme ; retirer le traçage shell des secrets ; respecter le port configurable |
| `perfao-conception/modules/1.0-core/sql/` | Migrations `V*`, fonctions `R__*`, callback `afterMigrate.sql`, audit, annotations GraphQL | Un module `1.0-core` pour pokecoach2 ; aucune table métier PerfAO copiée |
| `perfao-conception/modules/1.0-core/sql/afterMigrate.sql` | Rôle `authenticated_user`, droits et masquage de l’audit | Grants ciblés sur les objets pokecoach2, sans héritage de grants documentaires |
| `perfao-conception/devbox.json`, `scripts/` | Flyway, client PostgreSQL et scripts de migration/dump | Versions verrouillées ; configuration externe commune ; aucun mot de passe copié |
| `perfao-deployment/environments/dev/docker-compose.yml` | PostgreSQL sain → Flyway terminé → API ; services persistants et logs limités | Même ordre de démarrage, noms/volumes/ports propres à pokecoach2 |
| `perfao-deployment/scripts/`, `global.config` | Déploiement SSH et registre privés PerfAO | Hors périmètre local : ne pas reprendre les serveurs, chemins distants ou credentials PerfAO |
| `perfao-postgraphile/perfao-postgraphile/src/server.ts` | PostGraphile v4, plugins, live queries, décodage JWT | CLI v4 minimal compatible avec `@omit`, sans live queries ni authentification copiée |
| `pokecoach2-angular/pokecoach-angular/src/app/core/models/` | Équipes à six slots, source URL/texte, rapports structurés | Préserver ces données ; identités/relations SQL et documents JSONB versionnés |
| `pokecoach2-angular/pokecoach-angular/src/app/core/data/` | Clé `pokecoach.demo.v1`, rapports mock, identifiants de démo non UUID | Pas de migration silencieuse du navigateur ; conversion d’identifiants explicite pour les fixtures SQL |

Les README PerfAO présentent certains décalages avec le code (noms de schémas, base et ports). Les plans retiennent les fichiers exécutables comme référence et fixent une seule configuration pokecoach2.

Attention à une nuance de documentation : `afterMigrate` intervient après une commande `migrate` réussie ; le callback par migration individuelle est `afterEachMigrate`. C’est le [cycle Flyway documenté](https://documentation.red-gate.com/flyway/reference/callback-events) qui fait foi.

## Choix d’adaptation proposés

- PostgreSQL **17**, même majeure que PerfAO, avec un patch/image publique vérifié et verrouillé à l’implémentation. ParadeDB et wal2json ne sont pas requis sans recherche documentaire ni live queries.
- Flyway **11.11.2** pour commencer avec la version du modèle PerfAO ; vérifier l’image publique et la compatibilité au démarrage. Ne pas modifier silencieusement la majeure.
- PostGraphile **v4**, comme le code PerfAO ; verrouiller un patch compatible. Une migration vers v5 serait une décision séparée.
- Environnement personnel local, sans gestion d’utilisateurs ni JWT. `authenticated_user` est un nom de rôle SQL repris de PerfAO, pas une affirmation qu’une authentification existe.
- Base `pokecoach2`, schéma `core`, Compose projet `pokecoach2-local`, accès hôte sur `127.0.0.1`.
- Rapports et six Pokémon conservés en JSONB validé ; tables relationnelles pour les équipes, matchups et préparations. Cela garde le détail des simulations évolutif avant l’audit VGC-Bench.

## Résultat attendu des trois plans

La base est recréable par migrations et interrogeable avec PostGraphile. L’interface actuelle peut être servie dans Docker, en restant en mode mock. La configuration Python est prête à recevoir une image pokecoach2, mais son activation et le raccordement de l’interface nécessitent les applications correspondantes. Aucun déploiement distant n’est entrepris.
