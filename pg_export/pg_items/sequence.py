from pg_export.pg_items.item import Item
import pg_export.filters as filters

class Sequence (Item):
    template = 'out/sequence.sql'
    directory = 'sequences'

    def __init__(self, src, version):
            super(Sequence, self).__init__(src, version)

            self.full_name = filters.get_full_name(self.schema, self.name)

