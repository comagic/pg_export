from pg_export.pg_items.item import Item


class View (Item):
    template = 'out/view.sql'
    directory = 'views'
