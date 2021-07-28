(
  {%- for c in idx_columns if not c.is_include %}
    {{- c.name }}
    {%- if c.order -%} {{ c.order }} {%- endif %}
    {%- if c.collate %} collate {{c.collate }} {%- endif %}
    {%- if c.opclass %} {{c.opclass }} {%- endif %}
    {%- if c.operator %} with {{c.operator }} {%- endif %}
    {%- if not loop.last %}, {% endif %}
  {%- endfor -%}
)
  {%- for c in idx_columns if c.is_include %}
    {%- if loop.first %} include ({% endif %}
    {{- c.name }}
    {%- if not loop.last %}, {% else %}) {%- endif %}
  {%- endfor %}
