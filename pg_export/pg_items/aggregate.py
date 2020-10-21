from pg_export.pg_items.function import Function


class Aggregate (Function):
    template = 'out/aggregate.sql'
    directory = 'aggregates'
    columns = []
    returns_type = None
    returns_type_name = ''
    language = 'sql'
    kind = 'a'
