import os
from pg_export.filters import get_full_name
from pg_export.acl import acl_to_grants


class Item (object):
    INDOPTION_DESC = 0x0001         # src/backend/catalog/pg_index_d.h
    INDOPTION_NULLS_FIRST = 0x0002  # src/backend/catalog/pg_index_d.h
    last_builtin_oid = 16384 - 1    # src/bin/pg_dump/pg_dump.c

    template = None
    src_query = None
    directory = None
    ext = '.sql'
    is_schema_object = False
    acl: list
    schema: str
    name: str

    @classmethod
    def get_src_query(cls, renderer, chunk):
        return renderer.render(
            cls.src_query,
            {'INDOPTION_DESC': cls.INDOPTION_DESC,
             'INDOPTION_NULLS_FIRST': cls.INDOPTION_NULLS_FIRST,
             'last_builtin_oid': cls.last_builtin_oid,
             'chunk': chunk}
        )

    def __init__(self, src, renderer):
        self.__dict__.update(src)
        self.renderer = renderer
        if 'schema' in self.__dict__ and 'name' in self.__dict__:
            self.full_name = get_full_name(self.schema, self.name)

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

    @staticmethod
    def get_full_name(*params):
        return get_full_name(*params)

    @staticmethod
    def acl_to_grants(*params):
        return acl_to_grants(*params)
