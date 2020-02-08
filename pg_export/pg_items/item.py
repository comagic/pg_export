import os
from pg_export.render import render, render_to_file
import pg_export.filters as filters

class Item (object):
    template = None
    directory = None
    ext = '.sql'

    def __init__(self, src, version):
            self.__dict__.update(src)
            self.version = version

    def dump(self, root):
        render_to_file(os.path.join(self.version, self.template),
                      self.__dict__,
                      (root, self.schema, self.directory, self.name.replace('"', '') + self.ext))

    def render(self, template):
        return render(os.path.join(self.version, template), self.__dict__)
