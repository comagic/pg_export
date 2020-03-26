from pg_export.pg_items.item import Item
from pg_export.render import render, render_to_file
import pg_export.filters as filters

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

            for i in self.inherits:
                i['table'] = filters.get_full_name(i['table_schema'], i['table_name'])

            if self.attach:
                self.attach.update(self.inherits[0])
                self.inherits = []

            for fk in self.foreign_keys:
                fk['ftable'] = filters.get_full_name(fk['ftable_schema'], fk['ftable_name'])

            for t in self.triggers:
                t['function'] = filters.get_full_name(t['function_schema'], t['function_name'])
                if t['ftable_name']:
                    t['ftable'] = filters.get_full_name(t['ftable_schema'], t['ftable_name'])

    def get_constraints(self, type_char):
        return self.constraints.get(type_char, [])
