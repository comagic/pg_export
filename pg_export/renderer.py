# -*- coding:utf-8 -*-

import sys
import os
import aiofiles
import asyncio
from jinja2 import Environment, FileSystemLoader
from .filters import untype_default, ljust, rjust, join_attr, concat_items


MAX_OPEN_FILE = 100


class Renderer:
    def __init__(self, fork, version):
        self.open_file_limiter = asyncio.Semaphore(MAX_OPEN_FILE)
        base_path = os.path.join(os.path.dirname(__file__), 'templates')
        path = [fork + '.'.join(version)]
        for i in reversed(range(1, len(version))):
            path.append(fork + '.'.join(version[:i] + ('x',)))
        path = [os.path.join(base_path, p) for p in path]
        if not any(os.path.isdir(p) for p in path):
            raise Exception('Version not supported: template not found:\n' + '\n'.join(path))
        path.append(os.path.join(base_path, 'base'))

        self.env = Environment(
            loader=FileSystemLoader([
                self.join_path(os.path.dirname(__file__), 'templates', p)
                for p in path]))

        self.env.filters['untype_default'] = untype_default
        self.env.filters['ljust'] = ljust
        self.env.filters['rjust'] = rjust
        self.env.filters['join_attr'] = join_attr
        self.env.filters['concat_items'] = concat_items

    def join_path(self, *items):
        return self.fix_bug_in_windows(os.path.join(*items))

    @staticmethod
    def fix_bug_in_windows(path):
        return path.replace('\\', '/')

    def render(self, template_name, context):
        try:
            template_name = self.fix_bug_in_windows(template_name)
            res = self.env.get_template(template_name).render(context)
        except Exception:
            print("Error on render template:", template_name, file=sys.stderr)
            raise
        return res

    async def render_to_file(self, template_name, context, file_name):
        if isinstance(file_name, tuple):
            file_name = self.join_path(*file_name)
        if os.path.isfile(file_name):
            open(file_name, 'a', newline='\n').write('\n')
        async with self.open_file_limiter, aiofiles.open(file_name, 'ab') as f:
            await f.write(self.render(template_name, context).encode('utf8'))
