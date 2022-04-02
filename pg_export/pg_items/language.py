from .item import Item


class Language (Item):
    template = 'out/language.sql'
    src_query = 'in/language.sql'
    directory = 'languages'
    schema = '.'
