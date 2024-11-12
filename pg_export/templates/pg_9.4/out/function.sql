create or replace
{%- if kind == 'p' %} procedure {%- else %} function {%- endif %} {{ full_name }}({% include 'out/_argument.sql' %})
{%- if kind != 'p' %} returns
{%- if returns_type == 'table' %} table(
{%- for c in columns %}
  {%- if columns|length > 1 -%} {{"\n  "}} {%- endif -%}
  {{ c.name|ljust(column_max_length, ' ') }} {{ c.type }}
  {%- if not loop.last %},{% endif %}
{%- endfor %}
{%- if columns|length > 1 -%} {{"\n"}} {%- endif -%}
){% else %} {% if setof -%} SETOF {% endif -%} {{ returns_type }}{% endif -%}
{%- endif -%}{# if kind != 'p' #} as {% if binary_file %}'{{binary_file}}', {% endif -%} $${{ body|replace('\r', '') }}$$ language {{ language }}
{%- if kind == 'w' %} window {%- endif %}
{%- if volatile == 's' %} stable {%- endif %}
{%- if volatile == 'i' %} immutable {%- endif %}
{%- if leakproof == 's' %} leakproof {%- endif %}
{%- if strict %} strict {%- endif %}
{%- if security_definer %} security definer {%- endif %}
{%- if parallel == 'r' %} parallel restricted {%- endif %}
{%- if parallel == 's' %} parallel safe {%- endif %}
{%- if cost != 100 %} cost {{ cost }} {%- endif %}
{%- if rows != 1000 and setof %} rows {{ rows }} {%- endif %}
{%- if config %} set {{ config|join(' set ') }} {%- endif %};

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment %}

comment on {% if kind == 'p' -%} procedure {%- else -%} function {%- endif %} {{ signature }} is {{ comment }};
{%- endif %}

