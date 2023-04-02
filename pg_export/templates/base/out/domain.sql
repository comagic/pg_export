create domain {{ full_name }} as {{ basetype }}
{%- if collate %}
  collate {{ collate }}
{%- endif %}
{%- if default %}
  default {{ default }}
{%- endif %}
{%- if not_null %}
  not null
{%- endif %}
{%- for c in check_constraints %}
  constraint {{ c.name }} check ({{ c.src }})
{%- endfor %};

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment %}

comment on domain {{ full_name }} is {{ comment }};
{%- endif %}

