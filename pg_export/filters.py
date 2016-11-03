def get_full_name(schema, name):
    if schema in ('public', 'pg_catalog'):
        return name
    return '%s.%s' % (schema, name)

def untype_default(default, column_type):
	return default.replace('::'+column_type, '').replace('::'+column_type.split('.')[-1], '')
