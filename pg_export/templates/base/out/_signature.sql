{{ full_name }}(
{%- for a in arguments %}
  {%- if a.mode == 'o' %}OUT {% endif %}
  {%- if a.name %}{{ a.name }} {% endif %}
  {{- a.type }}
  {%- if not loop.last %}, {% endif %}
{%- endfor -%})
