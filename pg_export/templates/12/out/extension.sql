create extension {{ name }}
  with schema {{ with_schema }}
       version {{ with_version }};

{%- if comment %}

comment on extension {{ name }} is {{ comment }};
{%- endif %}

