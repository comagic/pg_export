import re
import os

WORDS_TO_LOWER = ['CREATE', 'ALTER', 'TABLE', 'FUNCTION', 'INDEX', ' CAST ', ' CASCADE',
                  'GRANT', 'REVOKE', ' TO ', ' FROM ', ' ALL ', 'PUBLIC', 'DEFERRABLE', 'INITIALLY DEFERRED',
                  'TRIGGER', 'AFTER', 'BEFORE', 'EACH ROW', 'EXECUTE PROCEDURE', 'LANGUAGE', 'AS',
                  'DEFAULT', 'NOT NULL', 'USING', 'SELECT', 'INSERT ', 'UPDATE ', 'DELETE ',
                  'UNIQUE', 'CONSTRAINT', 'ONLY', 'REFERENCES', 'FOREIGN KEY', 'PRIMARY KEY',
                  ' AND ', ' OR ', ' ON ', ' ADD ', ' FOR ', ' IS ', 'NULL::', ' WITH ',
                  'COMMENT', 'COLUMN', 'IMPLICIT', 'DOMAIN', 'UNLOGGED']


class PgObject(object):
    children = []
    body_sql = None  # if defined, body will replace to sql result

    def __init__(self, parser, data):
        self.owned_by = None
        self.parser = parser
        self.name, self.type, self.schema, self.owner = \
            self.match('(.+); Type: (.+); Schema: (.+); Owner: *(.*)', data.split('\n')[0])

        # For some types pg_dump adds parent table name
        # before entity name, for trigger, for example,
        # the string will look like this:
        #
        # Name: price bi_price; Type: TRIGGER; Schema: crm; Owner: postgres
        #
        # So we should take only last part of a name - after a last space
        if self.type in ('DEFAULT', 'CONSTRAINT', 'FK CONSTRAINT', 'TRIGGER', 'RULE'):
            self.name = ' '.join(self.name.split(' ')[1:])

        self.schema = self.parser.schemas.get(self.schema)
        self.acl = []
        self.comments = []
        self.data = '\n'.join(data.split('\n')[3:])
        self.file_name = self.name
        self.file_ext = 'sql'

        for c in self.children:
            setattr(self, c, {})
        self.add_to_parent()
        self.replace_body_by_sql()
        self.add_schema_name()
        self.special()
        self.one_oel()

    def replace_body_by_sql(self):
        if self.body_sql:
            self.data = self.parser.sql_execute(self.body_sql, **self.__dict__)[0]['body'].replace('\r', '')

    def add_to_parent(self):
        pass

    def add_schema_name(self):
        pass

    def special(self):
        pass

    def match(self, pattern, data=None, **kwargs):
        try:
            return re.match(pattern, data or self.data, **kwargs).groups()
        except AttributeError:
            raise Exception('(class: %s) pattern "%s" doesnt like on "%s"' % (self.__class__.__name__, pattern, data or self.data))

    def del_args_name(self, fname):# f(a integer, b text) -> f(integer, text)
        name, args = re.match('(.*)\((.*)\)', fname).groups()
        args = args.split(', OUT')[0]
        args = ', '.join([' '.join(a.split(' ')[1:]) if ' ' in a and a not in ('timestamp with time zone', 'timestamp without time zone') else a for a in args.split(', ')])
        return "%s(%s)" % (name, args)

    def dump(self, root_dir):
        self.lower_keywords()

        open(os.path.join(root_dir, '%s.%s' % (self.file_name, self.file_ext)), 'a').write(self.data)
        for o in self.acl + self.comments:
            o.dump(root_dir)

    def patch_data(self, pattern, replace):
        self.data = self.data.replace(pattern, replace)

    def patch_data_re(self, pattern, replace, **kwargs):
        try:
            self.data = re.sub(pattern, replace, self.data, **kwargs)
        except re.error:
            raise Exception('invalid regexp expression(pattern: "%s", replace: "%s")' % (pattern, replace))

    def one_oel(self, is_need_eol=True):
        self.data = self.data.strip()
        if is_need_eol:
            self.data += '\n\n'

    def lower_keywords(self):
        for w in WORDS_TO_LOWER:
            self.patch_data(w, w.lower())

    def del_public(self, s):
        return s.replace('public.', '')

    def dequote(self, s):
        return s.replace('"', '')

