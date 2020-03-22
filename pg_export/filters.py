def get_full_name(schema, name):
    if schema in ('public', 'pg_catalog'):
        return name
    return '%s.%s' % (schema, name)

def untype_default(default, column_type):
    return default.replace('::'+column_type, '').replace('::'+column_type.split('.')[-1], '')

def ljust(s, w, c):
  return s.ljust(w, c)

def rjust(s, w, c):
  return s.rjust(w, c)

def join_attr(l, a, s):
  return s.join(i.get(a) for i in l)

def concat_items(l1, s, l2):
  return ['%s%s%s' % (i1, s, i2) for i1, i2 in zip(l1, l2)]
