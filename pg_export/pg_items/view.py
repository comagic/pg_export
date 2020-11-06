from pg_export.pg_items.item import Item


class View (Item):
    template = 'out/view.sql'
    directory = 'views'

    def __init__(self, src, version):
        super(View, self).__init__(src, version)

        self.query = self.query[:-1]  # drop ";"

        if self.kind == 'm':
            self.directory = 'materializedviews'
