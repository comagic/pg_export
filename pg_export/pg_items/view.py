from pg_export.pg_items.item import Item
from pg_export.acl import acl_to_grants


class View (Item):
    template = 'out/view.sql'
    directory = 'views'

    def __init__(self, src, version):
        super(View, self).__init__(src, version)
        self.grants = acl_to_grants(self.acl, 'table', self.full_name)
        self.query = self.query[:-1]  # drop ";"

        if self.kind == 'm':
            self.directory = 'materializedviews'

        for c in self.columns:
            c['grants'] = acl_to_grants(c['acl'],
                                        'column',
                                        self.full_name,
                                        c['name'])
