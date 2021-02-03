select json_build_object(
           'casts',
           ({% include 'GP_6.13/in/cast.sql' %}),

           'extensions',
           ({% include 'GP_6.13/in/extension.sql' %}),

           'languages',
           ({% include 'GP_6.13/in/language.sql' %}),

           'servers',
           ({% include 'GP_6.13/in/server.sql' %}),

           'schemas',
           ({% include 'GP_6.13/in/schema.sql' %}),

           'types',
           ({% include 'GP_6.13/in/type.sql' %}),

           'tables',
           ({% include 'GP_6.13/in/table.sql' %}),

           'views',
           ({% include 'GP_6.13/in/view.sql' %}),

           'sequences',
           ({% include 'GP_6.13/in/sequence.sql' %}),

           'functions',
           ({% include 'GP_6.13/in/function.sql' %}),

           'aggregates',
           ({% include 'GP_6.13/in/aggregate.sql' %}),

           'operators',
           ({% include 'GP_6.13/in/operator.sql' %})

       ) as src
