/* promscale_demo--1.0.sql */

-- complain if script is sourced in psql, rather than via create extension
\echo Use "create extension promscale_demo version '1.0'" to load this file. \quit
/* src/sql/00_ddl.sql */

/* public entities */
CREATE SCHEMA ps_trace;

/* internal entities */
CREATE SCHEMA _ps_trace;
/* src/sql/05_type.sql */

/* ps_trace.tag_map type definition.
 *
 * Type is identical to jsonb but is extended with support functions for a
 * number of operators to improve performance in promscale specific cases.
 *
 * Depends on PostgreSQL version. PG14 added support for subscripts
 * for jsonb type.
 */

CREATE TYPE ps_trace.tag_map;
CREATE TYPE _ps_trace.tag_v;

CREATE OR REPLACE FUNCTION ps_trace.tag_map_in(cstring)
 RETURNS ps_trace.tag_map
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_in$function$
;

CREATE OR REPLACE FUNCTION ps_trace.tag_map_out(ps_trace.tag_map)
 RETURNS cstring
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_out$function$
;

CREATE OR REPLACE FUNCTION ps_trace.tag_map_send(ps_trace.tag_map)
 RETURNS bytea
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_send$function$
;

CREATE OR REPLACE FUNCTION ps_trace.tag_map_recv(internal)
 RETURNS ps_trace.tag_map
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_recv$function$
;

DO
$do$
/* Create subscript_handler function for pg v14+ and the type accordingly.
 * For pg v13 jsonb type doesn't have a subscript_handler function so it shall
 * be omitted.
 */
DECLARE
    _pg_version int4 := current_setting('server_version_num')::int4;
BEGIN
    IF (_pg_version >= 140000) THEN
        EXECUTE
            'CREATE OR REPLACE FUNCTION ps_trace.tag_map_subscript_handler(internal) ' ||
                'RETURNS internal '                 ||
                'LANGUAGE internal '                ||
                'IMMUTABLE PARALLEL SAFE STRICT '   ||
                'AS $f$jsonb_subscript_handler$f$;'
            ;

        EXECUTE
            'CREATE TYPE ps_trace.tag_map ( '       ||
                'INPUT = ps_trace.tag_map_in, '     ||
                'OUTPUT = ps_trace.tag_map_out, '   ||
                'SEND = ps_trace.tag_map_send, '    ||
                'RECEIVE = ps_trace.tag_map_recv, ' ||
                'SUBSCRIPT = ps_trace.tag_map_subscript_handler);'
            ;

    ELSE
        EXECUTE
            'CREATE TYPE ps_trace.tag_map ( '       ||
                'INPUT = ps_trace.tag_map_in, '     ||
                'OUTPUT = ps_trace.tag_map_out, '   ||
                'SEND = ps_trace.tag_map_send, '    ||
                'RECEIVE = ps_trace.tag_map_recv);'
            ;

    END IF;
END
$do$;


CREATE CAST (jsonb AS ps_trace.tag_map) WITHOUT FUNCTION AS IMPLICIT;
CREATE CAST (ps_trace.tag_map AS jsonb) WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (json AS ps_trace.tag_map) WITH INOUT AS ASSIGNMENT;
CREATE CAST (ps_trace.tag_map AS json) WITH INOUT AS ASSIGNMENT;

-- CREATE CAST (text AS ps_trace.tag_map) WITH INOUT AS IMPLICIT;
-- CREATE CAST (ps_trace.tag_map AS text) WITH INOUT AS ASSIGNMENT;


CREATE DOMAIN ps_trace.tag_k text NOT NULL CHECK (value != '');
-- GRANT USAGE ON DOMAIN ps_trace.tag_k TO prom_reader;

CREATE DOMAIN ps_trace.tag_v jsonb NOT NULL;
-- GRANT USAGE ON DOMAIN ps_trace.tag_v TO prom_reader;

CREATE DOMAIN ps_trace.tag_type smallint NOT NULL; --bitmap, may contain several types
-- GRANT USAGE ON DOMAIN ps_trace.tag_type TO prom_reader;


CREATE OR REPLACE FUNCTION _ps_trace.tag_v_in(cstring)
 RETURNS _ps_trace.tag_v
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_in$function$
;

