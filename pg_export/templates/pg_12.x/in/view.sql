select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relkind as kind,
       c.relacl::text[] as acl,
       pg_get_viewdef(c.oid, true) as query,
       ({% include 'in/_rule.sql' %}) as rules,
       ({% include 'in/_index.sql' %}) as indexes,
       (select json_agg(x)
          from (select quote_ident(tg.tgname) as name,
                       tg.tgconstraint <> 0 as constraint,
                       case
                         when (tg.tgtype & (1<<0))::boolean
                           then 'row'
                         else 'statement'
                       end as each,
                       case
                         when (tgtype & (1<<1))::boolean
                           then 'before'
                         when (tgtype & (1<<6))::boolean
                           then 'instead of'
                         else 'after'
                       end as type,
                       case
                         when tg.tgqual is not null
                           then substring(pg_get_triggerdef(tg.oid), 'WHEN (.*) EXECUTE FUNCTION')
                       end as condition,
                       array(select 'insert'
                              where (tgtype & (1<<2))::boolean
                             union all
                             select 'update' ||
                                    case when tgattr <> ''
                                      then ' of ' ||
                                           array_to_string(array(
                                             select quote_ident(cl.attname)
                                               from unnest(tgattr) with ordinality as k
                                               join pg_attribute as cl on cl.attrelid = tg.tgrelid and cl.attnum = k
                                              order by ordinality), ', ')
                                      else ''
                                    end
                              where (tgtype & (1<<4))::boolean
                             union all
                             select 'delete'
                              where (tgtype & (1<<3))::boolean
                             union all
                             select 'truncate'
                              where (tgtype & (1<<5))::boolean) as actions,
                       p.proname as function_name,
                       pn.nspname as function_schema,
                       tg.tgdeferrable as deferrable,
                       tg.tginitdeferred as deferred,
                       ft.relname as ftable_name,
                       fn.nspname as ftable_schema,
                       tg.tgoldtable as old_table,
                       tg.tgnewtable as new_table,
                       case
                         when tg.tgnargs > 0
                           then substring(pg_get_triggerdef(tg.oid), 'EXECUTE FUNCTION [^(]+\((.*)\)$')
                         else ''
                       end as arguments
                  from pg_trigger tg
                 inner join (pg_proc p
                             inner join pg_namespace pn
                                     on pn.oid = p.pronamespace)
                         on p.oid = tgfoid
                  left join (pg_class ft
                             inner join pg_namespace fn
                                     on fn.oid = ft.relnamespace)
                         on ft.oid = tg.tgconstrrelid
                 where tg.tgrelid = c.oid and
                       not tg.tgisinternal
                 order by tg.tgname) as x) as triggers,
       ({% include 'in/_attribute.sql' %}) as columns,
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
 order by 1, 2
