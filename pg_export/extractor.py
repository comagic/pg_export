# -*- coding:utf-8 -*-

import os
import psycopg2
import psycopg2.extras
from pg_export.render import render
from pg_export.pg_items.schema import Schema
from pg_export.pg_items.type import Type
from pg_export.pg_items.table import Table
from pg_export.pg_items.function import Function

directory_sql = '''
  select n.nspname as schema,
         t.relname as name,
         (select (regexp_matches(obj_description(t.oid),
                                 'synchronized directory\((.*)\)'))[1]) as cond
    from pg_class t
    join pg_namespace n on t.relnamespace = n.oid
   where relkind = 'r' and
         obj_description(t.oid) like '%%synchronized directory%%' '''


class Extractor:
    def __init__(self, connect):
        self.connect = connect

    def sql_execute(self, query, **query_params):
        c = self.connect.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        c.execute(query, query_params)
        res = c.fetchall()
        return res

    def get_version(self):
        self.version = self.sql_execute('select version()')[0]['version']
        self.version = self.version.split()[1]                # get number
        self.version = '.'.join(self.version.split('.')[:-1]) # discard minor

    def extract_structure(self):
        self.get_version()
        self.src = self.sql_execute(render(os.path.join(self.version, 'in', 'database.sql'), {}))[0]['src']
        self.schemas = [Schema(i, self.version) for i in self.src['schemas']]
        self.types = [Type(i, self.version) for i in self.src['types']]
        self.tables = [Table(i, self.version) for i in self.src['tables']]
        self.functions = [Function(i, self.version) for i in self.src['functions']]

    def dump_structure(self, root):
        self.extract_structure()

        root = os.path.join(root, 'schema')
        os.mkdir(root)

        for s in self.schemas:
            os.mkdir(os.path.join(root, s.name))
            if any(True for t in self.types if t.schema == s.name):
                os.mkdir(os.path.join(root, s.name, 'types'))
            if any(True for t in self.tables if t.schema == s.name):
                os.mkdir(os.path.join(root, s.name, 'tables'))
            if any(True for f in self.functions if f.schema == s.name and f.directory == 'functions'):
                os.mkdir(os.path.join(root, s.name, 'functions'))
            if any(True for f in self.functions if f.schema == s.name and f.directory == 'triggers'):
                os.mkdir(os.path.join(root, s.name, 'triggers'))
            if any(True for f in self.functions if f.schema == s.name and f.directory == 'procedures'):
                os.mkdir(os.path.join(root, s.name, 'procedures'))

        for t in self.types:
            t.dump(root)

        for t in self.tables:
            t.dump(root)

        for f in self.functions:
            f.dump(root)

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

            if t['cond'] and t['cond'].startswith('select'):
                query = t['cond']
            else:
                query = 'select * from %s %s order by 1' % (table_name, 'where ' + t['cond'] if t['cond'] else '')

            with open(os.path.join(root, t['schema'], t['name']+'.sql'), 'w') as f:
                f.write('copy %s from stdin;\n' % table_name)
                self.connect.cursor().copy_to(f, '(%s)' % query)
                f.write('\\.\n')
