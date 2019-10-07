create schema {{ name }};

{% if acl -%}
{{ acl|acl_to_grants('schema', name) }}
{% endif %}
