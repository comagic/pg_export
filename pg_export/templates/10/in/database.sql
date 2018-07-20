select json_build_object(
           'schemas',
           ({% include '10/in/schema.sql' %}),

           'types',
           ({% include '10/in/type.sql' %}),

           'tables',
           ({% include '10/in/table.sql' %})

       ) as src
