{% if type == 'enum' -%}
create TYPE {{ full_name }} as ENUM (
    {%- for l in enum_lables %}
    '{{ l }}' {%- if not loop.last %},{% endif %}
    {%- endfor %}
);
{% endif -%}

{%- if type == 'composite' -%}
create type {{ full_name }} as (
    {%- include '11/out/attribute.sql' %}
);
{% endif -%}

{% if acl -%}
{{ acl|acl_to_grants('type', full_name) }}
{% endif -%}
{{"\n"}}