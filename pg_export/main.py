import json
import os
import shutil
import argparse
import asyncio
import asyncpg
from pg_export.extractor import Extractor


def main():
    arg_parser = argparse.ArgumentParser(
        description='Export structure of databese to object '
                    'files for control version system',
        epilog='Report bugs to <a.n.d@inbox.ru>.',
        conflict_handler='resolve')
    arg_parser.add_argument('--clean',
                            action="store_true",
                            help='clean out_dir if not empty')
    arg_parser.add_argument('-h', '--host',
                            type=str, help='host for connect db')
    arg_parser.add_argument('-p', '--port',
                            type=str, help='port for connect db')
    arg_parser.add_argument('-U', '--username',
                            type=str, help='user for connect db')
    arg_parser.add_argument('-W', '--password',
                            type=str, help='password for connect db')
    arg_parser.add_argument('-j', '--jobs',
                            type=int, help='number of connections',
                            default=4)
    arg_parser.add_argument('dbname', help='source databese name')
    arg_parser.add_argument('out_dir', help='directory for object files')
    args = arg_parser.parse_args()

    if not os.access(args.out_dir, os.F_OK):
        try:
            os.mkdir(args.out_dir)
        except Exception:
            arg_parser.error("can not access to directory '%s'" % args.out_dir)

    if os.listdir(args.out_dir):
        if args.clean:
            for f in os.listdir(args.out_dir):
                shutil.rmtree(os.path.join(args.out_dir, f))
        else:
            arg_parser.error('distination directory not empty '
                             '(you can use option --clean)')

    coninfo = ''
    if args.dbname:
        coninfo += ' dbname=' + args.dbname
    if args.host:
        coninfo += ' host=' + args.host
    if args.port:
        coninfo += ' port=' + args.port
    if args.username:
        coninfo += ' username=' + args.username
    if args.password:
        coninfo += ' password=' + args.password

    async def go():

        async def init_conn(conn):
            # Для каждого нового конекта будем устанавливать кодеки
            async with conn.transaction():
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

        async with asyncpg.create_pool(
            'postgres://{}:{}@{}:{}/{}'.format(
                args.username, args.password, args.host, args.port, args.dbname
            ),
            init=init_conn,
            command_timeout=60
        ) as pool:
            e = Extractor(pool, args.out_dir)
            await e.create_renderer()
            await e.get_directories()
            await asyncio.wait(e.extract_structure())
            directories = e.dump_directories(args.out_dir)
            if directories:
                await asyncio.wait(e.dump_directories(args.out_dir))

    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    loop = asyncio.get_event_loop()
    loop.run_until_complete(go())