CREATE OR REPLACE FUNCTION _ps_trace.tag_v_out(_ps_trace.tag_v)
 RETURNS cstring
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_out$function$
;

CREATE OR REPLACE FUNCTION _ps_trace.tag_v_send(_ps_trace.tag_v)
 RETURNS bytea
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_send$function$
;

CREATE OR REPLACE FUNCTION _ps_trace.tag_v_recv(internal)
 RETURNS _ps_trace.tag_v
 LANGUAGE internal
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$jsonb_recv$function$
;

DO
$do$
/* Create subscript_handler function for pg v14+ and the type accordingly.
 * For pg v13 jsonb type doesn't have a subscript_handler function so it shall
 * be omitted.
 */
DECLARE
    _pg_version int4 := pg_catalog.current_setting('server_version_num')::int4;
BEGIN
    IF (_pg_version >= 140000) THEN
        EXECUTE
            'CREATE OR REPLACE FUNCTION _ps_trace.tag_v_subscript_handler(internal) ' ||
                'RETURNS internal '                 ||
                'LANGUAGE internal '                ||
                'IMMUTABLE PARALLEL SAFE STRICT '   ||
                'AS $f$jsonb_subscript_handler$f$;'
            ;

        EXECUTE
            'CREATE TYPE _ps_trace.tag_v ( '       ||
                'INPUT = _ps_trace.tag_v_in, '     ||
                'OUTPUT = _ps_trace.tag_v_out, '   ||
                'SEND = _ps_trace.tag_v_send, '    ||
                'RECEIVE = _ps_trace.tag_v_recv, ' ||
                'SUBSCRIPT = _ps_trace.tag_v_subscript_handler);'
            ;

    ELSE
        EXECUTE
            'CREATE TYPE _ps_trace.tag_v ( '       ||
                'INPUT = _ps_trace.tag_v_in, '     ||
                'OUTPUT = _ps_trace.tag_v_out, '   ||
                'SEND = _ps_trace.tag_v_send, '    ||
                'RECEIVE = _ps_trace.tag_v_recv);'
            ;

    END IF;
END
$do$;


CREATE CAST (pg_catalog.jsonb AS _ps_trace.tag_v) WITHOUT FUNCTION AS IMPLICIT;
CREATE CAST (_ps_trace.tag_v AS pg_catalog.jsonb) WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.json AS _ps_trace.tag_v) WITH INOUT AS ASSIGNMENT;
CREATE CAST (_ps_trace.tag_v AS pg_catalog.json) WITH INOUT AS ASSIGNMENT;
/* src/sql/10_tables.sql */

CREATE TABLE _ps_trace.tag_key
(
    id        pg_catalog.int8   NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tag_type  ps_trace.tag_type NOT NULL,
    key       ps_trace.tag_k    NOT NULL UNIQUE
);

CREATE TABLE _ps_trace.tag
(
    id        pg_catalog.int8   NOT NULL GENERATED ALWAYS AS IDENTITY,
    tag_type  ps_trace.tag_type NOT NULL,
    key_id    pg_catalog.int8   NOT NULL,
    key       ps_trace.tag_k    NOT NULL REFERENCES _ps_trace.tag_key (key) ON DELETE CASCADE,
    value     ps_trace.tag_v    NOT NULL,
    UNIQUE (key, value) INCLUDE (id, key_id)
);

CREATE TABLE _ps_trace.map
(
    map       ps_trace.tag_map
);
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

/* src/sql/025_operators */

CREATE OPERATOR ps_trace.->
(
    FUNCTION = ps_trace.tag_map_object_field,
    LEFTARG  = ps_trace.tag_map,
    RIGHTARG = pg_catalog.text
);

CREATE OPERATOR ps_trace.=
(
    FUNCTION       = ps_trace.tag_v_eq,
    LEFTARG        = _ps_trace.tag_v,
    RIGHTARG       = pg_catalog.jsonb,
    COMMUTATOR     = '=',
    NEGATOR        = '<>',
    RESTRICT       = eqsel,
    JOIN           = eqjoinsel,
    HASHES, MERGES

);
/* src/sql/20_misc.sql */

CREATE VIEW ps_trace.spans AS
    SELECT ps_trace.tag_map_denormalize(map) as span_tags
        FROM _ps_trace.map;

