select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relacl::text[] as acl,
       c.relpersistence = 'u' as unlogged,
       c.reloptions as options,
       (select array_agg(format('%s %L',
                                split_part(u, '=', 1),
                                split_part(u, '=', 2)))
          from unnest(ft.ftoptions) u) as foreign_options,
       quote_ident(fs.srvname) as server,
       c.relkind as kind,
       (select json_agg(x)
          from (select quote_ident(a.attname) as name,
                       case
                         when s.is_serial
                           then case ft.type
                                  when 'integer'
                                    then 'serial'
                                  when 'bigint'
                                    then 'bigserial'
                                end
                         else ft.type
                       end as type,
                       quote_ident(coll.collname) as collate,
                       a.attnotnull and not s.is_serial as not_null,
                       case
                         when not s.is_serial
                           then pg_get_expr(cd.adbin, cd.adrelid)
                       end as default,
                       null as generated_stored,
                       quote_literal(d.description) as comment,
                       a.attacl as acl,
                       nullif(a.attstattarget, -1) as statistics
                  from pg_attribute a
                 inner join pg_type ct
                         on ct.oid = a.atttypid
                  left join pg_collation coll
                         on coll.oid = a.attcollation and
                            a.attcollation <> ct.typcollation
                  left join pg_attrdef cd
                         on cd.adrelid = a.attrelid and
                            cd.adnum = a.attnum
                  {% with objid='c.oid', objclass='pg_class', objsubid='a.attnum' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
                 cross join format_type(a.atttypid, a.atttypmod) as ft(type)
                 cross join lateral (select pg_get_expr(cd.adbin, cd.adrelid) like 'nextval(%' and
                                            pg_get_serial_sequence(format('%I.%I', n.nspname, c.relname), a.attname) is not null) as s(is_serial)
                 where a.attrelid = c.oid and
                       a.attnum > 0 and
                       not a.attisdropped
                 order by a.attnum) as x) as columns,
       ({% include 'in/_constraint.sql' %}) as constraints,
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
                       is_instead as instead
--                        ,
--                        (regexp_match(rd.def, ' (DO +|DO +INSTEAD +)(.*);'))[2] as query,
--                        (regexp_match(rd.def, ' WHERE +\((.*)\) +DO'))[1] as predicate
                  from pg_rewrite rw
                 cross join pg_get_ruledef(rw.oid) as rd(def)
                 where rw.ev_class = c.oid and
                       rw.ev_type <> '1') r) as rules,
       ({% include 'in/_index.sql' %}) as indexes,
       (select quote_ident(i.relname)
          from pg_index idx
         inner join pg_class i
                 on i.oid = idx.indexrelid
         where idx.indrelid = c.oid and
               idx.indisclustered) as clustered_index,
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
                       null as old_table,
                       null as new_table,
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
       (select coalesce(
                 json_agg(
                   json_build_object(
                     'table_schema', ni.nspname,
                     'table_name', ci.relname) order by i.inhseqno),
                 '[]')
          from pg_inherits i
          join (pg_class ci join pg_namespace ni on ni.oid = ci.relnamespace) on ci.oid = i.inhparent
         where i.inhrelid = c.oid) as inherits,
       null as partition_by,
       null as attach,
       c.relreplident as replica_identity,
       quote_ident(cr.relname) as replica_identity_index
  from pg_class c
 inner join pg_namespace n
         on n.oid = c.relnamespace
  left join pg_foreign_table ft
         on ft.ftrelid = c.oid
  left join pg_foreign_server fs
         on fs.oid = ft.ftserver
  left join pg_index ir
            inner join pg_class cr
                    on cr.oid = ir.indexrelid
         on ir.indrelid = c.oid and
            ir.indisreplident and
            c.relreplident = 'i'
  {% with objid='c.oid', objclass='pg_class' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where c.relkind in ('r', 'p', 'f') and
       abs(hashint4(c.oid::integer)) % 4 = {{ chunk }} and
       n.nspname not in ('pg_catalog', 'information_schema') and
       {% with objid='c.oid', objclass='pg_class' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2
