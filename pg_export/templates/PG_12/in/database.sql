select json_build_object(
           'casts',
           ({% include 'PG_12/in/cast.sql' %}),

           'extensions',
           ({% include 'PG_12/in/extension.sql' %}),

           'languages',
           ({% include 'PG_12/in/language.sql' %}),

           'servers',
           ({% include 'PG_12/in/server.sql' %}),

           'schemas',
           ({% include 'PG_12/in/schema.sql' %}),

           'types',
           ({% include 'PG_12/in/type.sql' %}),

           'tables',
           ({% include 'PG_12/in/table.sql' %}),

           'views',
           ({% include 'PG_12/in/view.sql' %}),

           'sequences',
           ({% include 'PG_12/in/sequence.sql' %}),

           'functions',
           ({% include 'PG_12/in/function.sql' %}),

           'aggregates',
           ({% include 'PG_12/in/aggregate.sql' %}),

           'operators',
           ({% include 'PG_12/in/operator.sql' %})

       ) as src
