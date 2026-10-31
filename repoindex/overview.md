# pokecoach2-conception — overview

Flyway-managed PostgreSQL schema **`core`** for VGC matchup preparation data: teams (six JSONB slots), matchups, and preparation runs with versioned reports.

Local stack: Docker Compose project `pokecoach2-local`, optional PostGraphile and Angular profile. No MinIO/S3.

**Current milestone:** relational model and constraints from plans 1–2; GraphQL read/write via PostGraphile CLI (plan 3). Angular remains mock until a separate wiring task.

Demo SQL ids map Angular demo strings to UUIDs (`docs/data-contract.md`).
