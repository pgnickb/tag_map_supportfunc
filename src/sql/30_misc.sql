/* src/sql/20_misc.sql */

CREATE VIEW ps_trace.spans AS
    SELECT ps_trace.tag_map_denormalize(map) as span_tags
        FROM _ps_trace.map;

