select json_build_object(
           'schemas',
           ({% include '10/in/schema.sql' %}),

           'types',
           ({% include '10/in/type.sql' %}),

           'tables',
           ({% include '10/in/table.sql' %}),

           'sequences',
           ({% include '11/in/sequence.sql' %}),

           'functions',
           ({% include '10/in/function.sql' %})

       ) as src
