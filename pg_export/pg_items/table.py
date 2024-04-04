from .item import Item


class Table (Item):
    template = 'out/table.sql'
    directory = 'tables'
    src_query = 'in/table.sql'
    is_schema_object = True
    columns: list
    attach: dict
    inherits: list
    kind: str
    constraints: dict

    def __init__(self, src, version):
        super(Table, self).__init__(src, version)

        self.primary_key = self.get_constraints('p')
        self.primary_key = self.primary_key and self.primary_key[0] or None
        self.foreign_keys = self.get_constraints('f')
        self.uniques = self.get_constraints('u')
        self.checks = self.get_constraints('c')
        self.exclusions = self.get_constraints('x')
        self.triggers = self.triggers or []
        self.grants = self.acl_to_grants(self.acl, 'table', self.full_name)

        for i in self.inherits:
            i['table'] = self.get_full_name(i['table_schema'], i['table_name'])

        if self.attach:
            self.attach.update(self.inherits[0])
            self.inherits = []

        for c in self.columns:
            c['grants'] = self.acl_to_grants(c['acl'],
                                             'column',
                                             self.full_name,
                                             c['name'])

        for fk in self.foreign_keys:
            fk['ftable'] = self.get_full_name(fk['ftable_schema'],
                                              fk['ftable_name'])

        for t in self.triggers:
            t['function'] = self.get_full_name(t['function_schema'],
                                               t['function_name'])
            if t['ftable_name']:
                t['ftable'] = self.get_full_name(t['ftable_schema'],
                                                 t['ftable_name'])
        if self.kind == 'f':
            self.directory = 'foreigntables'

        if 'gp_partitions' in self.__dict__:
            self.gp_partitions = self.normalize_gp_partitions(
                self.gp_partitions
            )
            self.gp_subpartition_template = self.normalize_gp_partitions(
                self.gp_subpartition_template
            )

    def get_constraints(self, type_char):
        return self.constraints.get(type_char, [])

    @staticmethod
    def normalize_gp_partitions(partitions):
        res = []
        np = None
        start = None
        for i, p in enumerate(partitions):
            if i < len(partitions) - 1:
                np = partitions[i + 1]

            start = start or p['start']

            if not (np is not None
                    and p['every'] == np['every']
                    and p['end'] == np['start']):
                res.append({'start': start,
                            'start_inclusive': p['start_inclusive'],
                            'end': p['end'],
                            'end_inclusive': p['end_inclusive'],
                            'every': p['every']})
                start = None
        return res
