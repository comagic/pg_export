import pg_export.filters as filters

class Schema:
    def __init__(self, data):
            self.__dict__.update(data)

            self.name = self.schema_name
