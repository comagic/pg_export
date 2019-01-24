from pg_export.pg_items.item import Item
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Function (Item):
    template = 'out/function.sql'
    directory = 'functions'

    def __init__(self, src, version):
            super(Function, self).__init__(src, version)

            self.full_name = filters.get_full_name(self.schema, self.name)
            self.with_out_args = any(True for a in self.arguments if a['mode'] == 'o')
            self.argument_max_length = max([len(a['name']) for a in self.arguments if a['name']] or [0])
            self.column_max_length = max([len(c['name']) for c in self.columns if c['name']] or [0])
            if self.columns:
                self.returns_type = 'table'
            else:
                self.returns_type = self.returns_type_name.replace('public.', '')
            self.signature = '%s(%s)' % (self.full_name,
                                         ', '.join('%(name)s %(type)s' % a
                                                   for a in self.arguments
                                                   if a['mode'] == 'i'))
            self.ext = '.' + self.language
            if self.returns_type == 'trigger':
                self.directory = 'triggers'
