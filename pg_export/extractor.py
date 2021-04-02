# -*- coding:utf-8 -*-

import os
import re
import psycopg2
import psycopg2.extras
from pg_export.renderer import Renderer
from pg_export.pg_items.cast import Cast
from pg_export.pg_items.extension import Extension
from pg_export.pg_items.language import Language
from pg_export.pg_items.server import Server
from pg_export.pg_items.schema import Schema
from pg_export.pg_items.type import Type
from pg_export.pg_items.view import View
from pg_export.pg_items.table import Table
from pg_export.pg_items.sequence import Sequence
from pg_export.pg_items.function import Function
from pg_export.pg_items.aggregate import Aggregate
from pg_export.pg_items.operator import Operator

directory_sql = '''
  select n.nspname as schema,
         t.relname as name,
         (select (regexp_matches(
                    obj_description(t.oid),
                    'synchronized directory\\((.*)\\)'))[1]) as cond
    from pg_class t
    join pg_namespace n on t.relnamespace = n.oid
   where relkind = 'r' and
         obj_description(t.oid) like '%%synchronized directory%%' '''


class Extractor:
    def __init__(self, connect):
        self.connect = connect
        self.INDOPTION_DESC = 0x0001         # src/backend/catalog/pg_index_d.h
        self.INDOPTION_NULLS_FIRST = 0x0002  # src/backend/catalog/pg_index_d.h
        self.get_last_builtin_oid()
        self.create_renderer()

    def sql_execute(self, query, **query_params):
        c = self.connect.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        c.execute(query, query_params)
        res = c.fetchall()
        return res

    def get_version(self):
        version = self.sql_execute('select version()')[0]['version']
        match = re.match('.*Greenplum Database (\\d+).(\\d+).(\\d+)', version)
        if match:
            version = 'gp_', match.groups()
        else:
            match = re.match('PostgreSQL (\\d+).(\\d+)', version)
            if match:
                version = 'pg_', match.groups()
            else:
                raise Exception('Could not determine the version number: ' +
                                version)
        return version

    def get_last_builtin_oid(self):
        """
        postgresql-11.5/src/include/access/transam.h:
        #define FirstNormalObjectId   16384

        postgresql-11.5/src/bin/pg_dump/pg_dump.c:
        g_last_builtin_oid = FirstNormalObjectId - 1;
        """
        self.last_builtin_oid = 16384 - 1     # src/include/access/transam.h

    def create_renderer(self):
        fork, version = self.get_version()
        self.renderer = Renderer(fork, version)

    def extract_structure(self):
        self.src = self.sql_execute(
                        self.renderer.render(
                            os.path.join('in', 'database.sql'),
                            self.__dict__))[0]['src']

        self.casts = [Cast(i, self.renderer)
                      for i in self.src['casts'] or []]
        self.extensions = [Extension(i, self.renderer)
                           for i in self.src['extensions'] or []]
        self.languages = [Language(i, self.renderer)
                          for i in self.src['languages'] or []]
        self.servers = [Server(i, self.renderer)
                        for i in self.src['servers'] or []]
        self.schemas = [Schema(i, self.renderer)
                        for i in self.src['schemas'] or []]
        self.types = [Type(i, self.renderer)
                      for i in self.src['types'] or []]
        self.tables = [Table(i, self.renderer)
                       for i in self.src['tables'] or []]
        self.views = [View(i, self.renderer)
                      for i in self.src['views'] or []]
        self.sequences = [Sequence(i, self.renderer)
                          for i in self.src['sequences'] or []]
        self.functions = [Function(i, self.renderer)
                          for i in self.src['functions'] or []]
        self.aggregates = [Aggregate(i, self.renderer)
                           for i in self.src['aggregates'] or []]
        self.operators = [Operator(i, self.renderer)
                          for i in self.src['operators'] or []]

    def dump_structure(self, root):
        self.extract_structure()

        for c in self.casts:
            c.dump(root)
        for e in self.extensions:
            e.dump(root)
        for i in self.languages:
            i.dump(root)
        for s in self.servers:
            s.dump(root)

        root = os.path.join(root, 'schemas')
        os.mkdir(root)

        for s in self.schemas:
            s.dump(root)
        for t in self.types:
            t.dump(root)
        for t in self.tables:
            t.dump(root)
        for v in self.views:
            v.dump(root)
        for s in self.sequences:
            s.dump(root)
        for f in self.functions:
            f.dump(root)
        for a in self.aggregates:
            a.dump(root)
        for o in self.operators:
            o.dump(root)

    def dump_directory(self, root):
        tables = self.sql_execute(directory_sql)
        if not tables:
            return

        root = os.path.join(root, 'data')
        os.mkdir(root)

        for s in set(t['schema'] for t in tables):
            os.mkdir(os.path.join(root, s))

        for t in tables:
            table_name = '.'.join([t['schema'],
                                   t['name']]).replace('public.', '')

            if t['cond'] and t['cond'].startswith('select'):
                query = t['cond']
            else:
                query = 'select * from %s %s order by 1' % (
                            table_name,
                            'where ' + t['cond'] if t['cond'] else ''
                        )

            with open(os.path.join(root,
                                   t['schema'],
                                   t['name'] + '.sql'),
                      'w',
                      encoding="utf-8") as f:
                f.write('copy %s from stdin;\n' % table_name)
                self.connect.cursor().copy_to(f, '(%s)' % query)
                f.write('\\.\n')
