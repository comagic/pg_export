import json
import os
import re
import asyncio
import aiofiles
import asyncpg

from .renderer import Renderer
from .pg_items.cast import Cast
from .pg_items.extension import Extension
from .pg_items.language import Language
from .pg_items.server import Server
from .pg_items.schema import Schema
from .pg_items.type import Type
from .pg_items.view import View
from .pg_items.table import Table
from .pg_items.sequence import Sequence
from .pg_items.function import Function
from .pg_items.aggregate import Aggregate
from .pg_items.operator import Operator
from .pg_items.publication import Publication
from .pg_items.domain import Domain


class Extractor:
    pool: asyncpg.pool.Pool
    renderer: Renderer
    directories: list

    def __init__(self, args):
        self.args = args

    async def init_pool(self):
        async def init_conn(conn):
            await conn.set_type_codec(
                'json',
                encoder=json.dumps,
                decoder=json.loads,
                schema='pg_catalog'
            )
            await conn.set_type_codec(
                'jsonb',
                encoder=json.dumps,
                decoder=json.loads,
                schema='pg_catalog'
            )
            await conn.set_type_codec(
                '"char"',
                encoder=lambda x: x,
                decoder=lambda x: x,
                schema='pg_catalog'
            )
            if self.args.timezone:
                await conn.execute(f"set time zone '{self.args.timezone}'")

        self.pool = await asyncpg.create_pool(
            database=self.args.database,
            user=self.args.user,
            password=self.args.password,
            host=self.args.host,
            port=self.args.port,
            min_size=self.args.jobs,
            max_size=self.args.jobs,
            statement_cache_size=0,
            init=init_conn
        )

    async def close_pool(self):
        await self.pool.close()

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
                raise Exception('Could not determine the version number: ' + version)
        return version

    async def create_renderer(self):
        fork, version = await self.get_version()
        self.renderer = Renderer(fork, version)

    async def ordered_dumps(self, item_class, items):
        for i in items:
            await item_class(i, self.renderer).dump(self.args.out_dir)

    async def dump_item(self, item_class, chunk=None):
        query = item_class.get_src_query(self.renderer, chunk)
        if self.args.echo_queries:
            print(f'\n\n--{item_class.__name__}\n{query}')
        src = await self.sql_execute(query)

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
                        item_class(i[0], self.renderer).dump(self.args.out_dir))
                else:
                    tasks.append(self.ordered_dumps(item_class, i))
        else:
            tasks = [
                item_class(i, self.renderer).dump(self.args.out_dir)
                for i in src
            ]
        if tasks:
            await asyncio.wait([asyncio.create_task(i) for i in tasks])

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
            self.dump_item(Domain),
            self.dump_item(View),
            self.dump_item(Publication),
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
