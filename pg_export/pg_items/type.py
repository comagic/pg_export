from .item import Item


class Type (Item):
    template = 'out/type.sql'
    src_query = 'in/type.sql'
    directory = 'types'
    is_schema_object = True

    def __init__(self, src, version):
        super(Type, self).__init__(src, version)
        self.grants = self.acl_to_grants(self.acl, 'type', self.full_name)
