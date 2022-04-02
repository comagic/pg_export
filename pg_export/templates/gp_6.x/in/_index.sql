select coalesce(json_agg(x), '[]')
  from (select quote_ident(i.relname) as name,
               idx.indisunique as is_unique,
               am.amname as access_method,
               i.reloptions as options,
               pg_get_expr(idx.indpred, idx.indrelid) as predicate,
               (select json_agg(
                         json_build_object(
                           'name', pg_get_indexdef(idx.indexrelid, i::int, true),
                           'order', format('%s%s',
                                           case
                                             when (u.option & {{ INDOPTION_DESC }}) <> 0
                                               then ' desc'
                                           end,
                                           case
                                             when (u.option & {{ INDOPTION_DESC }}) <> 0 and
                                                  not (u.option & {{ INDOPTION_NULLS_FIRST }}) <> 0
                                               then ' nulls last'
                                             when not (u.option & {{ INDOPTION_DESC }}) <> 0 and
                                                  (u.option & {{ INDOPTION_NULLS_FIRST }}) <> 0
                                               then ' nulls first'
                                           end),
                           'collate', quote_ident(coll.collname),
                           'opclass', oc.opcname,
                           'is_include', false) order by u.i)
                  from unnest(idx.indkey::int[], idx.indcollation, idx.indclass, idx.indoption) with ordinality u(key, coll, class, option, i)
                  left join pg_attribute a
                         on a.attrelid = idx.indrelid and
                            a.attnum = u.key
                  left join pg_type ct
                         on ct.oid = a.atttypid
                  left join pg_collation coll
                         on coll.oid = a.attcollation and
                            a.attcollation <> ct.typcollation
                  left join pg_opclass oc
                         on oc.oid = u.class and
                            not oc.opcdefault) as columns
          from pg_index idx
         inner join pg_class i
                 on i.oid = idx.indexrelid
         inner join pg_am am
                 on am.oid = i.relam
          left join pg_constraint cn
                 on cn.conindid = i.oid and
                    cn.contype in ('p', 'u', 'x')
         where idx.indrelid = c.oid and
               cn.conindid is null
         order by idx.indisunique desc, i.relname) as x
