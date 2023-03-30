import os
import shutil
import argparse
import asyncio
import asyncpg
from .extractor import Extractor
from . import __version__


asyncpg.protocol.BUILTIN_TYPE_NAME_MAP['"char"'] = 18  # fix bug in asyncpg


def main():
    arg_parser = argparse.ArgumentParser(
        description='Export structure of database to object '
                    'files for control version system',
        epilog='Report bugs to <a.n.d@inbox.ru>.',
        conflict_handler='resolve')
    arg_parser.add_argument('--version',
                            action='version',
                            version=__version__)
    arg_parser.add_argument('--clean',
                            action="store_true",
                            help='clean out_dir if not empty')
    arg_parser.add_argument('-h', '--host',
                            type=str, help='host for connect db')
    arg_parser.add_argument('-p', '--port',
                            type=str, help='port for connect db')
    arg_parser.add_argument('-U', '--user',
                            type=str, help='user for connect db')
    arg_parser.add_argument('-W', '--password',
                            type=str, help='password for connect db')
    arg_parser.add_argument('-j', '--jobs',
                            type=int, help='number of connections',
                            default=4)
    arg_parser.add_argument('-z', '--timezone',
                            type=str, help='timezone for constraints, partitions etc.')
    arg_parser.add_argument('database', help='source database name')
    arg_parser.add_argument('out_dir', help='directory for object files')
    args = arg_parser.parse_args()

    if os.path.exists(args.out_dir) and os.listdir(args.out_dir):
        if args.clean:
            shutil.rmtree(args.out_dir)
        else:
            arg_parser.error('destination directory not empty '
                             '(you can use option --clean)')
    try:
        os.makedirs(args.out_dir, exist_ok=True)
    except Exception:
        arg_parser.error("can not access to directory '%s'" % args.out_dir)

    async def go():
        e = Extractor(args)
        await e.init_pool()
        await e.create_renderer()
        await e.get_directories()
        await asyncio.gather(*(
            e.extract_structure() +
            e.dump_directories(args.out_dir)
        ))
        await e.close_pool()

    if os.name == 'nt':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    loop = asyncio.get_event_loop()
    loop.run_until_complete(go())
