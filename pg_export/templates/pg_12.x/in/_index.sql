select coalesce(json_agg(x), '[]')
  from (select quote_ident(i.relname) as name,
               idx.indisunique as is_unique,
               am.amname as access_method,
               i.reloptions as options,
               pg_get_expr(idx.indpred, idx.indrelid) as predicate,
               ({% include 'in/_index_columns.sql' %}) as columns
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