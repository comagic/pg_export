from .item import Item


class Operator (Item):
    template = 'out/operator.sql'
    src_query = 'in/operator.sql'
    directory = 'operators'
    is_schema_object = True

    async def dump(self, root):
        self.name = 'operators'
        await super(Operator, self).dump(root)
