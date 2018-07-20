from pg_export.pg_items.item import Item
import pg_export.filters as filters

class Schema (Item):
    template = 'out/schema.sql'
    directory = '.'

