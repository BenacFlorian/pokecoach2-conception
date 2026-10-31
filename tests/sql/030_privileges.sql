SET ROLE pokecoach_api;
SET ROLE authenticated_user;

DO $$
BEGIN
  PERFORM 1 FROM core.teams LIMIT 1;
END
$$;

DO $$
BEGIN
  EXECUTE 'CREATE TABLE core.evil_api (id int)';
  RAISE EXCEPTION 'api ddl should fail';
EXCEPTION
  WHEN insufficient_privilege THEN
    NULL;
END
$$;

DO $$
BEGIN
  BEGIN
    DELETE FROM core.teams WHERE false;
    RAISE EXCEPTION 'delete should be denied';
  EXCEPTION
    WHEN insufficient_privilege THEN
      NULL;
  END;
END
$$;

RESET ROLE;
