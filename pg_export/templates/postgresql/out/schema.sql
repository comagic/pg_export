{% if name != 'public' -%}
create schema {{ name }};
{%- endif %}

{%- if grants %}

{{ grants }}
{%- endif %}

{%- if comment %}

comment on schema {{ name }} is {{ comment }};
{%- endif %}

