select json_build_object(
           'casts',
           ({% include '11/in/cast.sql' %}),

           'extensions',
           ({% include '11/in/extension.sql' %}),

           'servers',
           ({% include '11/in/server.sql' %}),

           'schemas',
           ({% include '11/in/schema.sql' %}),

           'types',
           ({% include '11/in/type.sql' %}),

           'tables',
           ({% include '11/in/table.sql' %}),

           'sequences',
           ({% include '11/in/sequence.sql' %}),

           'functions',
           ({% include '11/in/function.sql' %}),

           'aggregates',
           ({% include '11/in/aggregate.sql' %})

       ) as src
