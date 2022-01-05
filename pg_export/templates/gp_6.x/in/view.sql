select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relkind as kind,
       c.relacl as acl,
       pg_get_viewdef(c.oid, true) as query,
       (select coalesce(json_agg(r), '[]')
          from (select rw.rulename as name,
                       case ev_type --ruleutils.c
                         when '2'
                           then 'u'
                         when '3'
                           then 'i'
                         when '4'
                           then 'd'
                       end as event,
                       is_instead as instead,
                       regexp_replace(rd.def, ' (DO +|DO +INSTEAD +)(.*);', '\2') as query,
                       regexp_replace(rd.def, ' WHERE +\((.*)\) +DO', '\1') as predicate
                  from pg_rewrite rw
                 cross join pg_get_ruledef(rw.oid) as rd(def)
                 where rw.ev_class = c.oid and
                       rw.ev_type <> '1') r) as rules,
       ({% include 'in/_index.sql' %}) as indexes,
       ({% include 'in/_attribute.sql' %}) as columns,
       (select coalesce(
                 json_agg(
                   distinct
                   json_build_object(
                     'schema', dn.nspname,
                     'name', dc.relname)::jsonb),
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
 order by 1, 2
