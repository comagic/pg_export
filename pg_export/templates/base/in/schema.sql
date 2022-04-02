select quote_ident(n.nspname) as name,
       quote_literal(d.description) as comment,
       n.nspacl::text[] as acl
  from pg_namespace n
  {% with objid='n.oid', objclass='pg_namespace' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname !~ '^pg_' and
       n.nspname <> 'information_schema' and
       {% with objid='n.oid', objclass='pg_namespace' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1
