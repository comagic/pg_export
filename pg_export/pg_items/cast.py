from .item import Item


class Cast (Item):
    template = 'out/cast.sql'
    src_query = 'in/cast.sql'
    directory = 'casts'
    schema = '.'

    def __init__(self, src, version):
        super(Cast, self).__init__(src, version)

        self.name = "%s_as_%s" % (self.source, self.target)
