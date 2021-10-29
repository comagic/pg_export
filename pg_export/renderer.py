# -*- coding:utf-8 -*-

import sys
import os
from jinja2 import Environment, FileSystemLoader
from pg_export.filters import (untype_default, ljust,
                               rjust, join_attr, concat_items)


class Renderer:
    def __init__(self, fork, version):
        base_path = os.path.join(os.path.dirname(__file__), 'templates')

        path = [fork + '.'.join(version)]
        for i in reversed(range(1, len(version))):
            path.append(fork + '.'.join(version[:i] + ('x',)))

        path = [os.path.join(base_path, p) for p in path]

        if not any(os.path.isdir(p) for p in path):
            raise Exception('Version not suported: template not found:\n' +
                            '\n'.join(path))

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

    def fix_bug_in_windows(self, path):
        return path.replace('\\', '/')

    def render(self, template_name, context):
        try:
            template_name = self.fix_bug_in_windows(template_name)
            res = self.env.get_template(template_name).render(context)
        except Exception:
            print("Error on render template:", template_name, file=sys.stderr)
            raise
        return res

    def render_to_file(self, template_name, context, file_name):
        if isinstance(file_name, tuple):
            file_name = self.join_path(*file_name)
        if os.path.isfile(file_name):
            open(file_name, 'a', newline='\n').write('\n')
        open(file_name, 'ab').write(
            self.render(template_name, context).encode('utf8'))
