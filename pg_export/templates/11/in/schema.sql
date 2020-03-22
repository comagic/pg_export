select json_agg(x)
  from (select n.nspname as name,
               n.nspacl as acl,
               d.description as comment
          from pg_namespace n
          left join pg_description d on d.objoid = n.oid and d.objsubid = 0
         where n.nspname !~ '^pg_' and n.nspname <> 'information_schema'
         order by 1) as x
