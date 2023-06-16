{%- for r in rules %}

create rule {{ r.name }} as
    on {%- if r.event == 'i' %} insert
       {%- elif r.event == 'u' %} update
       {%- elif r.event == 'd' %} delete
       {%- endif %} to {{ full_name }}
    {%- if r.predicate %}
    where {{ r.predicate }}
    {%- endif %}
    do {%- if r.instead %} instead {%- endif %} {{ r.query }};
{%- endfor %}
