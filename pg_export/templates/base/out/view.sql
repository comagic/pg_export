create {%- if kind == 'm' %} materialized {%- else %} or replace {%- endif %} view {{ full_name }} as
{{ query }}
{%- if kind == 'm' %}
with no data
{%- endif %};

{%- for v in depend_on_view %}
--depend on view {{ v.schema }}.{{ v.name }}
{%- endfor %}

{%- if acl or columns|selectattr('acl')|first() %}
{% if acl %}
{{ acl|acl_to_grants('table', full_name) }}
{%- endif %}
{%- for c in columns if c.acl %}
{{ c.acl|acl_to_grants('column', full_name, c.name) }}
{%- endfor %}
{%- endif %}

{%- if comment or columns|selectattr('comment')|first() %}
{% if comment %}
comment on view {{ full_name }} is {{ comment }};
{%- endif %}
{%- for c in columns if c.comment %}
comment on column {{ full_name }}.{{ c.name }} is {{ c.comment }};
{%- endfor %}
{%- endif %}

{%- for r in rules %}

create rule {{ r.name }} as
    on {%- if r.event == 'i' %} insert
       {%- elif r.event == 'u' %} update
       {%- elif r.event == 'd' %} delete
       {%- endif %} to {{ full_name }}
    {%- if r.predicate %}
    where {{ r.predicate }}
    {%- endif %}
    do {%- if r.instead %} instead {%- endif %} {{ r.query }};
{%- endfor %}

{%- include 'out/_index.sql' %}

