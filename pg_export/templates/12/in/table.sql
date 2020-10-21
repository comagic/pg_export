select json_agg(x)
  from (select tn.nspname as schema,
               c.relname as name,
               d.description as comment,
               c.relacl as acl,
               c.relpersistence = 'u' as unlogged,
               (select json_agg(x)
                  from (select a.attname as name,
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
                               coll.collname as collate,
                               a.attnotnull and not s.is_serial as not_null,
                               case
                                 when not s.is_serial
                                   then pg_get_expr(cd.adbin, cd.adrelid)
                               end as default,
                               d.description as comment,
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
                          left join pg_description d
                                 on d.objoid = a.attrelid and
                                    d.objsubid = a.attnum
                         cross join format_type(a.atttypid, a.atttypmod) as ft(type)
                         cross join lateral (select cd.adbin is not null and
                                                    pg_get_serial_sequence(tn.nspname||'.'||c.relname, a.attname) is not null) as s(is_serial)
                         where a.attrelid = c.oid and
                               a.attnum > 0 and
                               not a.attisdropped
                         order by a.attnum) as x) as columns,
               (select coalesce(json_object_agg(x.type, x.constraints), '{}')
                  from (select x.type, json_agg(x order by x.name) as constraints
                          from (select cn.conname as name,
                                       cn.contype as type,
                                       cn.condeferrable as deferrable,
                                       cn.condeferred as deferred,
                                       not cn.convalidated as not_valid,
                                       ft.relname as ftable_name,
                                       fn.nspname as ftable_schema,
                                       pg_get_expr(cn.conbin, cn.conrelid) as src,
                                       am.amname as access_method,
                                       array(select cl.attname
                                               from unnest(cn.conkey) with ordinality as k
                                               join pg_attribute cl on cl.attrelid = c.oid and cl.attnum = k
                                              order by ordinality) as columns,
                                       array(select op.oprname
                                               from unnest(cn.conexclop) with ordinality as op_oid
                                               join pg_operator op on op.oid = op_oid
                                              order by ordinality) as operators,
                                       array(select cl.attname
                                               from unnest(cn.confkey) with ordinality as k
                                               join pg_attribute cl on cl.attrelid = c.oid and cl.attnum = k
                                               order by ordinality) as fcolumns
                                  from pg_constraint cn
                                  left join (pg_class ft join pg_namespace fn on fn.oid = ft.relnamespace) on ft.oid = confrelid
                                  left join pg_class i on i.oid = cn.conindid
                                  left join pg_am am on am.oid = i.relam
                                 where cn.conrelid = c.oid) as x
                          group by 1) as x) as constraints,
               (select coalesce(json_agg(x), '[]')
                  from (select i.relname as name,
                               idx.indisunique as is_unique,
                               am.amname as access_method,
                               pg_get_expr(indpred, c.oid) as predicate,
                               (select array_agg(coalesce(attname, pg_get_expr(indexprs, c.oid))) -- FIXME incorrect coalesce(attname, pg_get_expr())
                                  from unnest(indkey::int[]) i
                                  left join pg_attribute on attrelid = c.oid and attnum = i) as columns
                          from pg_index idx
                          join pg_class i on i.oid = idx.indexrelid
                          join pg_am am on am.oid = i.relam
                          left join pg_constraint cn on cn.conindid = i.oid and cn.contype in ('p', 'u', 'x')
                         where idx.indrelid = c.oid and
                               cn.conindid is null
                         order by idx.indisunique desc, i.relname is null) as x) as indexes,
               (select json_agg(x)
                  from (select tg.tgname as name,
                               tg.tgconstraint <> 0 as constraint,
                               case when (tg.tgtype & (1<<0))::boolean then 'row' else 'statement' end as each,
                               case when (tgtype & (1<<1))::boolean then 'before' when (tgtype & (1<<6))::boolean then 'instead of' else 'after' end as when,
                               array(select 'insert'
                                      where (tgtype & (1<<2))::boolean
                                     union all
                                     select 'update' ||
                                            case when tgattr <> ''
                                              then ' of ' ||
                                                   array_to_string(array(
                                                     select cl.attname
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
                               fn.nspname as ftable_schema
                          from pg_trigger tg
                          join (pg_proc p join pg_namespace pn on pn.oid = p.pronamespace) on p.oid = tgfoid
                          left join (pg_class ft join pg_namespace fn on fn.oid = ft.relnamespace) on ft.oid = tg.tgconstrrelid
                         where tg.tgrelid = c.oid and not tg.tgisinternal
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
               case
                 when p.partstrat is not null
                   then json_build_object(
                          'strategy', p.partstrat,
                          'columns', (select array_agg(a.attname) --FIXME: need add expration
                                        from unnest(p.partattrs::int[]) i
                                        left join pg_attribute a on a.attrelid = c.oid and a.attnum = i))
               end as partition_by,
               case
                 when b.expr is not null
                   then json_build_object( --FIXME: need add WITH ( MODULUS ..., REMAINDER ...)
                          'in', (regexp_match(b.expr, '^FOR VALUES IN \((.*)\)$'))[1],
                          'from', (regexp_match(b.expr, '^FOR VALUES FROM \((.*)\) TO.*$'))[1],
                          'to', (regexp_match(b.expr, '^FOR VALUES FROM .* TO \((.*)\)'))[1],
                          'is_default', b.expr = 'DEFAULT')
               end as attach

          from pg_class c
          join pg_namespace tn on tn.oid = c.relnamespace
          left join pg_description d on d.objoid = c.oid and d.objsubid = 0
          left join pg_partitioned_table p on p.partrelid = c.oid
         cross join pg_get_expr(c.relpartbound, c.oid) as b(expr)
         where c.relkind in ('r', 'p') and
               tn.nspname not in ('pg_catalog', 'information_schema')) as x
