from pg_export.pg_items.item import Item


class Sequence (Item):
    template = 'out/sequence.sql'
    directory = 'sequences'
