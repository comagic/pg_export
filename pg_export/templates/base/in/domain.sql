select quote_ident(n.nspname) as schema,
       quote_ident(t.typname) as name,
       t.typbasetype::regtype as basetype,
       quote_literal(d.description) as comment,
       quote_ident(coll.collname) as "collate",
       t.typdefault as "default",
       t.typnotnull as not_null,
       t.typacl::text[] as acl,
       (select coalesce(json_agg(x order by x.name), '{}') as check_constraints
          from (select quote_ident(cn.conname) as name,
                       pg_get_expr(cn.conbin, cn.conrelid, true) as src
                  from pg_constraint cn
                 where cn.contypid = t.oid and
                       cn.contype = 'c') as x)
  from pg_type t
 inner join pg_namespace n
         on n.oid = t.typnamespace
  left join pg_collation coll
         on coll.oid = t.typcollation and
            coll.collname <> 'default'
  {% with objid='t.oid', objclass='pg_type' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       t.typtype = 'd' and
       {% with objid='t.oid', objclass='pg_type' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2
