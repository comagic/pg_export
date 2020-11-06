select json_agg(x)
  from (select tn.nspname as schema,
               c.relname as name,
               d.description as comment,
               c.relacl as acl,
               c.relpersistence = 'u' as unlogged,
               (select json_agg(x)
                  from (select a.attname as name,
                               format_type(a.atttypid, a.atttypmod) as type,
                               coll.collname as collate,
                               a.attnotnull as not_null,
                               cd.adsrc as default,
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
                                       consrc as src,
                                       array(select cl.attname
                                               from unnest(conkey) with ordinality as k
                                               join pg_attribute as cl on cl.attrelid = c.oid and cl.attnum = k
                                               order by ordinality) as columns,
                                       array(select cl.attname
                                               from unnest(conkey) with ordinality as k
                                               join pg_attribute as cl on cl.attrelid = c.oid and cl.attnum = k
                                               order by ordinality) as fcolumns
                                  from pg_constraint cn
                                  left join (pg_class ft join pg_namespace fn on fn.oid = ft.relnamespace) on ft.oid = confrelid
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
                         where idx.indrelid = c.oid and
                                not indisprimary
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
                         order by tg.tgname) as x) as triggers
          from pg_class c
          join pg_namespace tn on tn.oid = c.relnamespace
          left join pg_description d on d.objoid = c.oid and d.objsubid = 0
         where c.relkind = 'r' and
               tn.nspname not in ('pg_catalog', 'information_schema')) as x