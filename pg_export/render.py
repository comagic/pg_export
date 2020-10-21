# -*- coding:utf-8 -*-

import sys
import os
from jinja2 import Environment, FileSystemLoader
from pg_export.acl import acl_to_grants
from pg_export.filters import (untype_default, ljust,
                               rjust, join_attr, concat_items)

env = Environment(loader=FileSystemLoader('pg_export/templates'))

env.filters['acl_to_grants'] = acl_to_grants
env.filters['untype_default'] = untype_default
env.filters['ljust'] = ljust
env.filters['rjust'] = rjust
env.filters['join_attr'] = join_attr
env.filters['concat_items'] = concat_items


def render(template_name, context):
    try:
        res = env.get_template(template_name).render(context)
    except Exception:
        print("Error on render template:", template_name, file=sys.stderr)
        raise
    return res


def render_to_file(template_name, context, file_name):
    if isinstance(file_name, tuple):
        file_name = os.path.join(*file_name)
    open(file_name, 'ab').write(render(template_name, context).encode('utf8'))
