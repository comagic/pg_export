from pg_export.pg_items.function import Function
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Aggregate (Function):
    template = 'out/aggregate.sql'
    directory = 'aggregates'
    columns = []
    returns_type = None
    returns_type_name = ''
    language = 'sql'
    kind = 'a'