class PgGlobalObject(PgObject):
    def add_to_parent(self):
        self.schema = self.parser.schemas['public']
        getattr(self.schema, self.__class__.__name__.lower() + 's')[self.name] = self


class PgObjectOfSchema(PgObject):
    def add_to_parent(self):
        getattr(self.schema, self.__class__.__name__.lower() + 's')[self.name] = self

    def get_full_name(self):
        return '%s.%s' % (self.schema.name, self.name)

    def add_schema_name(self):
        before_name = 'CREATE ' + self.__class__.__name__.upper()
        name = self.name.split('(')[0]
        if self.schema.name != 'public':
            self.patch_data_re('%s %s' % (before_name, name),
                               '%s %s.%s' % (before_name, self.schema.name, name))
            self.patch_data_re('%s "%s"' % (before_name, name),
                               '%s %s.%s' % (before_name, self.schema.name, name))

    def dump(self, root_dir):
        super(PgObjectOfSchema, self).dump(root_dir)

        for c_name, c in [(c_name, getattr(self, c_name)) for c_name in self.children]:
            for e in sorted(c.values(), key=lambda x: x.data):
                e.dump(root_dir)


class PgObjectOfTable(PgObject):
    def add_to_parent(self):
        self.table_name = self.match(self.table_pattern, flags=re.M)[0]
        self.table = self.schema.tables.get(self.table_name) or \
                     self.schema.tables.get(self.dequote(self.table_name)) or \
                     self.schema.views.get(self.table_name) or \
                     self.schema.views.get(self.dequote(self.table_name)) or \
                     self.schema.materializedviews.get(self.table_name) or \
                     self.schema.materializedviews.get(self.dequote(self.table_name))
        if not self.table:
            raise Exception('Cant find table or view "%s"' % self.table_name)
        getattr(self.table, self.__class__.__name__.lower() + 's')[self.name] = self
        self.file_name = self.table.file_name
        self.file_ext = self.table.file_ext

    def add_schema_name(self):
        if self.table.name in ("group", "user", "position"):
            self.patch_data('"%s"' % self.table.name, '%s' % self.table.name)

        if self.schema.name != 'public':
            self.patch_data_re(' %s %s' % (self.before_name, self.table.name),
                               ' %s %s.%s' % (self.before_name, self.schema.name, self.table.name))


class Acl(PgObject):
    def add_to_parent(self):
        self.ptype = self.match('.* ON (\w+) .*')[0]
        self.parent = None
        if self.ptype == 'SCHEMA':
            self.parent = self.parser.schemas[self.name]
        elif self.ptype == 'FUNCTION':
            self.parent = self.schema.functions[self.name]
        elif self.ptype == 'TABLE':
            self.parent = (self.schema.tables.get(self.name) or self.schema.views.get(self.name) or self.schema.foreigntables.get(self.name))
        elif self.ptype == 'SEQUENCE':
            self.parent = self.schema.sequences[self.name]
        elif self.ptype == 'FOREIGN':
            self.parent = self.parser.schemas.get('public').servers[self.name]

        if self.parent:
            self.parent.acl.append(self)
            self.file_name = self.parent.file_name
            self.file_ext = self.parent.file_ext
        else:
            print "WARNING: can't find %s(%s) for acl" % (self.ptype, self.name)

    def special(self):
        self.patch_data_re('REVOKE ALL ON .* FROM postgres;\nGRANT ALL ON .* TO postgres;\n', '')

    def add_schema_name(self):
        if self.schema and self.schema.name != 'public':
            if self.ptype == 'FUNCTION':
                name = self.match('.* ON FUNCTION (.*) (FROM|TO) .*')[0]
                self.patch_data(name, self.parent.semantic)
            else:
                 self.patch_data(self.ptype+' "', self.ptype+' ') # for keyword, ON "user" FROM|TO
                 self.patch_data('" FROM', ' FROM')
                 self.patch_data('" TO', ' TO')
                 self.patch_data(' ON %s %s' % (self.ptype, self.name),
                                 ' ON %s %s.%s' % (self.ptype, self.schema.name, self.name))

    def dump(self, root_dir):
        self.lower_keywords()

        tmp = [a for a in self.data.split("\n") if a != ""]
        self.data = "\n".join(sorted([a for a in tmp if "revoke" in a]) + \
                              sorted([a for a in tmp if "revoke" not in a])) + "\n\n"

        open(os.path.join(root_dir, '%s.%s' % (self.file_name, self.file_ext)), 'a').write(self.data)

