from pg_export.pg_items.item import Item


class Language (Item):
    template = 'out/language.sql'
    directory = 'languages'
    schema = '.'
