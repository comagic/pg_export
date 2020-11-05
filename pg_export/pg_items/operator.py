from pg_export.pg_items.item import Item


class Operator (Item):
    template = 'out/operator.sql'
    directory = 'operators'

    def dump(self, root):
        self.name = 'operators'
        super(Operator, self).dump(root)
