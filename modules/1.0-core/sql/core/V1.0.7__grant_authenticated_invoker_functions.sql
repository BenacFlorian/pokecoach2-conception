-- authenticated_user inserts run audit triggers and pokemon CHECK as invoker.
GRANT EXECUTE ON FUNCTION core.current_actor() TO authenticated_user, pokecoach_worker;
GRANT EXECUTE ON FUNCTION core.is_valid_pokemon_slot_entry(jsonb) TO authenticated_user, pokecoach_worker;
