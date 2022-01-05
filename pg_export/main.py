import os
import shutil
import argparse
import asyncio
from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool
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
        async with AsyncConnectionPool(coninfo,
                                       kwargs={"row_factory": dict_row,
                                               "autocommit": True},
                                       min_size=args.jobs,
                                       max_size=args.jobs) as pool:
            e = Extractor(pool, args.out_dir)
            await e.create_renderer()
            await e.get_directories()
            await asyncio.wait(e.extract_structure())
            await asyncio.wait(e.dump_directories(args.out_dir))

    loop = asyncio.get_event_loop()
    loop.run_until_complete(go())
