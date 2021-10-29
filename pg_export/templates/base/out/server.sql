create server {{ name }}
    {%- if type %}
    type {{ type }}
    {%- endif %}
    {%- if version %}
    version {{ version }}
    {%- endif %}
    foreign data wrapper {{ wrapper }}
    options ({% for o in options %}
             {{- o.name }} {{ o.value }}
             {%- if not loop.last %},
             {% endif %}
             {%- endfor %});

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment %}

comment on server {{ name }} is {{ comment }};
{%- endif %}

{%- for m in user_mappings %}

create user mapping
  for {% if m.role -%} {{ m.role }} {%- else -%} public {%- endif %}
  server {{ name }}
  options ({% for o in m.options %}
           {{- o.name }} {{ o.value }}
           {%- if not loop.last %},
           {% endif %}
           {%- endfor %});
{%- endfor %}

