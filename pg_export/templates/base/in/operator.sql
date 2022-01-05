select quote_ident(n.nspname) as schema,
       o.oprname as name,
       quote_literal(d.description) as comment,
       o.oprcode as func,
       format_type(o.oprleft, -1) as left_type,
       format_type(o.oprright, -1) as right_type,
       o.oprcanmerge as merges,
       o.oprcanhash as hashes,
       ocom.oprname as commutator,
       oneg.oprname as negator,
       o.oprrest::regproc as restrict_func,
       o.oprjoin::regproc as join_func
  from pg_operator o
 inner join pg_namespace n
         on n.oid = o.oprnamespace
  left join pg_operator ocom
         on ocom.oid = o.oprcom
  left join pg_operator oneg
         on oneg.oid = o.oprnegate
  {% with objid='o.oid', objclass='pg_operator' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where n.nspname not in ('pg_catalog', 'pg_toast', 'information_schema') and
       {% with objid='o.oid', objclass='pg_operator' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2, 5, 6
