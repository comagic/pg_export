from pg_export.pg_items.item import Item


class Schema (Item):
    template = 'out/schema.sql'
    directory = '.'

    def __init__(self, src, version):
        super(Schema, self).__init__(src, version)
        self.schema = self.name
