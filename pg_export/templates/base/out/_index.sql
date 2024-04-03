{%- for i in indexes %}

create {%- if i.is_unique %} unique {%- endif %} index {{ i.name }} on {{ full_name }}
  {%- if i.access_method != 'btree' %}
  using {{ i.access_method }}
  {%- endif %}
  {%- with idx_columns=i.columns %} {%- include 'out/_index_columns.sql' %} {%- endwith %}
  {%- if i.nulls_not_distinct %} nulls not distinct {%- endif %}
  {%- if i.predicate %}
  where ({{ i.predicate }})
  {%- endif %}
  {%- if i.options %} with ({{ i.options|join(', ') }}){%- endif %};
{%- endfor %}
