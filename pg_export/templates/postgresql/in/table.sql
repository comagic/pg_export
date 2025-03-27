select quote_ident(n.nspname) as schema,
       quote_ident(c.relname) as name,
       quote_ident(sp.spcname) as tablespace,
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
                         {%- if version[0] >= 12 %}
                         when not s.is_serial and a.attgenerated = ''
                         {%- else %}
                         when not s.is_serial
                         {%- endif %}
                           then pg_get_expr(cd.adbin, cd.adrelid)
                       end as default,
                       {%- if version[0] >= 12 %}
                       case
                         when a.attgenerated != ''
                           then pg_get_expr(cd.adbin, cd.adrelid)
                       end as generated_stored,
                       {%- else %}
                       null as generated_stored,
                       {%- endif %}
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
       ({% include 'in/_rule.sql' %}) as rules,
       ({% include 'in/_index.sql' %}) as indexes,
       (select quote_ident(i.relname)
          from pg_index idx
         inner join pg_class i
                 on i.oid = idx.indexrelid
         where idx.indrelid = c.oid and
               idx.indisclustered) as clustered_index,
       ({% include 'in/_trigger.sql' %}) as triggers,
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
                                left join pg_attribute a
                                       on a.attrelid = c.oid and
                                          a.attnum = i))
       end as partition_by,
       case
         when b.expr is not null
           then json_build_object( --FIXME: need add WITH ( MODULUS ..., REMAINDER ...)
                  'in', substring(b.expr, '^FOR VALUES IN \((.*)\)$'),
                  'from', substring(b.expr, '^FOR VALUES FROM \((.*)\) TO.*$'),
                  'to', substring(b.expr, '^FOR VALUES FROM .* TO \((.*)\)'),
                  'is_default', b.expr = 'DEFAULT')
       end as attach,
       c.relreplident as replica_identity,
       quote_ident(cr.relname) as replica_identity_index
  from pg_class c
 inner join pg_namespace n
         on n.oid = c.relnamespace
  left join pg_tablespace sp
         on sp.oid =  c.reltablespace and
            sp.spcname <> 'pg_default'
  left join pg_partitioned_table p
         on p.partrelid = c.oid
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
 cross join pg_get_expr(c.relpartbound, c.oid) as b(expr)
 where c.relkind in ('r', 'p', 'f') and
       abs(hashint4(c.oid::integer)) % 4 = {{ chunk }} and
       n.nspname not in ('pg_catalog', 'information_schema') and
       {% with objid='c.oid', objclass='pg_class' %} {% include 'in/_not_part_of_extension.sql' %} {% endwith %}
       {%- include 'in/_namespace_filter.sql' %}
 order by 1, 2
