create event trigger {{ name }}
  on {{ event }}
  {%- if tags %}
  when tag in ('{{ tags | join("', '") }}')
  {%- endif %}
  execute function {{ function }}();

{%- if enabled == 'D' %}

alter event trigger {{ name }} disable;

{%- elif enabled != 'O' %}

alter event trigger {{ name }} enable
  {%- if enabled == 'A' %} always
  {%- elif enabled == 'R' %} replica
  {%- endif %};

{%- endif %}

