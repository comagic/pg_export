{%- for a in arguments %}
  {%- if arguments_as_table -%} {{"\n  "}} {%- endif -%}
  {%- if a.mode == 'o' %}{{"OUT"|ljust(argument_max_length, ' ')}} {% endif %}
  {%- if a.mode == 'b' %}{{"INOUT"|ljust(argument_max_length, ' ')}} {% endif %}
  {%- if a.mode == 'v' %}{{"VARIADIC"|ljust(argument_max_length, ' ')}} {% endif %}
  {%- if a.name %}{{ a.name|ljust(0 if a.mode in ['o', 'b', 'v'] else argument_max_length, ' ') }} {% endif %}
  {{- a.type }}
  {%- if a.default %} default {% if a.default.startswith('NULL') %}{{ a.default|lower }}{% else %}{{ a.default }}{% endif %}{% endif %}
  {%- if not loop.last %},{% endif %}
  {%- if not loop.last and not arguments_as_table %} {% endif %}
{%- endfor %}
{%- if arguments_as_table -%} {{"\n"}} {%- endif -%}
