def get_full_name(schema, name):
    if schema in ('public', 'pg_catalog'):
        return name
    return '%s.%s' % (schema, name)


def untype_default(default, column_type):
    return default.replace("'::" + column_type, "'") \
                  .replace("'::public." + column_type[-1], "'") \
                  .replace("'::" + column_type.split('.')[-1], "'")


def ljust(string, width, fillchar):
    return string.ljust(width, fillchar)


def rjust(string, width, fillchar):
    return string.rjust(width, fillchar)


def join_attr(ittr, attribute, delimiter):
    return delimiter.join(i.get(attribute) for i in ittr)


def concat_items(l1, s, l2):
    return ['%s%s%s' % (i1, s, i2) for i1, i2 in zip(l1, l2)]
