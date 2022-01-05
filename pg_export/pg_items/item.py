import os
import pg_export.filters as filters


class Item (object):
    INDOPTION_DESC = 0x0001         # src/backend/catalog/pg_index_d.h
    INDOPTION_NULLS_FIRST = 0x0002  # src/backend/catalog/pg_index_d.h
    last_builtin_oid = 16384 - 1    # src/bin/pg_dump/pg_dump.c

    template = None
    src_query = None
    directory = None
    ext = '.sql'
    is_schema_object = False

    @classmethod
    def get_src_query(self, renderer, chunk):
        return renderer.render(
                    self.src_query,
                    {'INDOPTION_DESC': self.INDOPTION_DESC,
                     'INDOPTION_NULLS_FIRST': self.INDOPTION_NULLS_FIRST,
                     'last_builtin_oid': self.last_builtin_oid,
                     'chunk': chunk})

    def __init__(self, src, renderer):
        self.__dict__.update(src)
        self.renderer = renderer
        if 'schema' in self.__dict__ and 'name' in self.__dict__:
            self.full_name = filters.get_full_name(self.schema, self.name)

    async def dump(self, root):
        directory = os.path.join(root,
                                 'schemas' if self.is_schema_object else '',
                                 self.schema,
                                 self.directory)
        os.makedirs(directory, exist_ok=True)
        await self.renderer.render_to_file(
            self.template,
            self.__dict__,
            (directory, self.name.replace('"', '') + self.ext))

    def render(self, template):
        return self.renderer.render(template, self.__dict__)
