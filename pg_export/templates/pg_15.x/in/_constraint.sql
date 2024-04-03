        select coalesce(json_object_agg(x.type, x.constraints), '{}')
          from (select x.type, json_agg(x order by x.name) as constraints
                  from (select quote_ident(cn.conname) as name,
                               cn.contype as type,
                               cn.condeferrable as deferrable,
                               cn.condeferred as deferred,
                               not cn.convalidated as not_valid,
                               quote_ident(ft.relname) as ftable_name,
                               quote_ident(fn.nspname) as ftable_schema,
                               pg_get_expr(cn.conbin, cn.conrelid, true) as src,
                               am.amname as access_method,
                               confupdtype as on_update,
                               confdeltype as on_delete,
                               confmatchtype as match_type,
                               pg_get_expr(idx.indpred, idx.indrelid) as predicate,
                               idx.indnullsnotdistinct as nulls_not_distinct,
                               array(select quote_ident(cl.attname)
                                       from unnest(cn.conkey) with ordinality as ck(key, i)
                                       left join pg_attribute cl
                                              on cl.attrelid = cn.conrelid and
                                                 cl.attnum = ck.key
                                      where cn.contype not in ('p', 'u', 'x')
                                      order by ck.i) as columns,
                               ({% with operators='cn.conexclop' %} {% include 'in/_index_columns.sql' %} {% endwith %}
                                 where cn.contype in ('p', 'u', 'x')) as idx_columns,
                               array(select quote_ident(cl.attname)
                                       from unnest(cn.confkey) with ordinality as k
                                      inner join pg_attribute cl
                                              on cl.attrelid = cn.confrelid and
                                                 cl.attnum = k
                                       order by ordinality) as fcolumns
                          from pg_constraint cn
                          left join (pg_class ft
                                     inner join pg_namespace fn
                                             on fn.oid = ft.relnamespace)
                                 on ft.oid = confrelid
                          left join pg_index idx
                                 on idx.indexrelid = cn.conindid
                          left join pg_class i
                                 on i.oid = cn.conindid
                          left join pg_am am
                                 on am.oid = i.relam
                         where cn.conrelid = c.oid) as x
                  group by 1) as x
