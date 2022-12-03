with w_subpartition_template as (
  select schemaname,
         tablename,
         parentpartitiontablename,
         json_agg(
           json_build_object(
             'start', p.partitionrangestart,
             'start_inclusive', p.partitionstartinclusive,
             'end', p.partitionrangeend,
             'end_inclusive', p.partitionendinclusive,
             'every', case
                        when ts_range.start is not null
                          then format('''%s''::interval', age(ts_range.end, ts_range.start))
                        when int_range.start is not null
                          then (int_range.end - int_range.start)::text
                      end) order by partitionrangestart)::jsonb as subpartition_template
    from pg_partitions p
    left join lateral (select substring(p.partitionrangestart, '^''(.*)''::timestamp.*$')::timestamp as start,
                              substring(p.partitionrangeend, '^''(.*)''::timestamp.*$')::timestamp as end
                        where p.partitionrangestart ~ '^''(.*)''::timestamp.*$') as ts_range
           on true
    left join lateral (select p.partitionrangestart::integer as start,
                              p.partitionrangeend::integer as end
                        where p.partitionrangestart ~ '^\d+$') as int_range
           on true
   where p.partitionlevel = 1
   group by 1, 2, 3
),
w_partitions as (
  select p.schemaname,
         p.tablename,
         st.subpartition_template,
         json_agg(
             json_build_object(
               'start', p.partitionrangestart,
               'start_inclusive', p.partitionstartinclusive,
               'end', p.partitionrangeend,
               'end_inclusive', p.partitionendinclusive,
               'every', case
                          when ts_range.start is not null
                            then format('''%s''::interval', age(ts_range.end, ts_range.start))
                          when int_range.start is not null
                            then (int_range.end - int_range.start)::text
                        end) order by partitionrangestart)::jsonb as partitions
    from pg_partitions p
    left join lateral (select substring(p.partitionrangestart, '^''(.*)''::timestamp.*$')::timestamp as start,
                              substring(p.partitionrangeend, '^''(.*)''::timestamp.*$')::timestamp as end
                        where p.partitionrangestart ~ '^''(.*)''::timestamp.*$') as ts_range
           on true
    left join lateral (select p.partitionrangestart::integer as start,
                              p.partitionrangeend::integer as end
                        where p.partitionrangestart ~ '^\d+$') as int_range
           on true
    left join w_subpartition_template st
           on p.schemaname = st.schemaname and
              p.tablename = st.tablename and
              p.partitiontablename = st.parentpartitiontablename
   where p.partitionlevel = 0
   group by 1, 2, 3
)
select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_literal(d.description) as comment,
       c.relacl as acl,
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
       (select coalesce(json_object_agg(x.type, x.constraints), '{}')
          from (select x.type, json_agg(x order by x.name) as constraints
                  from (select quote_ident(cn.conname) as name,
                               cn.contype as type,
                               cn.condeferrable as deferrable,
                               cn.condeferred as deferred,
                               not cn.convalidated as not_valid,
                               quote_ident(ft.relname) as ftable_name,
                               quote_ident(fn.nspname) as ftable_schema,
                               pg_get_expr(cn.conbin, cn.conrelid, true) as src,
                               am.amname as access_method,
                               confupdtype as on_update,
                               confdeltype as on_delete,
                               confmatchtype as match_type,
                               array(select case
                                              when cn.contype = 'x'
                                                then pg_get_indexdef(cn.conindid, ck.i::int, false)
                                              else quote_ident(cl.attname)
                                            end
                                       from unnest(cn.conkey) with ordinality as ck(key, i)
                                       left join pg_attribute cl
                                              on cl.attrelid = cn.conrelid and
                                                 cl.attnum = ck.key
                                      order by ck.i) as columns,
                               array(select op.oprname
                                       from unnest(cn.conexclop) with ordinality as op_oid
                                      inner join pg_operator op
                                              on op.oid = op_oid
                                      order by ordinality) as operators,
                               array(select quote_ident(cl.attname)
                                       from unnest(cn.confkey) with ordinality as k
                                      inner join pg_attribute cl
                                              on cl.attrelid = cn.confrelid and
                                                 cl.attnum = k
                                       order by ordinality) as fcolumns
                          from pg_constraint cn
                          left join (pg_class ft
                                     inner join pg_namespace fn
                                             on fn.oid = ft.relnamespace)
                                 on ft.oid = confrelid
                          left join pg_class i
                                 on i.oid = cn.conindid
                          left join pg_am am
                                 on am.oid = i.relam
                         where cn.conrelid = c.oid) as x
                  group by 1) as x) as constraints,
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
       dp.policytype as distributed_type,
       (select coalesce(
                 json_agg(
                   json_build_object(
                     'table_schema', ni.nspname,
                     'table_name', ci.relname) order by i.inhseqno),
                 '[]')
          from pg_inherits i
          join (pg_class ci join pg_namespace ni on ni.oid = ci.relnamespace) on ci.oid = i.inhparent
         where i.inhrelid = c.oid) as inherits,
       (select coalesce(json_agg(a.attname order by u.i), '[]')
          from unnest(dp.distkey) with ordinality u(key, i)
         inner join pg_attribute a
                 on a.attrelid = c.oid and
                    a.attnum = u.key) as distributed_by,
       null as partition_by,
       null as attach,
       par.parkind as gp_partition_kind,
       (select array_agg(a.attname order by pa.i)
          from unnest(par.paratts) with ordinality as pa(num, i)
         inner join pg_attribute a
                 on a.attrelid = par.parrelid and
                    a.attnum = pa.num) as gp_partition_columns,
       coalesce(pr.partitions, '[]') as gp_partitions,
       spar.parkind as gp_subpartition_kind,
       (select array_agg(a.attname order by pa.i)
          from unnest(spar.paratts) with ordinality as pa(num, i)
         inner join pg_attribute a
                 on a.attrelid = spar.parrelid and
                    a.attnum = pa.num) as gp_subpartition_columns,
       coalesce(pr.subpartition_template, '[]') as gp_subpartition_template
  from pg_class c
 inner join pg_namespace n
         on n.oid = c.relnamespace
  left join pg_foreign_table ft
         on ft.ftrelid = c.oid
  left join pg_foreign_server fs
         on fs.oid = ft.ftserver
  left join gp_distribution_policy dp
         on dp.localoid = c.oid
  left join w_partitions pr
         on pr.schemaname = n.nspname and
            pr.tablename = c.relname
  left join pg_partition par
         on par.parrelid = c.oid and
            par.parlevel = 0 and
            not par.paristemplate
  left join pg_partition spar
         on spar.parrelid = c.oid and
            spar.parlevel = 1 and
            spar.paristemplate
  {% with objid='c.oid', objclass='pg_class' -%} {% include 'in/_join_description_as_d.sql' %} {% endwith %}
 where c.relkind in ('r', 'p', 'f') and
       abs(hashint4(c.oid::integer)) % 4 = {{ chunk }} and
       n.nspname not in ('pg_catalog', 'information_schema', 'pg_bitmapindex') and
       c.relname not in (select partitiontablename
                           from pg_partitions) and
       {% with objid='c.oid', objclass='pg_class' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
 order by 1, 2