class Comment(PgObject):
    def add_to_parent(self):
        tn = self.name.split(' ')
        self.name = ' '.join(tn[1:]).replace('"', '')
        self.ptype = tn[0]
        self.parent = None
        if self.ptype == 'SCHEMA':
            self.parent = self.parser.schemas[self.name]
        elif self.ptype == 'FUNCTION':
            self.name = self.del_args_name(self.name)
            self.parent = self.schema.functions[self.name]
        elif self.ptype == 'AGGREGATE':
            self.parent = self.schema.aggregates[self.name]
        elif self.ptype == 'TABLE':
            self.parent = self.schema.tables[self.name]
        elif self.ptype == 'VIEW':
            self.parent = self.schema.views[self.name]
        elif self.ptype == 'COLUMN':
            self.parent = self.schema.tables[self.name.split('.')[0]]
        elif self.ptype == 'SEQUENCE':
            self.parent = self.schema.sequences[self.name]
        elif self.ptype == 'EXTENSION':
            self.parent = self.parser.schemas['public'].extensions[self.name]
        elif self.ptype == 'CONSTRAINT':
            self.parent = self.schema.tables[self.match('.* ON (.*)', self.name)[0]]
        elif self.ptype == 'MATERIALIZED VIEW':
            self.parent = self.schema.materializedviews[self.name]
        if self.parent:
            self.parent.comments.append(self)
            self.file_name = self.parent.file_name
            self.file_ext = self.parent.file_ext
        else:
            print "WARNING: can't find %s(%s) for comment" % (self.ptype, self.name)

    def quote_literals(self, s, lits):
        for l in lits:
            s = s.replace(l, '\\'+l)
        return s

    def add_schema_name(self):
        if self.schema and self.schema.name != 'public':
            if self.ptype == 'FUNCTION':
                name = self.match('.* ON FUNCTION (.*) IS .*')[0]
                self.patch_data(name, self.parent.semantic)
            else:
                if ' ON ' in self.name:
                    name = self.name.split(' ON ')[1]
                    self.patch_data(' ON %s' % (name),
                                    ' ON %s.%s' % (self.schema.name, name))
                else:
                    self.patch_data(' ON %s %s' % (self.ptype, self.name),
                                    ' ON %s %s.%s' % (self.ptype, self.schema.name, self.name))
                    self.patch_data(' ON %s "%s"' % (self.ptype, self.name),
                                    ' ON %s %s.%s' % (self.ptype, self.schema.name, self.name))
                    if '.' in self.name:
                        self.patch_data(' ON %s "%s".%s' % tuple([self.ptype] + self.name.split('.')),
                                        ' ON %s %s.%s' % (self.ptype, self.schema.name, self.name))


class Schema(PgObject):
    children = ['aggregates', 'tables', 'functions', 'types', 'domains', 'operators',
                'foreigntables', 'views', 'sequences', 'casts', 'languages',
                'extensions', 'triggers', 'servers', 'usermappings', 'materializedviews']

    def add_to_parent(self):
        self.parser.schemas[self.name] = self

    def dump(self, root_dir):
        d = os.path.join(root_dir, self.name)
        os.mkdir(d)
        super(Schema, self).dump(d)

        for c_name, c in [(c_name, getattr(self, c_name)) for c_name in self.children]:
            if c:
                dd = os.path.join(d, c_name)
                os.mkdir(dd)
                for e in c.values():
                    e.dump(dd)

    def post_processing(self):
        for t in self.tables.values():
            t.make_serial()

        for fn, f in self.functions.items():
            if f.is_trigger:
                del self.functions[fn]
                self.triggers[fn] = f

class Aggregate(PgObjectOfSchema):
    def special(self):
        self.file_name = self.name.split('(')[0]

