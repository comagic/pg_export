          left join pg_description d
                 on d.objoid = {{ objid }} and
                    d.classoid = '{{ objclass }}'::regclass and
                    d.objsubid = {% if objsubid %} {{ objsubid }} {% else %} 0 {% endif %}
