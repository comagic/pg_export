{%- for i in indexes %}

create {%- if i.is_unique %} unique {%- endif %} index {{ i.name }} on {{ full_name }}
  {%- if i.access_method != 'btree' %}
  using {{ i.access_method }}
  {%- endif -%}
  ({%- for c in i.columns %}
     {{- c.name }}
     {%- if c.order -%} {{ c.order }} {%- endif %}
     {%- if c.collate %} collate {{c.collate }} {%- endif %}
     {%- if c.opclass %} {{c.opclass }} {%- endif %}
     {%- if not loop.last %}, {% endif %}
   {%- endfor %})
  {%- if i.include_columns %} include ({{i.include_columns|join_attr('name', ', ')}}){%- endif %}
  {%- if i.predicate %}
  where ({{ i.predicate }})
  {%- endif %}
  {%- if i.options %} with ({{ i.options|join(', ') }}){%- endif %};
{%- endfor %}
