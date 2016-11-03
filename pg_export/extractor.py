# -*- coding:utf-8 -*-

import os
import psycopg2
import psycopg2.extras
from pg_export.pg_items.table import Table
from pg_export.pg_items.schema import Schema

structure_sql = '''
  select json_build_object(
           'schema',
           (select json_agg(x)
              from (select n.nspname as schema_name
                      from pg_namespace n
                     where n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
                     order by 1) as x),

           'table',
           (select json_agg(x)
              from (select tn.nspname as table_schema,
                           t.relname as table_name,
                           d.description as comment,
                           t.relacl as acl,
                           t.relpersistence = 'u' as unlogged,
                           (select json_agg(x)
                              from (select c.attname as name,
                                           format_type(c.atttypid, c.atttypmod) as type,
                                           coll.collname as collate,
                                           c.attnotnull as not_null,
                                           cd.adsrc as default,
                                           d.description as comment,
                                           c.attacl as acl,
                                           nullif(c.attstattarget, -1) as statistics
                                      from pg_attribute c
                                      join pg_type ct on ct.oid = c.atttypid
                                      left join pg_collation coll on coll.oid = c.attcollation and c.attcollation <> ct.typcollation
                                      left join pg_attrdef cd on cd.adrelid = c.attrelid and cd.adnum = c.attnum
                                      left join pg_description d on d.objoid = c.attrelid and d.objsubid = c.attnum
                                     where c.attrelid = t.oid and
                                           c.attnum > 0 and
                                           not c.attisdropped
                                     order by attnum) as x) as columns,
                           (select json_agg(x)
                              from (select c.conname as name,
                                           c.contype as type,
                                           c.condeferrable as deferrable,
                                           c.condeferred as deferred,
                                           not c.convalidated as not_valid,
                                           ft.relname as ftable_name,
                                           fn.nspname as ftable_schema,
                                           consrc as src,
                                           array(select cl.attname
                                                   from unnest(conkey) with ordinality as k
                                                   join pg_attribute as cl on cl.attrelid = t.oid and cl.attnum = k
                                                   order by ordinality) as columns,
                                           array(select cl.attname
                                                   from unnest(conkey) with ordinality as k
                                                   join pg_attribute as cl on cl.attrelid = t.oid and cl.attnum = k
                                                   order by ordinality) as fcolumns
                                      from pg_constraint c
                                      left join (pg_class ft join pg_namespace fn on fn.oid = ft.relnamespace) on ft.oid = confrelid
                                     where c.conrelid = t.oid) as x) as constraints,
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
                                     where tg.tgrelid = t.oid and not tg.tgisinternal
                                     order by tg.tgname) as x) as triggers
                      from pg_class t
                      join pg_namespace tn on tn.oid = t.relnamespace
                      left join pg_description d on d.objoid = t.oid and d.objsubid = 0
                     where t.relkind = 'r' and
                           tn.nspname not in ('pg_catalog', 'information_schema')) as x)
         ) as src'''

directory_sql = '''
  select nspname as schema,
         relname as name,
         (select (regexp_matches(obj_description(t.oid), 'synchronized directory\((.*)\)'))[1]) as cond
    from pg_class t
    join pg_namespace n on t.relnamespace = n.oid
   where relkind = 'r' and obj_description(t.oid) like '%%synchronized directory%%' '''


class Extractor:
    def __init__(self, connect):
        self.connect = connect

    def sql_execute(self, query, **query_params):
        c = self.connect.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        c.execute(query, query_params)
        res = c.fetchall()
        return res

    def extract_structure(self):
        self.src = self.sql_execute(structure_sql)[0]['src']
        self.schemas = [Schema(i) for i in self.src['schema']]
        self.tables = [Table(i) for i in self.src['table']]

    def dump_structure(self, root):
        self.extract_structure()

        for s in self.schemas:
            os.mkdir(os.path.join(root, s.schema_name))

        for t in self.tables:
            t.dump(root)

    def dump_directory(self, root):
        tables = self.sql_execute(directory_sql)
        if not tables:
            return

        root = os.path.join(root, 'data')
        os.mkdir(root)

        for s in set(t['schema'] for t in tables):
            os.mkdir(os.path.join(root, s))

        for t in tables:
            table_name = '.'.join([t['schema'], t['name']]).replace('public.', '')
            cond = 'where ' + t['cond'] if t['cond'] else ''
            with open(os.path.join(root, t['schema'], t['name']+'.sql'), 'w') as f:
                f.write('copy %s from stdin;\n' % table_name)
                self.connect.cursor().copy_to(f, '(select * from %s %s order by 1)' % (table_name, cond))
                f.write('\\.\n')
