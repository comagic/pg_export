from pg_export.pg_items.item import Item
import pg_export.filters as filters

class Sequence (Item):
    template = 'out/sequence.sql'
    directory = 'sequences'
