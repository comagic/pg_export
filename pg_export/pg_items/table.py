from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Table:
    def __init__(self, src):
            self.src = src
            self.__dict__.update(src)
            self.name = filters.get_full_name(self.table_schema, self.table_name)
            self.primary_key = self.get_constraints('p')
            self.primary_key = self.primary_key and self.primary_key[0] or None
            self.foreign_keys = self.get_constraints('f')
            self.uniques = self.get_constraints('u')
            self.checks = self.get_constraints('c')
            self.exclusions = self.get_constraints('x')
            self.triggers = self.triggers or []

            for fk in self.foreign_keys:
                fk['ftable'] = filters.get_full_name(fk['ftable_schema'], fk['ftable_name'])

            for t in self.triggers:
                t['function'] = filters.get_full_name(t['function_schema'], t['function_name'])
                if t['ftable_name']:
                    t['ftable'] = filters.get_full_name(t['ftable_schema'], t['ftable_name'])

            if self.exclusions:
                print 'WARNING: missed exclusion constraint (%s) on table %s, because not implemented :(' % \
                                                   (','.join([e['name'] for e in self.exclusions]), self.name)

    def get_constraints(self, type_char):
        if self.constraints:
            return sorted([c for c in self.constraints if c['type'] == type_char], key=lambda x:x['name'])
        return []

    def dump(self, root):
       render_to_file('table.sql',
                      self.__dict__,
                      (root, self.table_schema, self.table_name+'.sql'))
