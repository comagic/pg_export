select json_agg(x)
  from (select n.nspname as schema,
               c.relname as name,
               c.relacl as acl,
               pg_get_viewdef(c.oid, true) as query,
               (select coalesce(json_agg(r), '[]')
                  from (select rw.rulename as name,
                               case ev_type --ruleutils.c
                                 when '2'
                                   then 'u'
                                 when '3'
                                   then 'i'
                                 when '4'
                                   then 'd'
                               end as event,
                               is_instead as instead,
                               (regexp_match(rd.def, ' (DO +|DO +INSTEAD +)(.*);'))[2] as query,
                               (regexp_match(rd.def, ' WHERE +\((.*)\) +DO'))[1] as predicate
                          from pg_rewrite rw
                         cross join pg_get_ruledef(rw.oid) as rd(def)
                         where rw.ev_class = c.oid and
                               rw.ev_type <> '1') r) as rules
          from pg_class c
         inner join pg_namespace n
                 on n.oid = c.relnamespace
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
               c.relkind = 'v'
         order by 1, 2) as x
