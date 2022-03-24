from .item import Item


class Sequence (Item):
    template = 'out/sequence.sql'
    src_query = 'in/sequence.sql'
    directory = 'sequences'
    is_schema_object = True

    def __init__(self, src, version):
        super(Sequence, self).__init__(src, version)
        self.grants = self.acl_to_grants(self.acl, 'sequence', self.full_name)
