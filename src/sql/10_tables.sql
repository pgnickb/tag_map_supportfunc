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

CREATE INDEX ON _ps_trace.map USING gin(map);
