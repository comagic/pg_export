select json_agg(x)
  from (select quote_ident(e.extname) as name,
               quote_ident(n.nspname) as with_schema,
               quote_literal(e.extversion) as with_version
          from pg_extension e
          left join pg_namespace n
                 on n.oid = e.extnamespace
         order by 1, 2) as x
