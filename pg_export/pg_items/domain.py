from .item import Item


class Domain (Item):
    template = 'out/domain.sql'
    src_query = 'in/domain.sql'
    directory = 'domains'
    is_schema_object = True

    def __init__(self, src, version):
        super().__init__(src, version)
        self.grants = self.acl_to_grants(self.acl, 'domain', self.full_name)
