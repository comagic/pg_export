select json_agg(x)
  from (select quote_ident(n.nspname) as schema,
               quote_ident(t.typname) as name,
               quote_literal(d.description) as comment,
               t.typacl as acl,
               case t.typtype
                 when 'e'
                   then 'enum'
                 when 'c'
                   then 'composite'
               end as type,
               (select array_agg(e.enumlabel order by enumsortorder)
                  from pg_enum e
                 where enumtypid = t.oid) as enum_lables,
               ({% include 'PG_12/in/_attribute.sql' %}) as columns
          from pg_type t
         inner join pg_namespace n
                 on n.oid = t.typnamespace
          left join pg_class c
                 on c.oid = t.typrelid
          {% with objid='c.oid', objclass='pg_class' -%} {% include 'PG_12/in/_join_description_as_d.sql' %} {% endwith %}
         where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
               (c.relkind is null
                or
                c.relkind = 'c') and
               t.typname not like e'\\_%%' and -- implicit array
               t.typtype <> 'd'            and -- domain
               {% with objid='t.oid', objclass='pg_type' %} {% include 'PG_12/in/_not_part_of_extension.sql' %} {% endwith %}
         order by 1, 2) as x
