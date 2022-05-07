from .item import Item


class Schema (Item):
    template = 'out/schema.sql'
    src_query = 'in/schema.sql'
    directory = ''
    is_schema_object = True

    def __init__(self, src, version):
        super(Schema, self).__init__(src, version)
        self.schema = self.name
        self.grants = self.acl_to_grants(self.acl, 'schema', self.name)
