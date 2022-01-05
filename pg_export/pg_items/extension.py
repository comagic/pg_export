from pg_export.pg_items.item import Item


class Extension (Item):
    template = 'out/extension.sql'
    src_query = 'in/extension.sql'
    directory = 'extensions'
    schema = '.'
