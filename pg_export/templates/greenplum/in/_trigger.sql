select json_agg(x)
  from (select quote_ident(tg.tgname) as name,
               tg.tgconstraint <> 0 as "constraint",
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
                   then substring(pg_get_triggerdef(tg.oid), 'WHEN (.*) EXECUTE PROCEDURE')
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
               tg.tgdeferrable as "deferrable",
               tg.tginitdeferred as "deferred",
               ft.relname as ftable_name,
               fn.nspname as ftable_schema,
               case
                 when tg.tgnargs > 0
                   then substring(pg_get_triggerdef(tg.oid), 'EXECUTE PROCEDURE [^(]+\((.*)\)$')
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
         order by tg.tgname) as x
