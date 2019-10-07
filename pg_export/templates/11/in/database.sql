select json_build_object(
           'schemas',
           ({% include '11/in/schema.sql' %}),

           'types',
           ({% include '11/in/type.sql' %}),

           'tables',
           ({% include '11/in/table.sql' %}),

           'functions',
           ({% include '11/in/function.sql' %})

       ) as src