class Function(PgObjectOfSchema):
    body_sql = 'select pg_get_functiondef(%(oid)s) as body'

    def special(self):
        self.file_ext = self.match('.*\n.*\n.* LANGUAGE (\w+).*', flags=re.M)[0]
        self.file_name = self.name.split('(')[0]

        body = self.data.split('\n')
        name, args = self.match('CREATE OR REPLACE FUNCTION ([^(]*)\((.*)\)', body.pop(0))
        rettype = self.match(' RETURNS (.*)', body.pop(0))[0]
        self.semantic = '%s(%s)' % (name, self.get_identity_arguments())

        self.is_trigger = (rettype == 'trigger')

        if self.file_ext in ('c', 'internal'):
            self.data += ';'
            return

        name = self.del_public(name)
        if rettype.startswith('TABLE'):
            rettype = 'table(%s)' % self.pretty_args(self.match('TABLE\((.*)\)', rettype)[0])
        signature = 'create or replace\nfunction %s(%s) returns %s as $$' % (name, self.pretty_args(args), rettype)

        lang = body.pop(0)
        if 'AS $$' not in body[0]:
            lang += body.pop(0) #strict sequrity definer

        body[0] = body[0].replace('AS $$', '')
        if body[0] == '':
            body.pop(0)
        if body[-1] != '$$': #end;$$
            body[-1] = body[-1].replace('$$', '\n$$')
        body[-1] += ' %s;' % lang.lower().strip()
        self.data = '\n'.join([signature] + body)

        dep_table = self.parser.sql_execute('''
            select n.nspname, c.relname
              from pg_depend d
              join pg_type t on t.oid = d.refobjid
              join pg_class c on c.oid = t.typrelid
              join pg_namespace n on n.oid = relnamespace
            where d.objid = %(oid)s and relkind='r' and d.deptype = 'n' ''', oid=self.oid)
        if dep_table:
            self.data += '\n--depend on table %(nspname)s.%(relname)s' % dep_table[0]

    def add_schema_name(self):
        pass

    def pretty_args(self, args_str):
        args = args_str.split(', ')
        if len(args) == 1 or min([len(a.split()) for a in args]) <= 1:
            return args_str
        max_len_name = max([len(a.split()[0]) for a in args])
        return '\n%s\n' % ',\n'.join(['  %s %s' % (a.split(' ')[0].ljust(max_len_name),  ' '.join(a.split(' ')[1:])) for a in args])

    def replace_body_by_sql(self):
        name, args, rettype = self.match('CREATE FUNCTION ([^(]*)\((.*)\) RETURNS (.*)')
        args = ', '.join([a.replace(' ', '%').replace('::', '%') for a in args.split(', ')])
        self.oid = self.parser.sql_execute('''
          select p.oid::int
            from pg_proc p
            join pg_namespace n on pronamespace = n.oid
           where nspname = %(schema)s and proname = %(name)s and pg_get_function_arguments(p.oid) like %(args)s
          ''', schema=self.schema.name, name=self.dequote(name), args=self.del_public(args))[0]['oid']
        super(PgObjectOfSchema, self).replace_body_by_sql()
        self.data = self.data[:-1] # -eol
        self.patch_data('$function$', '$$')

    def get_identity_arguments(self):
        return self.parser.sql_execute('select pg_get_function_identity_arguments(%(oid)s) as args', oid=self.oid)[0]['args']

class Operator(PgObjectOfSchema):
    def special(self):
        self.file_name = 'operators'

    def add_to_parent(self):
        for i in xrange(1, 1000):
            if self.name + str(i) not in self.schema.operators:
                self.name += str(i)
                break
        super(Operator, self).add_to_parent()


class Sequence(PgObjectOfSchema):
    pass

class Type(PgObjectOfSchema):
    def replace_body_by_sql(self):
        dep_types = []
        for i in self.parser.sql_execute('''
            select dn.nspname, dt.typname
              from pg_type t
              join pg_namespace n on n.oid = t.typnamespace
              join pg_attribute a on attrelid = t.typrelid
              join pg_type dt on dt.oid = a.atttypid
              join pg_namespace dn on dn.oid = dt.typnamespace
             where t.typname = %(name)s and n.nspname = %(schema)s
                   and dn.nspname <> 'pg_catalog'
             order by 1, 2''', schema=self.schema.name, name=self.name):
            if i['nspname'] != 'public':
                self.patch_data(' %(typname)s' % i, ' %(nspname)s.%(typname)s' % i)
            self.patch_data(' public.', ' ')
            dep_types.append('%(nspname)s.%(typname)s' % i)
        self.data += '\n'.join( '--depend on type %s' % j for j in set(dep_types))

class Domain(Type):
    pass

