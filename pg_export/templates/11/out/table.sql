create {%- if unlogged %} unlogged {%- endif %} table {{ full_name }} (
    {%- include '11/out/attribute.sql' %}
)
{%- if inherits %}
inherits ({{ inherits|join_attr('table', ', ') }})
{%- endif %}
{%- if partition_by %}
partition by {%- if partition_by.strategy == 'r' %} range
             {%- elif partition_by.strategy == 'l' %} list
             {%- elif partition_by.strategy == 'h' %} hash
             {%- endif %} ({{ partition_by.columns|join(', ') }})
{%- endif %};

{%- if attach %}
alter table only {{ attach.table }} attach partition {{ full_name }}
    {%- if attach.is_default %} default
    {%- elif attach.in %} for values in ({{ attach.in }})
    {%- elif attach.from %} for values from ({{ attach.from }}) to ({{ attach.to }})
    {%- endif %};
{%- endif %}

{% if acl -%}
{{ acl|acl_to_grants('table', full_name) }}
{% endif %}

{%- for c in columns if c.acl -%}
{{ c.acl|acl_to_grants('column', full_name, c.name) }}
{% endfor %}

{%- if comment -%}
comment on table {{ full_name }} is '{{ comment }}';
{% endif %}

{%- for c in columns if c.comment %}
comment on column {{ full_name }}.{{ c.name }} is '{{ c.comment }}';
{% endfor %}

{%- if primary_key %}
alter table {{ full_name }} add constraint {{ primary_key.name }}
    primary key ({{ primary_key.columns|join(', ') }})
    {%- if primary_key.deferrable %} deferrable {%- endif %}
    {%- if primary_key.deferred %} initially deferred {%- endif %};
{% endif %}

{%- for fk in foreign_keys %}
alter table {{ full_name }} add constraint {{ fk.name }}
    foreign key ({{ fk.columns|join(', ') }}) references {{ fk.ftable }}({{ fk.fcolumns|join(', ') }})
    {%- if fk.deferrable %} deferrable {%- endif %}
    {%- if fk.deferred %} initially deferred {%- endif %}
    {%- if fk.not_valid %} not valid {%- endif %};
{% endfor %}

{%- for u in uniques %}
alter table {{ full_name }} add constraint {{ u.name }}
    unique ({{ u.columns|join(', ') }})
    {%- if u.deferrable %} deferrable {%- endif %}
    {%- if u.deferred %} initially deferred {%- endif %};
{% endfor %}

{%- for e in exclusions %}
alter table {{ full_name }} add constraint {{ e.name }}
    exclude using {{ e.access_method }} ({{ e.columns|concat_items(' with ', e.operators)|join(', ') }})
    {%- if e.deferrable %} deferrable {%- endif %}
    {%- if e.deferred %} initially deferred {%- endif %};
{% endfor %}

{%- for c in checks %}
alter table {{ full_name }} add constraint {{ c.name }}
    check {{ c.src|lower() }}
    {%- if c.not_valid %} not valid {%- endif %};
{% endfor %}

{%- for t in triggers %}
create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
    {{ t.when }} {{ t.actions|join(' or ') }} on {{ full_name }}
    {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
    {%- if t.deferrable %} deferrable {%- endif %}
    {%- if t.deferred %} initially deferred {%- endif %}
    for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
    execute procedure {{ t.function }}({{ t.arguments|join(', ') }});
{% endfor %}

{%- for i in indexes %}
create {%- if i.is_unique %} unique {%- endif %} index {{ i.name }}
    using {{ i.access_method }} on {{ full_name }}({{ i.columns|join(', ') }});
{% endfor %}

{%- for c in columns if c.statistics -%}
alter table only {{ full_name }} alter column {{ c.name }} set statistics {{ c.statistics }};
{% endfor %}

