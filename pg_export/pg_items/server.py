from pg_export.pg_items.item import Item


class Server (Item):
    template = 'out/server.sql'
    directory = 'servers'
    schema = '.'
