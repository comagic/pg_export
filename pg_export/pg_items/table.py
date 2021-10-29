from pg_export.pg_items.item import Item
from pg_export.filters import get_full_name
from pg_export.acl import acl_to_grants


class Table (Item):
    template = 'out/table.sql'
    directory = 'tables'

    def __init__(self, src, version):
        super(Table, self).__init__(src, version)

        self.primary_key = self.get_constraints('p')
        self.primary_key = self.primary_key and self.primary_key[0] or None
        self.foreign_keys = self.get_constraints('f')
        self.uniques = self.get_constraints('u')
        self.checks = self.get_constraints('c')
        self.exclusions = self.get_constraints('x')
        self.triggers = self.triggers or []
        self.grants = acl_to_grants(self.acl, 'table', self.full_name)

        for i in self.inherits:
            i['table'] = get_full_name(i['table_schema'], i['table_name'])

        if self.attach:
            self.attach.update(self.inherits[0])
            self.inherits = []

        for c in self.columns:
            c['grants'] = acl_to_grants(c['acl'],
                                        'column',
                                        self.full_name,
                                        c['name'])

        for fk in self.foreign_keys:
            fk['ftable'] = get_full_name(fk['ftable_schema'],
                                         fk['ftable_name'])

        for t in self.triggers:
            t['function'] = get_full_name(t['function_schema'],
                                          t['function_name'])
            if t['ftable_name']:
                t['ftable'] = get_full_name(t['ftable_schema'],
                                            t['ftable_name'])
        if self.kind == 'f':
            self.directory = 'foreigntables'

        if 'gp_partitions' in self.__dict__:
            self.gp_partitions = self.normalize_gp_partitions(
                                    self.gp_partitions)
            self.gp_subpartition_template = self.normalize_gp_partitions(
                                                self.gp_subpartition_template)

    def get_constraints(self, type_char):
        return self.constraints.get(type_char, [])

    def normalize_gp_partitions(self, partitions):
        res = []
        np = None
        start = None
        for i, p in enumerate(partitions):
            if i < len(partitions) - 1:
                np = partitions[i + 1]

            start = start or p['start']

            if not (np is not None and
                    p['every'] == np['every'] and
                    p['end'] == np['start']):
                res.append({'start': start,
                            'start_inclusive': p['start_inclusive'],
                            'end': p['end'],
                            'end_inclusive': p['end_inclusive'],
                            'every': p['every']})
                start = None
        return res
