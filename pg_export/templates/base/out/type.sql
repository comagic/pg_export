{% if type == 'enum' -%}
create type {{ full_name }} as enum (
  {%- for l in enum_lables %}
  '{{ l }}' {%- if not loop.last %},{% endif %}
  {%- endfor %}
);
{%- endif %}

{%- if type == 'composite' -%}
create type {{ full_name }} as (
  {%- include 'out/_attribute.sql' %}
);
{%- endif %}

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment or columns|selectattr('comment')|first() %}
{% if comment %}
comment on type {{ full_name }} is {{ comment }};
{%- endif %}
{%- for c in columns if c.comment %}
comment on column {{ full_name }}.{{ c.name }} is {{ c.comment }};
{%- endfor %}
{%- endif %}