class View(PgObjectOfSchema):
    children = ['rules', 'defaults', 'triggers', 'indexs']

    def replace_body_by_sql(self):
        body = self.parser.sql_execute("select pg_get_viewdef(%(schema)s||'.\"'||%(name)s||'\"') as body", schema=self.schema.name, name=self.name)[0]['body']
        self.data = self.data.split('\n')[0] + '\n' + body + '\n'
        self.data += '\n'.join( '--depend on view %s' % j
                       for j in set([i['dep_view']
                           for i in self.parser.sql_execute('''
            select distinct dn.nspname ||'.'|| dc.relname as dep_view
              from pg_class c
              join pg_namespace n on n.oid = c.relnamespace
              join pg_rewrite r on ev_class = c.oid
              join pg_depend d on d.objid = r.oid
              join pg_class dc on dc.oid = d.refobjid and dc.oid <> c.oid
              join pg_namespace dn on dn.oid = dc.relnamespace
             where n.nspname = %(schema)s and c.relname = %(name)s and dc.relkind = 'v'
            ''', schema=self.schema.name, name=self.name)]))

class MaterializedView(View):
    pass


class Table(PgObjectOfSchema):
    children = ['sequences', 'sequenceownedbys', 'defaults',
                'fkconstraints', 'constraints', 'triggers', 'indexs', 'rules']

    def special(self):
        dep_table = None
        unpublic_types = {}
        self.oid = self.parser.sql_execute('''
            select c.oid
              from pg_class c
              join pg_namespace n on n.oid = c.relnamespace
             where n.nspname = %(schema)s and c.relname = %(table)s''',
                               schema=self.schema.name, table=self.name)[0]['oid']
        self.one_oel(False)
        body = self.data.split('\n')
        self.column_types = {}

        for i, s in enumerate(body):
            if s.startswith('    CONSTRAINT'):
                for typ, udt in unpublic_types.items():
                    if udt not in s:
                        s = s.replace(typ, udt)

            elif s.startswith('    '): # columns
                cname, ctype = self.match('    ([^ ]*) (["\w.\[\]]*).*', s)
                self.column_types[cname] = ctype
                if ctype not in self.parser.pg_types:
                    if ctype.startswith('public.'):
                        s = self.del_public(s)
                    else:
                        d = self.get_column_def(self.schema.name, self.name, self.dequote(cname))
                        if d['udt_schema'] == 'pg_catalog':
                            print 'WARNING: Unknown system type:', ctype
                        elif d['udt_schema'] == 'public':
                            s = s.replace('    %s %s' % (cname, ctype), '    %s %s' % (cname, d['udt_name']))
                            s = s.replace('::%s' % ctype, '')
                        else:
                            unpublic_types[d['udt_name']] = d['udt']
                            s = s.replace('    %s %s' % (cname, ctype), '    %s %s' % (cname, d['udt']))
                            s = s.replace('::%s' % ctype, '')
                if 'DEFAULT nextval' in s:
                    cdefault = self.match(".* DEFAULT ([^)]*\)).*", s)[0]
                    d = self.get_column_def(self.schema.name, self.name, self.dequote(cname))
                    if cdefault != d['column_default']:
                        s = s.replace(cdefault, d['column_default'].replace('::regclass', ''))
                elif 'DEFAULT' in s:
                    t = s.split(' NOT NULL')[0]
                    t = t[:-1] if t[-1] == ',' else t
                    cdefault = self.match(".* DEFAULT (.*)", t)[0]
                    d = self.get_column_def(self.schema.name, self.name, self.dequote(cname))
                    if cdefault != d['column_default']:
                        s = s.replace(cdefault, d['column_default'])
                    if d['data_type'] == 'USER-DEFINED':
                        s = s.replace(self.del_public('::%s.%s' % (d['udt_schema'], d['udt_name'])), '')

            elif s.startswith('INHERITS '):
                itable = self.match('INHERITS \((.*)\)', s)[0]
                dep_table = self.parser.sql_execute('''
                    select n.nspname ||'.'|| c.relname as dep_table
                      from pg_inherits i
                      join pg_class c on c.oid = i.inhparent
                      join pg_namespace n on n.oid = c.relnamespace
                     where i.inhrelid = %(oid)s''', oid=self.oid)[0]['dep_table']
                dtable = self.del_public(dep_table)
                if dtable != itable:
                    s = s.replace(itable, dtable)

            elif s.startswith('ALTER TABLE ONLY'):
                s = s.replace('ALTER TABLE ONLY %s' % self.name,
                              'ALTER TABLE ONLY %s' % self.get_full_name())
            body[i] = s
        #end for
        dep_table = [dep_table] if dep_table else []
        body.extend( '--depend on table %s' % j
                       for j in set([i['dep_table']
                           for i in self.parser.sql_execute('''
            select n.nspname ||'.'|| c.relname as dep_table
              from pg_attrdef a
              join pg_depend d on d.objid = a.oid
              join pg_depend d2 on d2.objid = d.refobjid
              join pg_class c on c.oid = d2.refobjid
              join pg_namespace n on n.oid = c.relnamespace
             where a.adrelid = %(oid)s and d.deptype = 'n' and d2.deptype = 'a' and
                   d.classid in (select cd.oid from pg_class cd where cd.relname = 'pg_attrdef') and
                   d2.classid in (select cd.oid from pg_class cd where cd.relname = 'pg_class') and
                   d.refobjid <> a.adrelid and d2.refobjid <> a.adrelid''', oid=self.oid)] + dep_table))
        self.data = '\n'.join(body)

    def add_schema_name(self):
        if self.name in ("group", "user", "position"):
            self.patch_data('"%s"' % self.name, '%s' % self.name)

        if self.schema.name != 'public':
            if 'UNLOGGED' in self.data:
                self.patch_data('CREATE UNLOGGED TABLE %s (' % self.name, 'CREATE UNLOGGED TABLE %s (' % self.get_full_name())
            else:
                self.patch_data('CREATE TABLE %s (' % self.name, 'CREATE TABLE %s (' % self.get_full_name())

    def make_serial(self):
        for sob in self.sequenceownedbys.values():
            if sob.column in self.defaults and 'nextval' in self.defaults[sob.column].value and '%s_%s_seq' % (self.name, sob.column) in self.defaults[sob.column].value:
                col_str = self.match('(.*\n)+(    %s .*)\n' % sob.column, flags=re.M)[-1:][0]
                self.patch_data(col_str, '    %s %s,' % (sob.column, 'bigserial' if self.column_types[sob.column] == 'bigint' else 'serial'))
                del self.defaults[sob.column]
                del self.schema.sequences[sob.name]
                del self.sequenceownedbys[sob.name]
                del self.sequences[sob.name]
            else:
                self.sequences[sob.name].file_name = sob.name
                del self.sequences[sob.name]
        self.patch_data(' serial,\n)', ' serial\n)')

    def get_column_def(self, schema, table, column):
        res = self.parser.sql_execute('''
            select *, (udt_schema||'.'||udt_name)::regtype as udt
              from information_schema.columns
             where table_schema = %(schema)s and table_name = %(table)s and column_name = %(column)s''',
               schema=schema, table=table, column=self.dequote(column))
        if not res:
            raise Exception('Cant find column definition: %s.%s.%s' % (schema, table, column))
        return res[0]


