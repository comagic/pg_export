create or replace
{% if kind == 'p' -%} procedure {%- else -%} function {%- endif %} {{ full_name }}(
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
)
{%- if kind != 'p' %} returns
{%- if returns_type == 'table' %} table(
{%- for c in columns %}
  {%- if columns|length > 1 -%} {{"\n  "}} {%- endif -%}
  {{ c.name|ljust(column_max_length, ' ') }} {{ c.type }}
  {%- if not loop.last %},{% endif %}
{%- endfor %}
{%- if columns|length > 1 -%} {{"\n"}} {%- endif -%}
){% else %} {% if setof -%} SETOF {% endif -%} {{ returns_type }}{% endif -%}
{%- endif -%}{# if kind != 'p' #} as {% if binary_file %}'{{binary_file}}', {% endif -%} $${{ body }}$$ language {{ language }}
{%- if kind == 'w' %} window {%- endif %}
{%- if volatile == 's' %} stable {%- endif %}
{%- if volatile == 'i' %} immutable {%- endif %}
{%- if leakproof == 's' %} leakproof {%- endif %}
{%- if strict %} strict {%- endif %}
{%- if security_definer %} security definer {%- endif %}
{%- if parallel == 'r' %} parallel restrict {%- endif %}
{%- if parallel == 's' %} parallel safe {%- endif %}
{%- if cost != 100 %} cost {{ cost }} {%- endif %}
{%- if rows != 1000 and setof %} rows {{ rows }} {%- endif %}
{%- if config %} set {{ config|join(' set ') }} {%- endif %};
{%- for t in depend_on_tables %}
--depend on table {{ t.schema }}.{{ t.name }}
{%- endfor %}
{%- if acl %}

{{ acl|acl_to_grants('procedure' if kind == 'p' else 'function', signature) }}
{%- endif %}

{%- if comment %}

comment on {% if kind == 'p' -%} procedure {%- else -%} function {%- endif %} {{ signature }} is {{ comment }};
{%- endif %}


