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
        self.triggers = self.triggers or []

        if self.kind == 'm':
            self.directory = 'materializedviews'

        for c in self.columns:
            c['grants'] = self.acl_to_grants(c['acl'],
                                             'column',
                                             self.full_name,
                                             c['name'])

        for t in self.triggers:
            t['function'] = self.get_full_name(t['function_schema'],
                                               t['function_name'])
            if t['ftable_name']:
                t['ftable'] = self.get_full_name(t['ftable_schema'],
                                                 t['ftable_name'])
