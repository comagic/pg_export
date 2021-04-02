import os
import pg_export.filters as filters


class Item (object):
    template = None
    directory = None
    ext = '.sql'

    def __init__(self, src, renderer):
        self.__dict__.update(src)
        self.renderer = renderer
        if 'schema' in self.__dict__ and 'name' in self.__dict__:
            self.full_name = filters.get_full_name(self.schema, self.name)

    def dump(self, root):
        if not os.path.isdir(os.path.join(root, self.schema, self.directory)):
            os.mkdir(os.path.join(root, self.schema, self.directory))
        self.renderer.render_to_file(
            self.template,
            self.__dict__,
            (root, self.schema, self.directory,
             self.name.replace('"', '') + self.ext))

    def render(self, template):
        return self.renderer.render(template, self.__dict__)
