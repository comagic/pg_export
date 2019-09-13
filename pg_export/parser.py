# -*- coding:utf-8 -*-

import re
import os
import psycopg2
import psycopg2.extras

from pg_items import *

item_types = {
    'ACL': Acl,
    'DEFAULT ACL': DAcl,
    'AGGREGATE': Aggregate,
    'CAST': Cast,
    'COMMENT': Comment,
    'CONSTRAINT': Constraint,
    'DEFAULT': Default,
    'DOMAIN': Domain,
    'EXTENSION': Extension,
    'FK CONSTRAINT': FkConstraint,
    'FOREIGN TABLE': ForeignTable,
    'FUNCTION': Function,
    'INDEX': Index,
    'OPERATOR': Operator,
    'PROCEDURAL LANGUAGE': Language,
    'RULE': Rule,
    'SCHEMA': Schema,
    'SEQUENCE': Sequence,
    'SEQUENCE OWNED BY': SequenceOwnedBy,
    'SERVER': Server,
    'TABLE': Table,
    'TRIGGER': Trigger,
    'TYPE': Type,
    'USER MAPPING': UserMapping,
    'VIEW': View,
    'MATERIALIZED VIEW': MaterializedView
}

class Parser:
    def __init__(self, db_connect):
        self.dump_version = None
        self.db_connect = db_connect
        self.schemas = {}
        Schema(self, 'public; Type: SCHEMA; Schema: -; Owner: postgres') #init default schema
        self.pg_types = self.sql_execute('''
            select array_agg(distinct typname::regtype) as types
              from pg_type
              join pg_namespace n on n.oid = typnamespace
             where nspname = 'pg_catalog' and not typname like 'pg_%%' and
                   typcategory <> 'P' ''')[0]['types']

    def parse(self, src_file):
        if type(src_file) == file:
            dump = src_file.read()
        else:
            dump = open(src_file).read()
        dump = re.sub('SET search_path = .*;\n', '', dump)
        dump = re.sub('SET default_tablespace = \'\';\n', '', dump)
        dump = re.sub('SET default_with_oids = false;\n', '', dump)
        dump = dump.replace('--\n-- PostgreSQL database dump complete\n--', '')
        dump = re.split('--\n-- Name: ', dump)
        self.dump_version = map(int, re.match('.*pg_dump version (.+)', dump.pop(0).split('\n')[5]).groups()[0].split('.'))

        for item in dump:
            header = item.split('\n')[0]
            m = re.match('.*Type: ([^;]+);.*', header)
            if not m:
                print "WARNING: Unusual header:", header
                continue
            itype = m.groups()[0]
            if itype not in item_types:
                print "WARNING: Unknown item type:", itype, header
                continue
            item_types[itype](self, item)

        self.post_processing()

    def post_processing(self):
        for s in self.schemas.values():
            s.post_processing()

    def dump_all(self, root_dir):
        if self.schemas:
            root_dir = os.path.join(root_dir, 'schema')
            os.mkdir(root_dir)
        for s in self.schemas.values():
            s.dump(root_dir)

    def mkdir(root_dir, dir_name):
        os.mkdir(os.join(root_dir, dir_name))

    def sql_execute(self, query, **query_params):
        c = self.db_connect.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        c.execute(query, query_params)
        res = c.fetchall()
        return res
