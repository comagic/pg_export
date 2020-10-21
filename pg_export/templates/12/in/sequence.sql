select json_agg(x)
  from (select n.nspname as schema,
               c.relname as name,
               c.relacl as acl,
               nullif(seqstart, 1) as start,
               nullif(seqincrement, 1) as increment,
               nullif(seqmin, 1) as min,
               nullif(nullif(seqmax, 2^31-1), 2^63-1) as max,
               nullif(seqcache, 1) as cache,
               seqcycle as cycle
          from pg_sequence s
          left join pg_class c
                 on c.oid = s.seqrelid
         inner join pg_namespace n
                 on n.oid = c.relnamespace
          left join pg_description d on d.objoid = c.oid and d.objsubid = 0
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
               not exists (select 1
                             from pg_depend d
                            where d.objid = c.oid and
                                  d.classid = 'pg_class'::regclass and
                                  deptype = 'a')) as x
