select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relkind as kind,
       c.relacl::text[] as acl,
       pg_get_viewdef(c.oid, true) as query,
       ({% include 'in/_rule.sql' %}) as rules,
       ({% include 'in/_index.sql' %}) as indexes,
       ({% include 'in/_attribute.sql' %}) as columns,
       ({% include 'in/_trigger.sql' %}) as triggers,
       (select coalesce(
                 json_agg(
                   distinct
                   jsonb_build_object(
                     'schema', dn.nspname,
                     'name', dc.relname)),
                 '[]')
         from pg_rewrite r
        inner join pg_depend d
                on d.objid = r.oid
        inner join pg_class dc
                on dc.oid = d.refobjid and dc.oid <> c.oid
        inner join pg_namespace dn
                on dn.oid = dc.relnamespace
        where r.ev_class = c.oid and
              dc.relkind = 'v') as depend_on_view
  from pg_class c
 inner join pg_namespace n
         on n.oid = c.relnamespace
  {% with objid='c.oid', objclass='pg_class' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       c.relkind in ('v', 'm') and
       {% with objid='c.oid', objclass='pg_class' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
       {%- include 'in/_namespace_filter.sql' %}
 order by 1, 2
