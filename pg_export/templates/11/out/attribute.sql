    {%- for c in columns -%}
        {{'\n    '}} {{- c.name }} {{ c.type }}
        {%- if c.collate %} collate "{{ c.collate }}"{% endif %}
        {%- if c.not_null %} not null{% endif %}
        {%- if c.default %} default {{ c.default|replace('public.', '')|untype_default(c.type) }}{% endif %}
        {%- if not loop.last %},{% endif %}
        {%- if c.comment %} -- {{ c.comment|replace('\n', '\\n') }}{% endif %}
    {%- endfor %}
