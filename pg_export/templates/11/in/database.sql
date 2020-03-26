select json_build_object(
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
