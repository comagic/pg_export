select coalesce(json_agg(x), '[]')
  from (select quote_ident(i.relname) as name,
               quote_ident(isp.spcname) as tablespace,
               idx.indisunique as is_unique,
               {%- if version[0] >= 15  %}
               idx.indnullsnotdistinct as nulls_not_distinct,
               {%- endif %}
               am.amname as access_method,
               i.reloptions as options,
               pg_get_expr(idx.indpred, idx.indrelid) as predicate,
               ({% include 'in/_index_columns.sql' %}) as columns
          from pg_index idx
         inner join pg_class i
                 on i.oid = idx.indexrelid
         inner join pg_am am
                 on am.oid = i.relam
          left join pg_tablespace isp
                 on isp.oid =  i.reltablespace and
                    isp.spcname <> 'pg_default'
          left join pg_constraint cn
                 on cn.conindid = i.oid and
                    cn.contype in ('p', 'u', 'x')
         where idx.indrelid = c.oid and
               cn.conindid is null
         order by idx.indisunique desc, i.relname) as x
