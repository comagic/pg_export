create {%- if unlogged %} unlogged {%- endif %} table {{ name }} (
    {%- for c in columns -%}
        {{'\n    '}} {{- c.name }} {{ c.type }}
        {%- if c.collate %} collate "{{ c.collate }}"{% endif %}
        {%- if c.not_null %} not null{% endif %}
        {%- if c.default %} default {{ c.default|untype_default(c.type) }}{% endif %}
        {%- if not loop.last %},{% endif %}
        {%- if c.comment %} -- {{ c.comment|replace('\n', '\\n') }}{% endif %}
    {%- endfor %}
);

{% if acl -%}
{{ acl|acl_to_grants('table', name) }}
{% endif %}

{%- for c in columns if c.acl -%}
{{ c.acl|acl_to_grants('column', name, c.name) }}
{% endfor %}

{%- if comment %}
comment on table {{ name }} is '{{ comment }}';
{% endif %}

{%- for c in columns if c.comment %}
comment on column {{ name }}.{{ c.name }} IS '{{ c.comment }}';
{% endfor %}

{%- if primary_key %}
alter table {{ name }} add constraint {{ primary_key.name }}
    primary key({{ primary_key.columns|join(', ') }})
    {%- if primary_key.deferrable %} deferrable {%- endif %}
    {%- if primary_key.deferred %} initially deferred {%- endif %};
{% endif %}

{%- for fk in foreign_keys %}
alter table {{ name }} add constraint {{ fk.name }}
    foreign key({{ fk.columns|join(', ') }}) references {{ fk.ftable }}({{ fk.fcolumns|join(', ') }})
    {%- if fk.deferrable %} deferrable {%- endif %}
    {%- if fk.deferred %} initially deferred {%- endif %}
    {%- if fk.not_valid %} not valid {%- endif %};
{% endfor %}

{%- for u in uniques -%}
alter table {{ name }} add constraint {{ u.name }}
    unique({{ u.columns|join(', ') }})
    {%- if u.deferrable %} deferrable {%- endif %}
    {%- if u.deferred %} initially deferred {%- endif %};
{% endfor %}

{%- for c in checks -%}
alter table {{ name }} add constraint {{ c.name }}
    check{{ c.src }}
    {%- if c.not_valid %} not valid {%- endif %};
{% endfor %}

{%- for t in triggers %}
create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
    {{ t.when }} {{ t.actions|join(' or ') }} on {{ name }}
    {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
    {%- if t.deferrable %} deferrable {%- endif %}
    {%- if t.deferred %} initially deferred {%- endif %}
    for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
    execute procedure {{ t.function }}({{ t.arguments }});
{% endfor %}

{%- for i in indexes %}
create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
    {{ t.when }} {{ t.actions|join(' or ') }} on {{ name }}
    {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
    {%- if t.deferrable %} deferrable {%- endif %}
    {%- if t.deferred %} initially deferred {%- endif %}
    for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
    execute procedure {{ t.function }}({{ t.arguments }});
{% endfor %}

{% for c in columns if c.statistics -%}
alter table only {{ name }} alter column {{ c.name }} set statistics {{ c.statistics }};
{% endfor -%}
