from .item import Item


class Publication (Item):
    template = 'out/publication.sql'
    src_query = 'in/publication.sql'
    directory = 'publications'
    schema = '.'
