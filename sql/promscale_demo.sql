\unset ECHO

/* setup */
\i test_setup.sql


/* try and create extension */
create extension promscale_demo cascade;

/* seed random for consistent dataset */
select setseed(0.2);

/* populate tables with the test data */
insert into _ps_trace.tag_key(tag_type, key)
    select 1+(random()*100*k)::int8 % 5, 'Key_'||k
        from generate_series(1, 100) f(k);

insert into _ps_trace.tag(tag_type, key_id, key, value)
    select t.tag_type, t.id, t.key, jsonb('"val_'||val||'"')
        from _ps_trace.tag_key t,
             generate_series(1, 100 - floor(random() * t.id)::int8) f(val);

insert into _ps_trace.map(map)
    select map
        from
        (
            select grp, jsonb_cat(jsonb_build_object(k, v)) from
            (
                select distinct key_id, id, floor(random() * 100)::int4 as grp
                    from _ps_trace.tag, generate_series(1, 10)
                    where random() > 0.5
            ) as j(k,v)
                group by grp
        ) as maps(m, map),
        generate_series(1, (m * 907) % 359) as multi;

select plan(1);
/* tests */
select pass();

select * from finish();
