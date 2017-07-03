# -*- coding:utf-8 -*-

import os
import psycopg2
import psycopg2.extras


class DataDumper:

    def __init__(self, db_connect):
        self.db_connect = db_connect

    def dump_all(self, root_dir, args):
        schemas = self.sql_execute('''
            select distinct nspname
              from pg_class t
              join pg_namespace n on t.relnamespace = n.oid
             where relkind = 'r' and obj_description(t.oid) like '%%synchronized directory%%' ''')
        if not schemas:
            return

        root_dir = os.path.join(root_dir, 'data')
        os.mkdir(root_dir)

        for s in schemas:
            os.mkdir(os.path.join(root_dir, s['nspname']))

        tables = self.sql_execute('''
            select nspname, relname, 
                   (array(select (regexp_matches(obj_description(t.oid),
                                 'synchronized directory\((.*)\)'))[1]))[1] as cond
              from pg_class t
              join pg_namespace n on t.relnamespace = n.oid
             where relkind = 'r' and obj_description(t.oid) like '%%synchronized directory%%' ''')
        for t in tables:
            table_name = '.'.join([t['nspname'], t['relname']]).replace('public.', '')
            file_name = os.path.join(root_dir, t['nspname'], t['relname']+'.sql')
            if t['cond'] and t['cond'].startswith('select'):
                query = t['cond']
            else:
                cond = 'where ' + t['cond'] if t['cond'] else ''
                query = 'select * from %s %s order by 1' % (table_name, cond)

            os.popen('psql -c "\copy (%s) to %s" %s %s' % (query, file_name, args.connect_args, args.dbname))

            body = open(file_name).read()
            if body:
                body = 'copy %s from stdin;\n%s\\.\n' % (table_name, body)
                open(file_name, 'w').write(body)
            else:
                os.remove(file_name)

    def sql_execute(self, query, **query_params):
        c = self.db_connect.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        c.execute(query, query_params)
        res = c.fetchall()
        return res
