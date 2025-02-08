{%- for t in triggers %}

create {%- if t.constraint %} constraint {%- endif %} trigger {{ t.name }}
  {{ t.type }} {{ t.actions|join(' or ') }} on {{ full_name }}
  {%- if t.ftable %} from {{ t.ftable }} {%- endif %}
  {%- if t.deferrable %} deferrable {%- endif %}
  {%- if t.deferred %} initially deferred {%- endif %}
  {%- if t.new_table or t.old_table %} referencing {%- endif %}
  {%- if t.new_table %} new table as {{ t.new_table }} {%- endif %}
  {%- if t.old_table %} old table as {{ t.old_table }} {%- endif %}
  for each {{ t.each }} {% if t.condition -%} when ({{ t.condition }}) {% endif -%}
  execute function {{ t.function }}({{ t.arguments }});
{%- endfor %}
