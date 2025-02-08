create publication {{ name }}
{%- if all_tables %} for all tables {%- endif %}
{%- if publish_via_partition_root or not insert or not update or not delete or not truncate %}
  with (
  {%- if not insert or not update or not delete or not truncate -%}
    publish = '{{
      ", ".join(
        (["insert"] if insert else []) +
        (["update"] if update else []) +
        (["delete"] if delete else []) +
        (["truncate"] if truncate else []))
    }}'
    {%- if publish_via_partition_root %}, {% endif -%}
  {%- endif %}
  {%- if publish_via_partition_root -%}
  publish_via_partition_root = true
  {%- endif -%})
{%- endif %};

{%- if tables %}
{% for table in tables %}
alter publication {{ name }} add table {{table}};
{%- endfor %}
{%- endif %}

