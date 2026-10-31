-- Bootstrap assertions for plan 1 stack (run against migrated DB).
SELECT 1
WHERE EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'pokecoach_admin'
);

SELECT 1
WHERE EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'authenticated_user' AND rolcanlogin IS FALSE
);

SELECT 1
WHERE EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'pokecoach_api' AND rolinherit IS FALSE
);

SELECT 1
WHERE EXISTS (
  SELECT 1
  FROM pg_roles r
  WHERE r.rolname = 'pokecoach_api'
    AND r.rolsuper IS FALSE
    AND r.rolcreatedb IS FALSE
    AND r.rolcreaterole IS FALSE
    AND r.rolreplication IS FALSE
    AND r.rolbypassrls IS FALSE
);

SELECT 1
WHERE EXISTS (
  SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core'
);

SELECT 1
WHERE EXISTS (
  SELECT 1 FROM core.stack_sentinel WHERE id = 'pokecoach2-local'
);
