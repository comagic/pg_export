create SCHEMA {{ name }};
{%- if acl %}

{{ acl|acl_to_grants('schema', name) }}
{%- endif %}
{%- if comment %}

comment on SCHEMA {{ name }} is '{{ comment }}';
{%- endif %}

