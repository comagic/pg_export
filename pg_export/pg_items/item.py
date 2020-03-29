import os
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Item (object):
    template = None
    directory = None
    ext = '.sql'

    def __init__(self, src, pg_version):
            self.__dict__.update(src)
            self.pg_version = pg_version
            if 'schema' in self.__dict__ and 'name' in self.__dict__:
                self.full_name = filters.get_full_name(self.schema, self.name)

    def dump(self, root):
        render_to_file(os.path.join(self.pg_version, self.template),
                      self.__dict__,
                      (root, self.schema, self.directory, self.name.replace('"', '') + self.ext))

    def render(self, template):
        return render(os.path.join(self.pg_version, template), self.__dict__)
