# Promscale Demo

Expose `spans` as a view over `tag_map_denormalize` function and use a support function on the `->` operator to optimize tag search.

Considerations:
1. This approach in conjunction with the fact we provide `->` in our own schema results in an unpleasant scenario:
if the user ends up issuing `->` operator while `ps_trace` schema isn't path of their `search_path`, then `_ps_trace.tag_map` will be implicitly cast into `jsonb` and the built-in `->` will be used, which will result in extremely poor performance.

2. We have several options regarding how we want our custom nodes to look in the plan output:
typedef enum CoercionForm
{
	COERCE_EXPLICIT_CALL,		/* display as a function call */
	COERCE_EXPLICIT_CAST,		/* display as an explicit cast */
	COERCE_IMPLICIT_CAST,		/* implicit cast, so hide it */
	COERCE_SQL_SYNTAX			/* display with SQL-mandated special syntax */
} CoercionForm;
For now I've decided to stick with COERCE_EXPLICIT_CALL


notes:

Source
```
select
        ...
    from ps_trace.spans
    where
        span_tags -> 'Key_1' = '"val_27"';
```

Translation:
```
select
        ...
    from _ps_trace.maps
    where
        denormalize(map) -> 'Key_1' = '"val_27"';
```

Target
```
select
        ...
    from _ps_trace.maps
    where map <@ find_label_ids('Key_1', '"val_27"')
```

What we need:

[+] Make sure we're in the correct place (= opr of tag_map)
[+] Get left arg and make sure it is `tag_map_denormalize`
[+] Get the arg of the `tag_map_denormalize` (it is our `map` column)
[+] Get the right arg of `=` opr (it is our label)
[+] Get the jsonb @> function (jsonb_contains)
[ ] Get the function find_label_ids(text, jsonb);
[ ] Build a node corresponding to

