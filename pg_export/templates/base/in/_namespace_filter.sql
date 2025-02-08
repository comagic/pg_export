{% if include_schemas %} and
       n.nspname = any(array[{{ include_schemas }}])
{%- elif exclude_schemas %} and
       n.nspname <> all(array[{{ exclude_schemas }}])
{%- endif %}
