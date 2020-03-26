from pg_export.pg_items.item import Item
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Type (Item):
    template = 'out/type.sql'
    directory = 'types'