class ForeignTable(Table):
    def add_schema_name(self):
        if self.schema.name != 'public':
            self.patch_data('CREATE FOREIGN TABLE %s (' % self.name, 'CREATE FOREIGN TABLE %s (' % self.get_full_name())


class Default(PgObjectOfTable):
    table_pattern = 'ALTER TABLE ONLY (.*) ALTER'
    before_name = 'ONLY'

    def special(self):
        self.column, self.value = self.match('.* ALTER COLUMN (.*) SET DEFAULT (.*);')
        if 'nextval' in self.value:
            d = self.table.get_column_def(self.schema.name, self.table.name, self.column)
            if self.value != d['column_default']:
                self.patch_data(self.value, d['column_default'])
        self.patch_data_re('::[\w.]*', '')

#ALTER TABLE ONLY isdn_port ALTER COLUMN id SET DEFAULT nextval('port_id_seq'::regclass);

class FkConstraint(PgObjectOfTable):
    table_pattern = 'ALTER TABLE ONLY (.*)\n.*'
    before_name = 'ONLY'

    def add_schema_name(self):
        super(FkConstraint, self).add_schema_name()
        ftable_name = self.match('.*\n.*REFERENCES (.*)\(', flags=re.M)
        table_name = self.parser.sql_execute('''
            select rn.nspname ||'.'|| r.relname as table_name
              from pg_constraint
              join pg_namespace cn on cn.oid = connamespace
              join pg_class sr on sr.oid = conrelid
              join pg_class r on r.oid = confrelid
              join pg_namespace rn on rn.oid = r.relnamespace
             where contype = 'f' and cn.nspname = %(schema)s and conname = %(name)s
                   and sr.relname = %(table)s ''',
            schema=self.schema.name, name=self.name, table=self.table.name )[0]['table_name']
        table_name = self.del_public(table_name)
        if ftable_name != table_name:
            self.patch_data('REFERENCES %s(' % ftable_name, 'REFERENCES %s(' % table_name)


