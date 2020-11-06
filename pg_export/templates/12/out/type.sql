{% if type == 'enum' -%}
create type {{ full_name }} as enum (
  {%- for l in enum_lables %}
  '{{ l }}' {%- if not loop.last %},{% endif %}
  {%- endfor %}
);
{%- endif %}

{%- if type == 'composite' -%}
create type {{ full_name }} as (
  {%- include '12/out/_attribute.sql' %}
);
{%- endif %}

{%- if acl %}
{{ acl|acl_to_grants('type', full_name) }}
{%- endif %}

{%- if comment or columns|selectattr('comment')|first() %}
{% if comment %}
comment on type {{ full_name }} is {{ comment }};
{%- endif %}
{%- for c in columns if c.comment %}
comment on column {{ full_name }}.{{ c.name }} is {{ c.comment }};
{%- endfor %}
{%- endif %}

