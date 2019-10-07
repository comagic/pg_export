create or replace
function {{ full_name }}(
{%- for a in arguments %}
  {%- if arguments|length > 1 -%} {{"\n  "}} {%- endif -%}
  {%- if a.mode == 'o' %}out {% endif %}
  {%- if with_out_args and a.mode != 'o' %}    {% endif %}
  {%- if a.name %}{{ a.name|ljust(argument_max_length, ' ') }} {% endif %}
  {{- a.type }}
  {%- if a.default %} default {% if a.default.startswith('NULL') %}{{ a.default|lower }}{% else %}{{ a.default }}{% endif %}{% endif %}
  {%- if not loop.last %},{% endif %}
{%- endfor %}
{%- if arguments|length > 1 -%} {{"\n"}} {%- endif -%}
) returns
{%- if returns_type == 'table' %} table(
{%- for c in columns %}
  {{ c.name|ljust(column_max_length, ' ') }} {{ c.type }}
  {%- if not loop.last %},{% endif %}
{%- endfor %}
) {% else %} {% if setof -%} setof {% endif -%} {{ returns_type }} {% endif -%}
as $${{ body }}$$ language {{ language }}
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

{%- if acl %}

revoke all on function {{ signature }} from public;
{%- if acl != ['postgres=X/postgres'] %}
{{ acl|acl_to_grants('function', signature) }}
{%- endif %}
{%- endif %}

{%- if comment %}

comment on function {{ signature }} is '{{ comment }}';
{%- endif %}


