create {%- if kind == 'm' %} materialized {%- else %} or replace {%- endif %} view {{ full_name }} as
{{ query }}
{%- if kind == 'm' %}
with no data
{%- endif %};

{%- for v in depend_on_view %}
--depend on view {{ v.schema }}.{{ v.name }}
{%- endfor %}

{%- if grants or columns|selectattr('grants')|first() %}
{% if grants %}
{{ grants }}
{%- endif %}
{%- for c in columns if c.grants %}
{{ c.grants }}
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

{%- include 'out/_rule.sql' %}

{%- for t in triggers %}

create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
  {{ t.type }} {{ t.actions|join(' or ') }} on {{ full_name }}
  {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
  {%- if t.deferrable %} deferrable {%- endif %}
  {%- if t.deferred %} initially deferred {%- endif %}
  {%- if t.new_table %} referencing new table as {{ t.new_table }} {%- endif %}
  {%- if t.old_table %} referencing old table as {{ t.old_table }} {%- endif %}
  for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
  execute function {{ t.function }}({{ t.arguments }});
{%- endfor %}

{%- include 'out/_index.sql' %}

