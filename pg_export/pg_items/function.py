from .item import Item


class Function (Item):
    template = 'out/function.sql'
    src_query = 'in/function.sql'
    template_signature = 'out/_signature.sql'
    directory = 'functions'
    is_schema_object = True

    def __init__(self, src, version):
        super(Function, self).__init__(src, version)

        self.with_out_args = any(True
                                 for a in self.arguments
                                 if a['mode'] == 'o')
        self.arguments_as_table = (len(self.arguments) > 1
                                   and any(True
                                           for a in self.arguments
                                           if a['name']))
        self.argument_max_length = max(
            [len('OUT' if a['mode'] == 'o' else
                 'INOUT' if a['mode'] == 'b' else
                 'VARIADIC' if a['mode'] == 'VARIADIC' else
                 a['name'])
             for a in self.arguments
             if a['name'] and self.arguments_as_table] or [0]
        )
        self.column_max_length = max(
            [len(c['name'])
             for c in self.columns
             if c['name']] or [0]
        )
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
        self.grants = self.acl_to_grants(
            self.acl,
            'procedure' if self.kind == 'p' else 'function',
            self.signature
        )
