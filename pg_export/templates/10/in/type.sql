select json_agg(x)
  from (select n.nspname as schema,
               t.typname as name,
               t.typacl as acl,
               case t.typtype
                 when 'e' then 'enum'
                 when 'c' then 'composite'
               end as type,
               (select array_agg(e.enumlabel order by enumsortorder)
                  from pg_enum e
                 where enumtypid = t.oid) as enum_lables,
               ({% include '10/in/attribute.sql' %}) as columns
          from pg_type t
         inner join pg_namespace n
                 on n.oid = t.typnamespace
          left join pg_class c
                 on c.oid = t.typrelid
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
               (c.relkind is null or c.relkind = 'c') and
               t.typname not like e'\\_%%' and -- implicit array
               t.typtype <> 'd'                -- domain
         order by 1, 2) as x
