select json_build_object(
           'casts',
           ({% include 'in/cast.sql' %}),

           'extensions',
           ({% include 'in/extension.sql' %}),

           'languages',
           ({% include 'in/language.sql' %}),

           'servers',
           ({% include 'in/server.sql' %}),

           'schemas',
           ({% include 'in/schema.sql' %}),

           'types',
           ({% include 'in/type.sql' %}),

           'tables',
           ({% include 'in/table.sql' %}),

           'views',
           ({% include 'in/view.sql' %}),

           'sequences',
           ({% include 'in/sequence.sql' %}),

           'functions',
           ({% include 'in/function.sql' %}),

           'aggregates',
           ({% include 'in/aggregate.sql' %}),

           'operators',
           ({% include 'in/operator.sql' %})

       ) as src
