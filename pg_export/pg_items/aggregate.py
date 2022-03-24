from .function import Function


class Aggregate (Function):
    template = 'out/aggregate.sql'
    src_query = 'in/aggregate.sql'
    directory = 'aggregates'
    columns = []
    returns_type = None
    returns_type_name = ''
    language = 'sql'
    kind = 'a'
    is_schema_object = True
