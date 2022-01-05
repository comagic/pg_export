from pg_export.pg_items.item import Item
from pg_export.acl import acl_to_grants


class Server (Item):
    template = 'out/server.sql'
    src_query = 'in/server.sql'
    directory = 'servers'
    schema = '.'

    def __init__(self, src, version):
        super(Server, self).__init__(src, version)
        self.grants = acl_to_grants(self.acl, 'foreign server', self.name)
