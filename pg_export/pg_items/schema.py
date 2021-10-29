from pg_export.pg_items.item import Item
from pg_export.acl import acl_to_grants


class Schema (Item):
    template = 'out/schema.sql'
    directory = ''

    def __init__(self, src, version):
        super(Schema, self).__init__(src, version)
        self.schema = self.name
        self.grants = acl_to_grants(self.acl, 'schema', self.name)