class Constraint(PgObjectOfTable):
    table_pattern = 'ALTER TABLE ONLY (.*)\n.*'
    before_name = 'ONLY'

class Index(PgObjectOfTable):
    table_pattern = '.*ON (.*) USING.*'
    before_name = 'ON'

    def replace_body_by_sql(self):
        try:
            self.data = self.parser.sql_execute('''
                select indexdef || ';' as data
                  from pg_indexes
                 where schemaname = %(schema)s and tablename = %(table)s and indexname = %(name)s
              ''', schema=self.schema.name, table=self.table_name.replace('"', ''), name=self.name)[0]['data']
        except:
            print ('''
                select indexdef || ';' as data
                  from pg_indexes
                 where schemaname = %s and tablename = %s and indexname = %s
              ''' % (self.schema.name, self.table_name, self.name))

    def add_schema_name(self):
        if self.table.name in ("group", "user", "position"):
            self.patch_data('"%s"' % self.table.name, '%s' % self.table.name)

class SequenceOwnedBy(PgObjectOfTable):
    table_pattern = '.*OWNED BY (.*)\..*;'
    before_name = 'OWNED BY'

    def special(self):
        self.column = self.match('.*OWNED BY .*\.(.*);')[0]
        self.sequence = self.schema.sequences[self.name]
        self.table.sequences[self.name] = self.sequence
        self.sequence.file_name = self.table.file_name
        self.sequence.file_ext = self.table.file_ext

    def add_schema_name(self):
        super(SequenceOwnedBy, self).add_schema_name()
        if self.schema.name != 'public':
            self.patch_data_re('ALTER SEQUENCE %s' % (self.name),
                               'ALTER SEQUENCE %s.%s' % (self.schema.name, self.name))

class Trigger(PgObjectOfTable):
    table_pattern = '.*ON (\w*|"\w*") ((NOT )?DEFERRABLE|FOR|FROM).*'
    before_name = 'ON'

    def replace_body_by_sql(self):
        self.data = self.parser.sql_execute('''
            select pg_get_triggerdef(t.oid) || ';' as data
              from pg_trigger t
              join pg_class r on r.oid = tgrelid
              join pg_namespace rn on rn.oid = relnamespace
             where rn.nspname = %(schema)s and relname = %(table)s and tgname =  %(name)s
          ''', schema=self.schema.name, table=self.table_name.replace('"', ''), name=self.name)[0]['data']

    def add_schema_name(self):
        if self.table.name in ("group", "user", "position"):
            self.patch_data('"%s"' % self.table.name, '%s' % self.table.name)


class Rule(PgObjectOfTable):
    table_pattern = '.*\n*.* TO ([^\s]+)( DO|\n +WHERE)'
    before_name = 'TO'

    def replace_body_by_sql(self):
        self.data = self.parser.sql_execute('''
            select definition as data
              from pg_rules
             where schemaname = %(schema)s and tablename = %(table)s and rulename = %(name)s
          ''', schema=self.schema.name, table=self.dequote(self.table_name), name=self.name)[0]['data']

    def add_schema_name(self):
        pass




class Cast(PgGlobalObject):
    def special(self):
        self.file_name = self.match('CAST \((.*)\)', self.name)[0].lower().replace(' ', '_')

class Extension(PgGlobalObject):
    pass

class Language(PgGlobalObject):
    pass

class Server(PgGlobalObject):
    pass

class UserMapping(PgGlobalObject):
    def special(self):
        self.file_name = '%s_on_%s' % self.match('USER MAPPING (.*) SERVER (.*)', self.name)
