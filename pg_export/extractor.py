# -*- coding:utf-8 -*-

import os
import re
import asyncio
import aiofiles
from pg_export.pg_items import item
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


class Extractor:
    def __init__(self, pool, root):
        self.pool = pool
        self.root = root

    async def sql_execute(self, query, **params):
        async with self.pool.acquire() as con:
            return await con.fetch(query, *params)

    async def get_version(self):
        version = (await self.sql_execute('select version()'))[0]['version']
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

    async def create_renderer(self):
        fork, version = await self.get_version()
        self.renderer = Renderer(fork, version)

    async def ordered_dumps(self, item_class, items):
        for i in items:
            await item_class(i, self.renderer).dump(self.root)

    async def dump_item(self, item_class, chunk=None):
        src = await self.sql_execute(
            item_class.get_src_query(self.renderer, chunk)
        )

        if item_class in [Function, Aggregate, Operator]:
            groups = {}
            if item_class == Operator:
                for i in src:
                    groups.setdefault(i['schema'], []).append(i)
            else:
                for i in src:
                    groups.setdefault((i['schema'], i['name']), []).append(i)

            tasks = []
            for i in groups.values():
                if len(i) == 1:
                    tasks.append(
                        item_class(i[0], self.renderer).dump(self.root))
                else:
                    tasks.append(self.ordered_dumps(item_class, i))
        else:
            tasks = [item_class(i, self.renderer).dump(self.root) for i in src]
        if tasks:
            await asyncio.wait(tasks)

    def extract_structure(self):
        return [
            self.dump_item(Table, 0),
            self.dump_item(Table, 1),
            self.dump_item(Table, 2),
            self.dump_item(Table, 3),
            self.dump_item(Function, 0),
            self.dump_item(Function, 1),
            self.dump_item(Function, 2),
            self.dump_item(Function, 3),
            self.dump_item(Aggregate),
            self.dump_item(Cast),
            self.dump_item(Extension),
            self.dump_item(Language),
            self.dump_item(Operator),
            self.dump_item(Schema),
            self.dump_item(Sequence),
            self.dump_item(Server),
            self.dump_item(Type),
            self.dump_item(View),
        ]

    async def get_directories(self):
        query = self.renderer.render('in/directory.sql', {})
        self.directories = await self.sql_execute(query)

    async def dump_directory(self, table, root):
        table_name = '.'.join([table['schema'],
                               table['name']]).replace('public.', '')
        path = os.path.join(root, table['schema'], table['name'] + '.sql')

        if table['cond'] and table['cond'].startswith('select'):
            query = table['cond']
        elif table['cond']:
            query = 'select * from %s where %s order by 1' % (table_name,
                                                              table['cond'])
        else:
            query = 'select * from %s order by 1' % table_name

        async with self.pool.acquire() as con:
            async with aiofiles.open(path, 'wb') as f:
                await f.write(f'copy {table_name} from stdin;\n'.encode())
                await con.copy_from_query(query, output=f.write)
                await f.write(b'\\.\n')

    def dump_directories(self, root):
        if not self.directories:
            return []

        root = os.path.join(root, 'data')
        os.mkdir(root)

        for s in set(d['schema'] for d in self.directories):
            os.mkdir(os.path.join(root, s))

        return [self.dump_directory(d, root) for d in self.directories]
