{% if name != 'public' -%}
create schema {{ name }};
{%- endif %}

{%- if acl %}

{{ acl|acl_to_grants('schema', name) }}
{%- endif %}

{%- if comment %}

comment on schema {{ name }} is {{ comment }};
{%- endif %}

