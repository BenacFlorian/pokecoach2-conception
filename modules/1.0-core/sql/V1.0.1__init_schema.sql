-- Initial core schema for pokecoach2 migrations.
CREATE SCHEMA IF NOT EXISTS core AUTHORIZATION pokecoach_admin;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

COMMENT ON SCHEMA core IS 'Pokecoach2 relational and JSONB domain objects.';
