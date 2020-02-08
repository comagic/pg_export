from pg_export.pg_items.item import Item
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Function (Item):
    template = 'out/function.sql'
    template_signature = 'out/function_signature.sql'
    directory = 'functions'

    def __init__(self, src, version):
            super(Function, self).__init__(src, version)

            self.full_name = filters.get_full_name(self.schema, self.name)
            self.with_out_args = any(True for a in self.arguments if a['mode'] == 'o')
            self.arguments_as_table = len(self.arguments) > 1 and \
                                      any(True for a in self.arguments
                                               if a['name'])
            self.argument_max_length = max([len('OUT' if a['mode'] == 'o' else
                                                'INOUT' if a['mode'] == 'b' else
                                                'VARIADIC' if a['mode'] == 'VARIADIC' else
                                                a['name'])
                                            for a in self.arguments
                                            if a['name'] and self.arguments_as_table] or [0])
            self.column_max_length = max([len(c['name']) for c in self.columns if c['name']] or [0])
            if self.columns:
                self.returns_type = 'table'
            else:
                self.returns_type = self.returns_type_name.replace('public.', '')
            self.signature = self.render(self.template_signature)
            self.ext = '.' + self.language
            if self.returns_type == 'trigger':
                self.directory = 'triggers'
            if self.kind == 'p':
                self.directory = 'procedures'
