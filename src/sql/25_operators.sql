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
