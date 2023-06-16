select coalesce(json_agg(r), '[]')
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
               rw.ev_type <> '1') r
