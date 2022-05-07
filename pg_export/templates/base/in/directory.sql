select n.nspname as schema,
         t.relname as name,
         (select (regexp_matches(
                    d.description,
                    'synchronized directory\((.*)\)'))[1]) as cond
    from pg_class t
    join pg_namespace n on t.relnamespace = n.oid
   cross join obj_description(t.oid) as d(description)
   where relkind = 'r' and
         d.description like '%synchronized directory%'
