select json_build_object(
           'casts',
           ({% include '12/in/cast.sql' %}),

           'extensions',
           ({% include '12/in/extension.sql' %}),

           'languages',
           ({% include '12/in/language.sql' %}),

           'servers',
           ({% include '12/in/server.sql' %}),

           'schemas',
           ({% include '12/in/schema.sql' %}),

           'types',
           ({% include '12/in/type.sql' %}),

           'tables',
           ({% include '12/in/table.sql' %}),

           'views',
           ({% include '12/in/view.sql' %}),

           'sequences',
           ({% include '12/in/sequence.sql' %}),

           'functions',
           ({% include '12/in/function.sql' %}),

           'aggregates',
           ({% include '12/in/aggregate.sql' %}),

           'operators',
           ({% include '12/in/operator.sql' %})

       ) as src
