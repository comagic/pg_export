not exists (select *
              from pg_depend dep
             where dep.objid = {{ objid }} and
                   dep.classid = '{{ objclass }}'::regclass and
                   dep.deptype = 'e')
