select json_agg(x)
  from (select n.nspname as name,
               n.nspacl
          from pg_namespace n
         where n.nspname !~ '^pg_' and n.nspname <> 'information_schema'
         order by 1) as x
