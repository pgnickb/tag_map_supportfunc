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
