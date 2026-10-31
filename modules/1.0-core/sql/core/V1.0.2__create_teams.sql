-- Teams and Pokemon JSON validation.
CREATE OR REPLACE FUNCTION core.is_valid_pokemon_slot_entry(entry jsonb)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
DECLARE
  slot_val int;
  species text;
  moves jsonb;
  elem jsonb;
  idx int;
BEGIN
  IF entry IS NULL OR jsonb_typeof(entry) <> 'object' THEN
    RETURN false;
  END IF;
  IF NOT (entry ? 'slot') OR NOT (entry ? 'species') OR NOT (entry ? 'moves') OR NOT (entry ? 'rawBlock') THEN
    RETURN false;
  END IF;
  BEGIN
    slot_val := (entry ->> 'slot')::int;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN false;
  END;
  IF slot_val < 0 OR slot_val > 5 THEN
    RETURN false;
  END IF;
  species := btrim(entry ->> 'species');
  IF species IS NULL OR species = '' THEN
    RETURN false;
  END IF;
  moves := entry -> 'moves';
  IF jsonb_typeof(moves) <> 'array' THEN
    RETURN false;
  END IF;
  FOR idx IN 0..jsonb_array_length(moves) - 1 LOOP
    elem := moves -> idx;
    IF jsonb_typeof(elem) <> 'string' THEN
      RETURN false;
    END IF;
  END LOOP;
  IF entry ? 'gender' AND jsonb_typeof(entry -> 'gender') <> 'string' THEN
    RETURN false;
  END IF;
  IF entry ? 'level' THEN
    BEGIN
      IF (entry ->> 'level')::int IS NULL THEN
        RETURN false;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN false;
    END;
  END IF;
  IF entry ? 'evs' AND jsonb_typeof(entry -> 'evs') <> 'object' THEN
    RETURN false;
  END IF;
  IF entry ? 'ivs' AND jsonb_typeof(entry -> 'ivs') <> 'object' THEN
    RETURN false;
  END IF;
  IF jsonb_typeof(entry -> 'rawBlock') <> 'string' THEN
    RETURN false;
  END IF;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION core.is_valid_pokemon_slot_entry IS E'@omit';

CREATE OR REPLACE FUNCTION core.is_valid_pokemon_sets(p_sets jsonb)
  RETURNS boolean
  LANGUAGE plpgsql
  IMMUTABLE
  AS $$
DECLARE
  idx int;
  entry jsonb;
  seen boolean[] := ARRAY [false, false, false, false, false, false];
  slot_val int;
BEGIN
  IF p_sets IS NULL OR jsonb_typeof(p_sets) <> 'array' THEN
    RETURN false;
  END IF;
  IF jsonb_array_length(p_sets) <> 6 THEN
    RETURN false;
  END IF;
  FOR idx IN 0..5 LOOP
    entry := p_sets -> idx;
    IF NOT core.is_valid_pokemon_slot_entry(entry) THEN
      RETURN false;
    END IF;
    slot_val := (entry ->> 'slot')::int;
    IF slot_val <> idx THEN
      RETURN false;
    END IF;
    IF seen[slot_val + 1] THEN
      RETURN false;
    END IF;
    seen[slot_val + 1] := true;
  END LOOP;
  RETURN true;
END;
$$;

COMMENT ON FUNCTION core.is_valid_pokemon_sets IS E'@omit';

CREATE TABLE core.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL,
  name text NOT NULL,
  source_kind text NOT NULL,
  source_url text,
  source_text text NOT NULL,
  pokemon jsonb NOT NULL,
  data_version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by text NOT NULL DEFAULT 'system',
  updated_by text NOT NULL DEFAULT 'system',
  is_deleted boolean NOT NULL DEFAULT false,
  CONSTRAINT teams_kind_chk CHECK (kind IN ('owned', 'opponent')),
  CONSTRAINT teams_source_kind_chk CHECK (source_kind IN ('url', 'text')),
  CONSTRAINT teams_name_trim_chk CHECK (btrim(name) <> ''),
  CONSTRAINT teams_source_text_chk CHECK (btrim(source_text) <> ''),
  CONSTRAINT teams_source_url_chk CHECK (
    (
      source_kind = 'url'
      AND source_url IS NOT NULL
      AND source_url ~ '^https://pokepast\.es/'
    )
    OR (
      source_kind = 'text'
    )
  ),
  CONSTRAINT teams_data_version_chk CHECK (data_version > 0),
  CONSTRAINT teams_pokemon_chk CHECK (core.is_valid_pokemon_sets(pokemon) IS TRUE)
);

CREATE INDEX teams_list_idx ON core.teams (kind, is_deleted, created_at DESC, id);

COMMENT ON TABLE core.teams IS 'Owned and opponent teams with six Showdown sets stored as JSONB.';
COMMENT ON COLUMN core.teams.kind IS E'@omit update';
COMMENT ON COLUMN core.teams.data_version IS E'@omit create,update';
