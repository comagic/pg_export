# -*- coding:utf-8 -*-

import os
from jinja2 import Environment, FileSystemLoader
from pg_export.acl import acl_to_grants
from filters import untype_default, ljust, rjust

env = Environment(loader=FileSystemLoader('pg_export/templates'))

env.filters['acl_to_grants'] = acl_to_grants
env.filters['untype_default'] = untype_default
env.filters['ljust'] = ljust
env.filters['rjust'] = rjust

def render(template_name, context):
    try:
        res = env.get_template(template_name).render(context)
    except Exception as e:
        print "Error on render template:", template_name
        raise
    return res

def render_to_file(template_name, context, file_name):
    if isinstance(file_name, tuple):
        file_name = os.path.join(*file_name)
    open(file_name, 'a').write(render(template_name, context).encode('utf8'))
