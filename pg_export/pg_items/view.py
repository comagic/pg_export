from .item import Item


class View (Item):
    template = 'out/view.sql'
    directory = 'views'
    src_query = 'in/view.sql'
    is_schema_object = True

    def __init__(self, src, version):
        super(View, self).__init__(src, version)
        self.grants = self.acl_to_grants(self.acl, 'table', self.full_name)
        self.query = self.query[:-1]  # drop ";"

        if self.kind == 'm':
            self.directory = 'materializedviews'

        for c in self.columns:
            c['grants'] = self.acl_to_grants(c['acl'],
                                             'column',
                                             self.full_name,
                                             c['name'])
