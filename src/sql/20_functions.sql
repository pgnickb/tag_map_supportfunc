/* src/sql/10_functions.sql */

CREATE FUNCTION _ps_trace.tag_map_support(internal)
    RETURNS internal
    LANGUAGE C AS 'promscale_demo', 'tag_map_support';

CREATE FUNCTION ps_trace.tag_v_eq(_ps_trace.tag_v, pg_catalog.jsonb)
    RETURNS pg_catalog.bool
    LANGUAGE internal
        IMMUTABLE
        PARALLEL SAFE
        SUPPORT _ps_trace.tag_map_support
    AS 'jsonb_eq';

CREATE AGGREGATE ps_trace.jsonb_cat(pg_catalog.jsonb)
(
    SFUNC = pg_catalog.jsonb_concat,
    STYPE = pg_catalog.jsonb
);

CREATE FUNCTION ps_trace.tag_map_object_field(ps_trace.tag_map, pg_catalog.text)
    RETURNS _ps_trace.tag_v
    LANGUAGE internal AS 'jsonb_object_field';

/* NOTE: This function cannot be inlined since it's used in a scalar
 * context and uses an aggregate
 */
CREATE FUNCTION ps_trace.tag_map_denormalize(_map ps_trace.tag_map)
    RETURNS ps_trace.tag_map
    LANGUAGE sql STABLE
    PARALLEL SAFE AS
$fnc$
    SELECT ps_trace.jsonb_cat(pg_catalog.jsonb_build_object(t.key, t.value))
        FROM pg_catalog.jsonb_each(_map) f(k,v)
            JOIN _ps_trace.tag t ON
                    f.k::int8 = t.key_id
                AND f.v::int8 = t.id;
$fnc$;

CREATE FUNCTION _ps_trace.find_label_ids(_key pg_catalog.text, _value pg_catalog.jsonb)
    RETURNS pg_catalog.jsonb
    LANGUAGE sql STABLE
    PARALLEL SAFE AS
$fnc$
    SELECT pg_catalog.jsonb_build_object(t.key_id::pg_catalog.text, t.id)
        FROM _ps_trace.tag t
        WHERE
                    t.key   = _key
                AND t.value = _value;
$fnc$;

